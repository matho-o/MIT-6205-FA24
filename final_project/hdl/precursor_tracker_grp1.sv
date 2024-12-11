`default_nettype none
module precursor_tracker_grp1#(
    parameter LOG2_STEPS_PER_SECOND = 14 // default to 16384 cycles per second
    // usually a neutron generation lasts between 10^-5 and 10^-4 seconds
)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          new_timestep,
    input wire[50:0]    neutron_flux,
    output logic[63:0]  precursor_neutrons
  );

  // precursor group 1:
  // beta = 0.000215
  // lambda = 0.0124

  // i could parametrize this, but to optimize runtime i wanted to use bit-shift/addition to approximate multiplication by beta and lambda

  logic[63:0] precursor_amount;
  logic[63:0] amt_buf, n_buf;
  logic state;
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        // calculated equilibrium values
        // equilibrium neutron flux is 2^47
        precursor_neutrons <= 64'd495_756_247_000_000; 
        precursor_amount <= 64'd39_980_342_500_000_000; 

        state <= 0;

    end else begin
      if (state == 1) begin
        // finish pipelined calculation
        precursor_amount <= precursor_amount + (neutron_flux >> 14) + (neutron_flux >> 15);
        precursor_neutrons <= precursor_neutrons + (amt_buf >> 13) + (amt_buf >> 14);

        state <= 0;
      end else if (new_timestep) begin
        // start new calculation
        amt_buf <= precursor_amount;
        n_buf <= precursor_neutrons;

        precursor_amount <= precursor_amount - (precursor_neutrons >> LOG2_STEPS_PER_SECOND) + (neutron_flux >> 13);
        precursor_neutrons <= (precursor_amount >> 7) + (precursor_amount >> 8) + (precursor_amount >> 11);

        state <= 1;
      end
    end
  end
endmodule
`default_nettype wire