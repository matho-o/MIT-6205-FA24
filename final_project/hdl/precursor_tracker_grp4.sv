`default_nettype none
module precursor_tracker_grp4#(
    parameter LOG2_STEPS_PER_SECOND = 14 // default to 16384 cycles per second
    // usually a neutron generation lasts between 10^-5 and 10^-4 seconds
)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          new_timestep,
    input wire[50:0]    neutron_flux,
    output logic[63:0]  precursor_neutrons
  );

  // precursor group 4:
  // beta = 0.002568
  // lambda = 0.301

  logic[63:0] precursor_amount, amt_buf;
  logic state;
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        // calculated equilibrium values
        // equilibrium neutron flux is 2^47
        precursor_neutrons <= 64'd5_921_404_848_000_000; 
        precursor_amount <= 64'd19_672_441_350_000_000; 

    end else begin
      if (state == 1) begin
        // finish pipelined calculation
        precursor_amount <= precursor_amount + (neutron_flux >> 13) + (neutron_flux >> 18) + (neutron_flux >> 21);
        precursor_neutrons <= precursor_neutrons + (amt_buf >> 8) + (amt_buf >> 13);

        state <= 0;
      end else if (new_timestep) begin
        // start new calculation
        amt_buf <= precursor_amount;

        precursor_amount <= precursor_amount - (precursor_neutrons >> LOG2_STEPS_PER_SECOND) + (neutron_flux >> 9) + (neutron_flux >> 11);
        precursor_neutrons <= (precursor_amount >> 2) + (precursor_amount >> 5) + (precursor_amount >> 6);

        state <= 1;
      end
    end
  end
endmodule
`default_nettype wire