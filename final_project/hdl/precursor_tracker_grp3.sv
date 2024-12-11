`default_nettype none
module precursor_tracker_grp3#(
    parameter LOG2_STEPS_PER_SECOND = 14 // default to 16384 cycles per second
    // usually a neutron generation lasts between 10^-5 and 10^-4 seconds
)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          new_timestep,
    input wire[50:0]    neutron_flux,
    output logic[63:0]  precursor_neutrons
  );

  // precursor group 3:
  // beta = 0.001274
  // lambda = 0.111 

  logic[63:0] precursor_amount, amt_buf;
  logic state;
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        // calculated equilibrium values
        // equilibrium neutron flux is 2^47
        precursor_neutrons <= 64'd2_937_643_994_000_000; 
        precursor_amount <= 64'd26_465_261_200_000_000; 

    end else begin
      if (state == 1) begin
        // finish pipelined calculation
        precursor_amount <= precursor_amount + (neutron_flux >> 15) + (neutron_flux >> 16) + (neutron_flux >> 18);
        precursor_neutrons <= precursor_neutrons + (amt_buf >> 11) + (amt_buf >> 10);

        state <= 0;
      end else if (new_timestep) begin
        // start new calculation
        amt_buf <= precursor_amount;

        precursor_amount <= precursor_amount - (precursor_neutrons >> LOG2_STEPS_PER_SECOND) + (neutron_flux >> 10) + (neutron_flux >> 12);
        precursor_neutrons <=(precursor_amount >> 4) + (precursor_amount >> 5) + (precursor_amount >> 6);

        state <= 1;
      end
    end
  end
endmodule
`default_nettype wire