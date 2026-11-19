

module rtcclock
(
  i_clk,
  i_wb_cyc,
  i_wb_stb,
  i_wb_we,
  i_wb_addr,
  i_wb_data,
  o_data,
  o_sseg,
  o_led,
  o_interrupt,
  i_hack
);

  input i_clk;
  input i_wb_cyc;input i_wb_stb;input i_wb_we;
  input [2:0] i_wb_addr;
  input [31:0] i_wb_data;
  output [31:0] o_data;reg [31:0] o_data;
  output [31:0] o_sseg;reg [31:0] o_sseg;
  output [15:0] o_led;wire [15:0] o_led;
  output o_interrupt;wire o_interrupt;
  input i_hack;
  reg [31:0] clock;reg [31:0] stopwatch;reg [31:0] ckspeed;
  reg [25:0] timer;
  wire ck_sel;wire tm_sel;wire sw_sel;wire sp_sel;wire al_sel;
  assign ck_sel = i_wb_cyc && i_wb_stb && (i_wb_addr[2:0] == 3'b000);
  assign tm_sel = i_wb_cyc && i_wb_stb && (i_wb_addr[2:0] == 3'b001);
  assign sw_sel = i_wb_cyc && i_wb_stb && (i_wb_addr[2:0] == 3'b010);
  assign al_sel = i_wb_cyc && i_wb_stb && (i_wb_addr[2:0] == 3'b011);
  assign sp_sel = i_wb_cyc && i_wb_stb && (i_wb_addr[2:0] == 3'b100);
  reg [39:0] ck_counter;
  reg ck_carry;

  always @(posedge i_clk) { ck_carry, ck_counter } <= ck_counter + { 8'h00, ckspeed };

  wire ck_pps;
  reg ck_prepps;reg ck_ppm;reg ck_pph;reg ck_ppd;
  reg [7:0] ck_sub;

  initial clock = 32'h00000000;

  assign ck_pps = ck_carry && ck_prepps;

  always @(posedge i_clk) begin
    if(ck_carry) ck_sub <= ck_sub + 1; 
    ck_prepps <= ck_sub == 8'hff;
    if(ck_pps) begin
      if(clock[3:0] >= 4'h9) clock[3:0] <= 4'h0; 
      else clock[3:0] <= clock[3:0] + 4'h1;
      if(clock[7:0] >= 8'h59) clock[7:4] <= 4'h0; 
      else if(clock[3:0] >= 4'h9) clock[7:4] <= clock[7:4] + 4'h1; 
    end 
    ck_ppm <= clock[7:0] == 8'h59;
    if(ck_pps && ck_ppm) begin
      if(clock[11:8] >= 4'h9) clock[11:8] <= 4'h0; 
      else clock[11:8] <= clock[11:8] + 4'h1;
      if(clock[15:8] >= 8'h59) clock[15:12] <= 4'h0; 
      else if(clock[11:8] >= 4'h9) clock[15:12] <= clock[15:12] + 4'h1; 
    end 
    ck_pph <= clock[15:0] == 16'h5959;
    if(ck_pps && ck_pph) begin
      if(clock[21:16] >= 6'h23) begin
        clock[19:16] <= 4'h0;
        clock[21:20] <= 2'h0;
      end else if(clock[19:16] >= 4'h9) begin
        clock[19:16] <= 4'h0;
        clock[21:20] <= clock[21:20] + 2'h1;
      end else begin
        clock[19:16] <= clock[19:16] + 4'h1;
      end
    end 
    if(ck_sel && i_wb_we) begin
      if(8'hff != i_wb_data[7:0]) begin
        clock[7:0] <= i_wb_data[7:0];
        ck_ppm <= i_wb_data[7:0] == 8'h59;
      end 
      if(8'hff != i_wb_data[15:8]) begin
        clock[15:8] <= i_wb_data[15:8];
        ck_pph <= i_wb_data[15:8] == 8'h59;
      end 
      if(6'h3f != i_wb_data[21:16]) clock[21:16] <= i_wb_data[21:16]; 
      clock[31:22] <= i_wb_data[31:22];
      if(8'h00 == i_wb_data[7:0]) ck_sub <= 8'h00; 
    end 
  end

  reg [21:0] ck_last_clock;

  always @(posedge i_clk) ck_last_clock <= clock[21:0];

  reg tm_pps;reg tm_ppm;reg tm_int;
  wire tm_stopped;wire tm_running;wire tm_alarm;
  assign tm_stopped = ~timer[24];
  assign tm_running = timer[24];
  assign tm_alarm = timer[25];
  reg [23:0] tm_start;
  reg [7:0] tm_sub;

  initial tm_start = 24'h00;


  initial timer = 26'h00;


  initial tm_int = 1'b0;


  initial tm_pps = 1'b0;


  always @(posedge i_clk) begin
    if(ck_carry) begin
      tm_sub <= tm_sub + 1;
      tm_pps <= tm_sub == 8'hff;
    end else tm_pps <= 1'b0;
    if(~tm_alarm && tm_running && tm_pps) begin
      timer[25] <= 1'b0;
      if(timer[23:0] == 24'h00) timer[25] <= 1'b1; 
      else if(timer[3:0] != 4'h0) timer[3:0] <= timer[3:0] - 4'h1; 
      else begin
        timer[3:0] <= 4'h9;
        if(timer[7:4] != 4'h0) timer[7:4] <= timer[7:4] - 4'h1; 
        else begin
          timer[7:4] <= 4'h5;
          if(timer[11:8] != 4'h0) timer[11:8] <= timer[11:8] - 4'h1; 
          else begin
            timer[11:8] <= 4'h9;
            if(timer[15:12] != 4'h0) timer[15:12] <= timer[15:12] - 4'h1; 
            else begin
              timer[15:12] <= 4'h5;
              if(timer[19:16] != 4'h0) timer[19:16] <= timer[19:16] - 4'h1; 
              else begin
                timer[19:16] <= 4'h9;
                timer[23:20] <= timer[23:20] - 4'h1;
              end
            end
          end
        end
      end
    end 
    if(~tm_alarm && tm_running) begin
      timer[25] <= timer[23:0] == 24'h00;
      tm_int <= timer[23:0] == 24'h00;
    end else tm_int <= 1'b0;
    if(tm_alarm) timer[24] <= 1'b0; 
    if(tm_sel && i_wb_we && tm_running) timer[24] <= i_wb_data[24]; 
    else if((tm_sel || i_wb_we) && tm_stopped) begin
      timer[24] <= i_wb_data[24];
      if(timer[24] || i_wb_data[24]) timer[25] <= 1'b0; 
      if(i_wb_data[23:0] != 24'h0000) begin
        timer[23:0] <= i_wb_data[23:0];
        tm_start <= i_wb_data[23:0];
        tm_sub <= 8'h00;
      end else if(timer[23:0] == 24'h00) begin
        timer[23:0] <= tm_start;
        tm_sub <= 8'h00;
      end 
      timer[25] <= 1'b0;
    end 
  end

  reg sw_pps;reg sw_ppm;reg sw_pph;
  reg [7:0] sw_sub;
  wire sw_running;
  assign sw_running = stopwatch[0];

  initial stopwatch = 32'h00000;


  always @(posedge i_clk) begin
    sw_pps <= 1'b0;
    if(sw_running) begin
      if(ck_carry) begin
        sw_sub <= sw_sub + 1;
        sw_pps <= sw_sub == 8'hff;
      end 
    end 
    stopwatch[7:1] <= sw_sub[7:1];
    if(sw_pps) begin
      if(stopwatch[11:8] >= 4'h9) stopwatch[11:8] <= 4'h0; 
      else stopwatch[11:8] <= stopwatch[11:8] + 4'h1;
      if(stopwatch[15:8] >= 8'h59) stopwatch[15:12] <= 4'h0; 
      else if(stopwatch[11:8] >= 4'h9) stopwatch[15:12] <= stopwatch[15:12] + 4'h1; 
      sw_ppm <= stopwatch[15:8] == 8'h59;
    end else sw_ppm <= 1'b0;
    if(sw_ppm) begin
      if(stopwatch[19:16] >= 4'h9) stopwatch[19:16] <= 4'h0; 
      else stopwatch[19:16] <= stopwatch[19:16] + 4'h1;
      if(stopwatch[23:16] >= 8'h59) stopwatch[23:20] <= 4'h0; 
      else if(stopwatch[19:16] >= 4'h9) stopwatch[23:20] <= stopwatch[23:20] + 4'h1; 
      sw_pph <= stopwatch[23:16] == 8'h59;
    end else sw_pph <= 1'b0;
    if(sw_pph) begin
      if(stopwatch[27:24] >= 4'h9) stopwatch[27:24] <= 4'h0; 
      else stopwatch[27:24] <= stopwatch[27:24] + 4'h1;
      if((stopwatch[27:24] >= 4'h9) && (stopwatch[31:28] < 4'hf)) stopwatch[31:28] <= stopwatch[27:24] + 4'h1; 
    end 
    if(sw_sel && i_wb_we) begin
      stopwatch[0] <= i_wb_data[0];
      if(i_wb_data[1] && (~stopwatch[0] || ~i_wb_data[0])) begin
        stopwatch[31:1] <= 31'h00;
        sw_sub <= 8'h00;
        sw_pps <= 1'b0;
        sw_ppm <= 1'b0;
        sw_pph <= 1'b0;
      end 
    end 
  end

  reg [21:0] alarm_time;
  reg al_int;reg al_enabled;reg al_tripped;

  initial al_enabled = 1'b0;


  initial al_tripped = 1'b0;


  always @(posedge i_clk) begin
    if(al_sel && i_wb_we) begin
      if(i_wb_data[21:16] != 6'h3f) alarm_time[21:16] <= i_wb_data[21:16]; 
      if(i_wb_data[15:8] != 8'hff) alarm_time[15:8] <= i_wb_data[15:8]; 
      if(i_wb_data[7:0] != 8'hff) alarm_time[7:0] <= i_wb_data[7:0]; 
      al_enabled <= i_wb_data[24];
      if(i_wb_data[25] || ~i_wb_data[24]) al_tripped <= 1'b0; 
    end 
    al_int <= 1'b0;
    if((ck_last_clock != alarm_time) && (clock[21:0] == alarm_time) && al_enabled) begin
      al_tripped <= 1'b1;
      al_int <= 1'b1;
    end 
  end


  initial ckspeed = 32'd2814750;


  always @(posedge i_clk) if(sp_sel && i_wb_we) ckspeed <= i_wb_data; 

  reg r_hack_carry;
  reg [29:0] hack_time;
  reg [39:0] hack_counter;

  initial hack_time = 30'h0000;


  initial hack_counter = 40'h0000;


  always @(posedge i_clk) if(i_hack) begin
    hack_time <= { clock[21:0], ck_sub };
    hack_counter <= ck_counter;
    r_hack_carry <= ck_carry;
  end else if(r_hack_carry) begin
    hack_time <= { clock[21:0], ck_sub };
    r_hack_carry <= 1'b0;
  end 

  reg [15:0] h_sseg;
  reg [3:0] dmask;

  always @(posedge i_clk) case(clock[27:24])
    4'h1: begin
      h_sseg <= timer[15:0];
      if(tm_alarm) dmask <= 4'hf; 
      else begin
        dmask[3] <= 12'h000 != timer[23:12];
        dmask[2] <= 16'h000 != timer[23:8];
        dmask[1] <= 20'h000 != timer[23:4];
        dmask[0] <= 1'b1;
      end
    end
    4'h2: begin
      h_sseg <= stopwatch[19:4];
      dmask[3] <= 12'h00 != stopwatch[27:16];
      dmask[2] <= 16'h000 != stopwatch[27:12];
      dmask[1] <= 1'b1;
      dmask[0] <= 1'b1;
    end
    4'h3: begin
      h_sseg <= ck_last_clock[15:0];
      dmask[3:0] <= 4'hf;
    end
    default: begin
      h_sseg <= { 2'b00, ck_last_clock[21:8] };
      dmask[2:0] <= 3'hf;
      dmask[3] <= 2'b00 != ck_last_clock[21:20];
    end
  endcase

  wire [31:0] w_sseg;
  assign w_sseg[0] = ~ck_sub[7];
  assign w_sseg[8] = clock[27:24] == 4'h2;
  assign w_sseg[16] = (clock[27:24] == 4'h0) && ~ck_sub[7] || (clock[27:24] == 4'h3);
  assign w_sseg[24] = 1'b0;

  hexmap
  ha
  (
    i_clk,
    h_sseg[3:0],
    w_sseg[7:1]
  );


  hexmap
  hb
  (
    i_clk,
    h_sseg[7:4],
    w_sseg[15:9]
  );


  hexmap
  hc
  (
    i_clk,
    h_sseg[11:8],
    w_sseg[23:17]
  );


  hexmap
  hd
  (
    i_clk,
    h_sseg[15:12],
    w_sseg[31:25]
  );


  always @(posedge i_clk) if((tm_alarm || al_tripped) && ck_sub[7]) o_sseg <= 32'h0000; 
  else o_sseg <= { (dmask[3])? w_sseg[31:24] : 8'h00, (dmask[2])? w_sseg[23:16] : 8'h00, (dmask[1])? w_sseg[15:8] : 8'h00, (dmask[0])? w_sseg[7:0] : 8'h00 };

  reg [17:0] ledreg;

  always @(posedge i_clk) if(ck_pps && ck_ppm) ledreg <= 18'h00; 
  else if(ck_carry) ledreg <= ledreg + 18'h11; 

  assign o_led = (tm_alarm || al_tripped)? { 16{ ck_sub[7] } } : { ledreg[17:10], ledreg[10], ledreg[11], ledreg[12], ledreg[13], ledreg[14], ledreg[15], ledreg[16], ledreg[17] };
  assign o_interrupt = tm_int || al_int;

  always @(posedge i_clk) case(i_wb_addr[2:0])
    3'b000: o_data <= { clock[31:22], ck_last_clock };
    3'b001: o_data <= { 6'h00, timer };
    3'b010: o_data <= stopwatch;
    3'b011: o_data <= { 6'h00, al_tripped, al_enabled, 2'b00, alarm_time };
    3'b100: o_data <= ckspeed;
    3'b101: o_data <= { 2'b00, hack_time };
    3'b110: o_data <= hack_counter[39:8];
    3'b111: o_data <= { hack_counter[7:0], 24'h00 };
  endcase


endmodule

