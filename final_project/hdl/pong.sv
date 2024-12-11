`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module pong (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [1:0] control_in,
  input wire [3:0] puck_speed_in,
  input wire [3:0] paddle_speed_in,
  input wire nf_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  //use these params!
  localparam PADDLE_WIDTH = 16;
  localparam PADDLE_HEIGHT = 128;
  localparam PUCK_WIDTH = 128;
  localparam PUCK_HEIGHT = 128;
  localparam GAME_WIDTH = 1280;
  localparam GAME_HEIGHT = 720;

  logic [10:0] puck_x, paddle_x; //puck x location, paddle x location
  logic [9:0] puck_y, paddle_y; //puck y location, paddle y location
  logic [7:0] puck_r,puck_g,puck_b; //puck red, green, blue (from block sprite)
  logic [7:0] paddle_r,paddle_g,paddle_b; //paddle colors from its block sprite)

  //for speed avoid signed numbers. Use speed_x,y for speed and dir_x,y for direction
  logic [3:0] speed_x, speed_y; //use for velocity: 1 going positive, 0 going negative
  logic dir_x, dir_y; //use for direction of movement


  logic up, down; //up down from buttons
  logic game_over; //signal to indicate game over (0 on game reset, 1 during play)
  assign up = control_in[1]; //up control
  assign down = control_in[0]; //down control

  block_sprite #(.WIDTH(PADDLE_WIDTH), .HEIGHT(PADDLE_HEIGHT))
  paddle(
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .x_in(paddle_x),
    .y_in(paddle_y),
    .red_out(paddle_r),
    .green_out(paddle_g),
    .blue_out(paddle_b));

  block_sprite #(.WIDTH(PUCK_WIDTH), .HEIGHT(PUCK_HEIGHT))
  puck(
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .x_in(puck_x),
    .y_in(puck_y),
    .red_out(puck_r),
    .green_out(puck_g),
    .blue_out(puck_b));

  assign red_out = puck_r|paddle_r; //merge color contributions from puck and paddle
  assign green_out =  puck_g | paddle_g; //merge color contribuations from puck and paddle
  assign blue_out = puck_b | paddle_b; //merge color contributsion from puck and paddle

  logic puck_overlap; //one bit signal indicating if puck and paddle overlap
  //this signal should be one when puck is red in the video included in lab.
  //make signal be derived combinationally. you will need to figure this out
  //remember numbers are not signed here...so there's no such thing as negative
  always_comb begin
    puck_overlap = (puck_y < paddle_y + PADDLE_HEIGHT) && (puck_y + PUCK_HEIGHT > paddle_y);
  end

  always_ff @(posedge pixel_clk_in)begin
    if (rst_in)begin
      //start puck in center of screen
      puck_x <= GAME_WIDTH/2-PUCK_WIDTH/2;
      puck_y <= GAME_HEIGHT/2 - PUCK_HEIGHT/2;
      dir_x <= hcount_in[0]; //start at pseudorandom direction
      dir_y <= hcount_in[1]; //start with pseudorandom direction
      //start paddle in center of left half of screen
      paddle_x <= 0;
      paddle_y <= GAME_HEIGHT/2 - PADDLE_HEIGHT/2;
      game_over = 0;
    end else begin
      if (nf_in && ~game_over)begin
        // only progress if rendering newframe and NOT game over
        // update paddle location
        if (up && !down) begin
            paddle_y <= (paddle_y < paddle_speed_in ? 0 : paddle_y - paddle_speed_in);
        end else if (down && !up) begin
            paddle_y <= (paddle_y > (GAME_HEIGHT - PADDLE_HEIGHT - 1) - paddle_speed_in ? (GAME_HEIGHT - PADDLE_HEIGHT - 1) : paddle_y + paddle_speed_in);
        end
        
        // update puck y-location w/ collision check
        if (dir_y) begin
          puck_y <= (puck_y > (GAME_HEIGHT - PUCK_HEIGHT - 1) - puck_speed_in ? (GAME_HEIGHT - PUCK_HEIGHT - 1) : puck_y + puck_speed_in);
          if (puck_y > GAME_HEIGHT - PUCK_HEIGHT - 1 - puck_speed_in) begin
            dir_y <= 0;
          end
        end else begin
          puck_y <= (puck_y < puck_speed_in ? 0 : puck_y - puck_speed_in);
          if (puck_y < puck_speed_in) begin
            dir_y <= 1;
          end
        end
        
        // update puck x-location w/ collision check
        if (dir_x) begin 
          puck_x <= (puck_x > (GAME_WIDTH - PUCK_WIDTH - 1) - puck_speed_in ? (GAME_WIDTH - PUCK_WIDTH - 1) : puck_x + puck_speed_in);
          if (puck_x > GAME_WIDTH - PUCK_WIDTH - 1 - puck_speed_in) begin
            dir_x <= 0;
          end
        end else begin
          // instead of wall collision, check for paddle collision
          if (puck_x - puck_speed_in < PADDLE_WIDTH) begin
            // if no paddle collision, game is over
            if (puck_overlap) begin
              puck_x <= PADDLE_WIDTH;
              dir_x <= 1;
            end else begin
              puck_x <= puck_x - puck_speed_in;
              game_over <= 1;
            end
          end else begin
            puck_x <= puck_x - puck_speed_in;
          end
        end

      end
    end
  end
endmodule
`default_nettype wire