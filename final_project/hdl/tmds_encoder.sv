`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
  logic [4:0] tally;
  logic [3:0] n0, n1;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
    // 0x1a = 0b 0001 1010
    // q_m = 0b1 1111 0110
    // tally = -2

    // should be 0b01 1111 0110

    always_comb begin
        // compute n0, n1
        n1 = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        n0 = 8 - n1;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            tally <= 0;
            tmds_out <= 0;
        end else begin
            if (ve_in) begin
                // normal operations
                if (tally == 0 || n1 == n0) begin
                    // right branch of first comparison
                    tmds_out <= {~q_m[8], q_m[8], (q_m[8] ? q_m[7:0] : ~q_m[7:0])};

                    if (q_m[8] == 0) begin
                        tally <= tally + n0 - n1;
                    end else begin
                        tally <= tally + n1 - n0;
                    end

                end else begin
                    // bottom branch of first comparison
                    if ((tally[4] == 0 && n1 > n0) || (tally[4] == 1 && n0 > n1)) begin
                        tmds_out <= {1'b1, q_m[8], ~q_m[7:0]};
                        tally <= tally + 2*q_m[8] + n0 - n1;
                    end else begin
                        tmds_out <= {1'b0, q_m[8], q_m[7:0]};
                        tally <= tally - 2*(1 - q_m[8]) + n1 - n0;
                    end
                end

            end else begin
                tally <= 0;
                case (control_in)
                    2'b00: tmds_out <= 10'b1101010100;
                    2'b01: tmds_out <= 10'b0010101011;
                    2'b10: tmds_out <= 10'b0101010100;
                    2'b11: tmds_out <= 10'b1010101011;
                    default: tmds_out <= 0;
                endcase
            end
        end
    end
 
endmodule
 
`default_nettype wire