`default_nettype none
module control_rod #(
  parameter ROD_LENGTH = 2048, // in hundredths of an inch
  parameter ROD_NET_RX = 2048, // in millibeta
  parameter ROD_SPD = 7 // in hundredths of an inch per second

  // MIT Reactor control rods have 21" of motion at 4.25" per minute
  // and are worth 2 beta of reactivity
)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          new_second,
    input wire          rod_up,
    input wire          rod_dn,
    input wire          scram_in,     
    output logic[15:0]  rod_reactivity,
    output logic[15:0]  rod_position
  );

  assign rod_reactivity = rod_position;
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      rod_position <= 920;
      // critical position with fresh fuel loading at the MIT Reactor has control rods at about 9.2 inches removed
    end else begin
      // TODO: add BRAM reference for the position/reactivity cal data
      // currently just assume reactivity is linear to rod position

      // only move rods every second
      if (new_second) begin
        if (scram_in) begin
          rod_position <= 0;
        end else if (rod_up && !rod_dn) begin
          rod_position <= (rod_position < ROD_LENGTH - ROD_SPD) ? rod_position + ROD_SPD : ROD_LENGTH - 1;
        end else if (rod_dn && !rod_up) begin
          rod_position <= (rod_position >= ROD_SPD) ? rod_position - ROD_SPD : 0;
        end
      end
    end
  end
endmodule
`default_nettype wire