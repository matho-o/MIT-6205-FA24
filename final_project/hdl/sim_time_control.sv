`default_nettype none
module sim_time_control#(
    parameter LOG2_STEPS_PER_SECOND = 14 // default to 16384 cycles per second
    // usually a neutron generation lasts between 10^-5 and 10^-4 seconds
)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire[1:0]     time_sel,
    output logic        new_timestep,
    output logic        new_second
  );

  logic[15:0] counter;
  // new_timestep is single cycle high to indicate when counter is 0
  // counter is the number of cycles we are into the current timestep

  logic[LOG2_STEPS_PER_SECOND:0] step_count;
  // counts how many timrsteps since the last second
  // new_second is used to tell certain modules (control rods and hdmi output) to only update once per second (roughly) instead of every timestep

  localparam cycles_per_timestep = 100_000_000 >> LOG2_STEPS_PER_SECOND;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      counter <= 0;
      step_count <= 0;
      new_timestep <= 1;
      new_second <= 1;
    end else begin
      if (counter < cycles_per_timestep - 1) begin
        counter <= counter + 1;
        new_timestep <= 0;
        new_second <= 0;
      end else begin
          counter <= 0;
          new_timestep <= 1;

          if (step_count < (1 << LOG2_STEPS_PER_SECOND)) begin
            step_count <= step_count + 1;
            new_second <= 0;
          end else begin
            step_count <= 0;
            new_second <= 1;
          end
      end
    end
  end
endmodule
`default_nettype wire