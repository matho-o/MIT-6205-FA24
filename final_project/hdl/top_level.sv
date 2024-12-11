`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module top_level(
  input wire clk_100mhz, //crystal reference clock
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0] ss1_c, //cathode controls for the segments of lower four digits
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
  output logic hdmi_clk_p, hdmi_clk_n //differential hdmi clock
  );
 
  assign led = sw; //to verify the switch values
  //shut up those rgb LEDs (active high):
  assign rgb1 = 0;
  assign rgb0 = 0;
 
  //have btn[0] control system reset
  logic sys_rst, game_rst;
  assign sys_rst = btn[0]; //reset is btn[0]
  assign game_rst = btn[0];
 
  logic clk_pixel, clk_5x; //clock lines
  logic locked;

  logic [6:0] ss_c; //used to grab output cathode signal for 7s leds

// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------- NEUTRON LOGIC ------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------

  localparam LOG2_STEPS_PER_SECOND = 14; // default to 2^14 = 16384 timesteps per second
  // used to perform the division by timestep size in point kinetics model
  // instead of dividing by a fraction, just left-shift by LOG2_STEPS_PER_SECOND

  logic new_timestep, new_second;

  logic[15:0] rod1_rx, rod1_pos;
  logic[15:0] rod2_rx, rod2_pos;
  logic[15:0] rod3_rx, rod3_pos;
  logic[15:0] rod4_rx, rod4_pos;
  logic[15:0] rod5_rx, rod5_pos;
  logic[15:0] rod6_rx, rod6_pos;

  logic[50:0] neutron_flux;
  logic[63:0] precursors1, precursors2, precursors3, precursors4, precursors5, precursors6;

  sim_time_control time_ctrl(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .time_sel(sw[15:14]),
    .new_timestep(new_timestep),
    .new_second(new_second)
  );

  // switch 13 controls rod 1 with btn[3:2] as up/down, btn[1] as scram
  control_rod rod1(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_second(new_second),
    .rod_up(btn[3] && sw[13]),
    .rod_dn(btn[2] && sw[13]),
    .scram_in(btn[1]),
    .rod_reactivity(rod1_rx),
    .rod_position(rod1_pos)
  );

  control_rod rod2(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_second(new_second),
    .rod_up(btn[3] && sw[12]),
    .rod_dn(btn[2] && sw[12]),
    .scram_in(btn[1]),
    .rod_reactivity(rod2_rx),
    .rod_position(rod2_pos)
  );

  control_rod rod3(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_second(new_second),
    .rod_up(btn[3] && sw[11]),
    .rod_dn(btn[2] && sw[11]),
    .scram_in(btn[1]),
    .rod_reactivity(rod3_rx),
    .rod_position(rod3_pos)
  );

  control_rod rod4(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_second(new_second),
    .rod_up(btn[3] && sw[10]),
    .rod_dn(btn[2] && sw[10]),
    .scram_in(btn[1]),
    .rod_reactivity(rod4_rx),
    .rod_position(rod4_pos)
  );

  control_rod rod5(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_second(new_second),
    .rod_up(btn[3] && sw[9]),
    .rod_dn(btn[2] && sw[9]),
    .scram_in(btn[1]),
    .rod_reactivity(rod5_rx),
    .rod_position(rod5_pos)
  );

  control_rod rod6(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_second(new_second),
    .rod_up(btn[3] && sw[8]),
    .rod_dn(btn[2] && sw[8]),
    .scram_in(btn[1]),
    .rod_reactivity(rod6_rx),
    .rod_position(rod6_pos)
  );

  precursor_tracker_grp1 precursor1(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(new_timestep),
    .neutron_flux(neutron_flux),
    .precursor_neutrons(precursors1)
  );

  precursor_tracker_grp2 precursor2(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(new_timestep),
    .neutron_flux(neutron_flux),
    .precursor_neutrons(precursors2)
  );

  precursor_tracker_grp3 precursor3(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(new_timestep),
    .neutron_flux(neutron_flux),
    .precursor_neutrons(precursors3)
  );

  precursor_tracker_grp4 precursor4(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(new_timestep),
    .neutron_flux(neutron_flux),
    .precursor_neutrons(precursors4)
  );

  precursor_tracker_grp5 precursor5(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(new_timestep),
    .neutron_flux(neutron_flux),
    .precursor_neutrons(precursors5)
  );

  precursor_tracker_grp6 precursor6(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(new_timestep),
    .neutron_flux(neutron_flux),
    .precursor_neutrons(precursors6)
  );

  logic [15:0] rod1_buf, rod2_buf, rod3_buf, rod4_buf, rod5_buf, rod6_buf;
  logic [63:0] pre1_buf, pre2_buf, pre3_buf, pre4_buf, pre5_buf, pre6_buf;

  always_ff @(posedge clk_pixel) begin
    rod1_buf <= rod1_rx;
    rod2_buf <= rod2_rx;
    rod3_buf <= rod3_rx;
    rod4_buf <= rod4_rx;
    rod5_buf <= rod5_rx;
    rod6_buf <= rod6_rx;

    pre1_buf <= precursors1;
    pre2_buf <= precursors2;
    pre3_buf <= precursors3;
    pre4_buf <= precursors4;
    pre5_buf <= precursors5;
    pre6_buf <= precursors6;
  end

  point_kinetics_model pke(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    .new_timestep(sw[3] ? new_timestep : new_second),
    .rod_reactivity_1(rod1_buf),
    .rod_reactivity_2(rod2_buf),
    .rod_reactivity_3(rod3_buf),
    .rod_reactivity_4(rod4_buf),
    .rod_reactivity_5(rod5_buf),
    .rod_reactivity_6(rod6_buf),
    .precursor_neutron_1(pre1_buf),
    .precursor_neutron_2(pre2_buf),
    .precursor_neutron_3(pre3_buf),
    .precursor_neutron_4(pre4_buf),
    .precursor_neutron_5(pre5_buf),
    .precursor_neutron_6(pre6_buf),
    .neutron_flux(neutron_flux)
  );

  logic [31:0] val_to_display = sw[4] ? {rod1_buf, rod2_buf} : neutron_flux[50:19];

  // print neutron flux to seven segment display
  seven_segment_controller ssc(
    .clk_in(clk_pixel),
    .rst_in(sys_rst),
    //.val_in(neutron_flux[50:19]),
    .val_in(val_to_display),
    .cat_out(ss_c),
    .an_out({ss0_an, ss1_an})
  );
  assign ss0_c = ss_c;
  assign ss1_c = ss_c;

// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------- HDMI LOGIC ---------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------

  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(clk_100mhz),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x));
 
  logic [10:0] hcount; //hcount of system!
  logic [9:0] vcount; //vcount of system!
  logic hor_sync; //horizontal sync signal
  logic vert_sync; //vertical sync signal
  logic active_draw; //ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; //one cycle active indicator of new frame of info!
  logic [5:0] frame_count; //0 to 59 then rollover frame counter
 
  //written by you previously! (make sure you include in your hdl)
  //default instantiation so making signals for 720p
  video_sig_gen mvg(
      .pixel_clk_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));
 
  logic [7:0] red, green, blue; //red green and blue pixel values for output
  logic [7:0] tp_r, tp_g, tp_b; //color values as generated by test_pattern module
  logic [7:0] pg_r, pg_g, pg_b;//color values as generated by pong game(part 2)
 
  //comment out in checkoff 1 once you know you have your video pipeline working:
  //these three colors should be a nice pink (6.205 sidebar) color on full screen .
//   assign tp_r = 8'hFF;
//   assign tp_g = 8'h40;
//   assign tp_b = 8'h7A;
 
  //uncomment the test pattern generator for the latter portion of part 1
  //and use it to drive tp_r,g, and b once you know that your video
  //pipeline is working (by seeing the 6.205 pink color)
  
  test_pattern_generator mtpg(
      .sel_in(sw[1:0]),
      .hcount_in(hcount),
      .vcount_in(vcount),
      .red_out(tp_r),
      .green_out(tp_g),
      .blue_out(tp_b));
  
 
  //uncomment for last part of lab!:
  // TODO: update this for final project
  pong my_pong (
      .pixel_clk_in(clk_pixel),
      .rst_in(game_rst),
      .control_in(btn[3:2]),
      .puck_speed_in(sw[15:12]),
      .paddle_speed_in(sw[11:8]),
      .nf_in(new_frame),
      .hcount_in(hcount),
      .vcount_in(vcount),
      .red_out(pg_r),
      .green_out(pg_g),
      .blue_out(pg_b));
  
 
  always_comb begin
    if (~sw[2])begin //if switch 3 switched use shapes signal from part 2, else defaults
      red = tp_r;
      green = tp_g;
      blue = tp_b;
    end else begin
      red = pg_r;
      green = pg_g;
      blue = pg_b;
    end
  end
 
  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
 
  //three tmds_encoders (blue, green, red)
  //note green should have no control signal like red
  //the blue channel DOES carry the two sync signals:
  //  * control_in[0] = horizontal sync signal
  //  * control_in[1] = vertical sync signal
 
  tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(red),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[2]));

    tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(green),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[1]));

    tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(blue),
      .control_in({vert_sync, hor_sync}),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[0]));
 
  //three tmds_serializers (blue, green, red):
  tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));

    tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));

    tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));
 
  //output buffers generating differential signals:
  //three for the r,g,b signals and one that is at the pixel clock rate
  //the HDMI receivers use recover logic coupled with the control signals asserted
  //during blanking and sync periods to synchronize their faster bit clocks off
  //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
  //the slower 74.25 MHz clock)
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));
 
endmodule // top_level
`default_nettype wire