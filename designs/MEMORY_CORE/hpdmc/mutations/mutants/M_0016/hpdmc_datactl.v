

module hpdmc_datactl
(
  input sys_clk,
  input sdram_rst,
  input read,
  input write,
  input [3:0] concerned_bank,
  output reg read_safe,
  output reg write_safe,
  output [3:0] precharge_safe,
  output reg ack,
  output reg direction,
  output direction_r,
  input tim_cas,
  input [1:0] tim_wr
);

  reg [2:0] read_safe_counter;

  always @(posedge sys_clk) begin
    if(sdram_rst) begin
      read_safe_counter <= 3'd0;
      read_safe <= 1'b1;
    end else begin
      if(read) begin
        read_safe_counter <= 3'd4;
        read_safe <= 1'b0;
      end else if(write) begin
        read_safe_counter <= 3'd5;
        read_safe <= 1'b0;
      end else begin
        if(read_safe_counter == 3'd1) read_safe <= 1'b1; 
        if(~read_safe) read_safe_counter <= read_safe_counter - 3'd1; 
      end
    end
  end

  reg [2:0] write_safe_counter;

  always @(posedge sys_clk) begin
    if(sdram_rst) begin
      write_safe_counter <= 3'd0;
      write_safe <= 1'b1;
    end else begin
      if(read) begin
        write_safe_counter <= { 1'b1, tim_cas, ~tim_cas };
        write_safe <= 1'b0;
      end else if(write) begin
        write_safe_counter <= 3'd3;
        write_safe <= 1'b0;
      end else begin
        if(write_safe_counter == 3'd1) write_safe <= 1'b1; 
        if(~write_safe) write_safe_counter <= write_safe_counter - 3'd1; 
      end
    end
  end

  reg ack_read3;
  reg ack_read2;
  reg ack_read1;
  reg ack_read0;

  always @(posedge sys_clk) begin
    if(sdram_rst) begin
      ack_read3 <= 1'b0;
      ack_read2 <= 1'b0;
      ack_read1 <= 1'b0;
      ack_read0 <= 1'b1;
    end else begin
      if(tim_cas) begin
        ack_read3 <= read;
        ack_read2 <= ack_read3;
        ack_read1 <= ack_read2;
        ack_read0 <= ack_read1;
      end else begin
        ack_read2 <= read;
        ack_read1 <= ack_read2;
        ack_read0 <= ack_read1;
      end
    end
  end

  reg ack0;

  always @(posedge sys_clk) begin
    if(sdram_rst) begin
      ack0 <= 1'b0;
      ack <= 1'b0;
    end else begin
      ack0 <= ack_read0 | write;
      ack <= ack0;
    end
  end

  reg write_d;
  reg [2:0] counter_writedirection;

  always @(posedge sys_clk) begin
    if(sdram_rst) begin
      counter_writedirection <= 3'd0;
      direction <= 1'b0;
    end else begin
      if(write_d) begin
        counter_writedirection <= 3'b101;
        direction <= 1'b1;
      end else begin
        if(counter_writedirection == 3'b001) direction <= 1'b0; 
        if(direction) counter_writedirection <= counter_writedirection - 3'd1; 
      end
    end
  end

  assign direction_r = write_d | |counter_writedirection;

  always @(posedge sys_clk) begin
    if(sdram_rst) write_d <= 1'b0; 
    else write_d <= write;
  end


  hpdmc_banktimer
  banktimer0
  (
    .sys_clk(sys_clk),
    .sdram_rst(sdram_rst),
    .tim_cas(tim_cas),
    .tim_wr(tim_wr),
    .read(read & concerned_bank[0]),
    .write(write & concerned_bank[0]),
    .precharge_safe(precharge_safe[0])
  );


  hpdmc_banktimer
  banktimer1
  (
    .sys_clk(sys_clk),
    .sdram_rst(sdram_rst),
    .tim_cas(tim_cas),
    .tim_wr(tim_wr),
    .read(read & concerned_bank[1]),
    .write(write & concerned_bank[1]),
    .precharge_safe(precharge_safe[1])
  );


  hpdmc_banktimer
  banktimer2
  (
    .sys_clk(sys_clk),
    .sdram_rst(sdram_rst),
    .tim_cas(tim_cas),
    .tim_wr(tim_wr),
    .read(read & concerned_bank[2]),
    .write(write & concerned_bank[2]),
    .precharge_safe(precharge_safe[2])
  );


  hpdmc_banktimer
  banktimer3
  (
    .sys_clk(sys_clk),
    .sdram_rst(sdram_rst),
    .tim_cas(tim_cas),
    .tim_wr(tim_wr),
    .read(read & concerned_bank[3]),
    .write(write & concerned_bank[3]),
    .precharge_safe(precharge_safe[3])
  );


endmodule

