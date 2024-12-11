`default_nettype none
module point_kinetics_model#(
    parameter LOG2_STEPS_PER_SECOND = 14 // default to 16384 cycles per second
    // usually a neutron generation lasts between 10^-5 and 10^-4 seconds
)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          new_timestep,
    input wire[15:0]    rod_reactivity_1, 
    input wire[15:0]    rod_reactivity_2, 
    input wire[15:0]    rod_reactivity_3, 
    input wire[15:0]    rod_reactivity_4, 
    input wire[15:0]    rod_reactivity_5, 
    input wire[15:0]    rod_reactivity_6, 
    input wire[63:0]    precursor_neutron_1, 
    input wire[63:0]    precursor_neutron_2, 
    input wire[63:0]    precursor_neutron_3, 
    input wire[63:0]    precursor_neutron_4, 
    input wire[63:0]    precursor_neutron_5, 
    input wire[63:0]    precursor_neutron_6, 
    output logic[50:0]  neutron_flux
  );

  //logic [13:0] net_reactivity = rod_reactivity_1 + rod_reactivity_2 + rod_reactivity_3 + rod_reactivity_4 + rod_reactivity_5 + rod_reactivity_6;
  logic [12:0] net_reactivity = rod_reactivity_1 + rod_reactivity_2 + rod_reactivity_3;
  // -4050 accounts for other reactivity effects in the reactor, such that the reactor is exactly critical when rods are at 9.2"
  // deal with signed stuff zzz

  logic is_rx_signed = (net_reactivity > 4050);

  logic [63:0] precursor_sum = precursor_neutron_1 + precursor_neutron_2 + precursor_neutron_3 + precursor_neutron_4 + precursor_neutron_5 + precursor_neutron_6;

  // logic [31:0] small_neutron_flux = neutron_flux >> 18 + neutron_flux >> 19 + neutron_flux >> 21 + neutron_flux >> 22 + neutron_flux >> 24;
  logic [31:0] small_neutron_flux = (neutron_flux >> 18) + (neutron_flux >> 19) + (neutron_flux >> 21) + (neutron_flux >> 22);

  logic [2:0] state;

  

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      neutron_flux <= (1 << 47); // full power neutron flux @ MIT Reactor is about 1.4e14 ~ 2^47 conveniently
      state <= 0;
    end else begin

      logic [28:0] prompt;
      if (state == 1) begin
          if (is_rx_signed) begin
              prompt <= (net_reactivity - 4050) * small_neutron_flux[31:16];
          end else begin
              prompt <= (4050 - net_reactivity) * small_neutron_flux[31:16];
          end
        state <= 2;
      end else if (state == 2) begin
          if (is_rx_signed) begin
              neutron_flux <= neutron_flux + (prompt << 16);
          end else begin
              neutron_flux <= neutron_flux - (prompt << 16);
          end
        state <= 3;
      end else if (state == 3) begin
          if (is_rx_signed) begin
              prompt <= (net_reactivity - 4050) * small_neutron_flux[15:0];
          end else begin
              prompt <= (4050 - net_reactivity) * small_neutron_flux[15:0];
          end
        state <= 4;
      end else if (state == 4) begin
          if (is_rx_signed) begin
              neutron_flux <= neutron_flux + prompt;
          end else begin
              neutron_flux <= neutron_flux - prompt;
          end
        state <= 0;
      end else if (new_timestep) begin
        neutron_flux <= neutron_flux + (precursor_sum >> LOG2_STEPS_PER_SECOND);

        state <= 1;
      end
    end

  end
endmodule
`default_nettype wire