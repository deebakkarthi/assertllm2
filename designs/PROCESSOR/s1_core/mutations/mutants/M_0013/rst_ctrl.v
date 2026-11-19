

module rst_ctrl
(
  sys_clock_i,
  sys_reset_i,
  cluster_cken_o,
  gclk_o,
  cmp_grst_o,
  cmp_arst_o,
  ctu_tst_pre_grst_o,
  adbginit_o,
  gdbginit_o,
  sys_reset_final_o
);

  input sys_clock_i;
  input sys_reset_i;
  output gclk_o;
  output cluster_cken_o;
  reg cluster_cken_o;
  output cmp_grst_o;
  reg cmp_grst_o;
  output cmp_arst_o;
  reg cmp_arst_o;
  output ctu_tst_pre_grst_o;
  reg ctu_tst_pre_grst_o;
  output adbginit_o;
  reg adbginit_o;
  output gdbginit_o;
  reg gdbginit_o;
  output sys_reset_final_o;
  reg sys_reset_final_o;
  reg [16-1:0] cycle_counter;

  always @(posedge sys_clock_i) begin
    if(sys_reset_i == 1'b1) begin
      cycle_counter = 0;
    end else begin
      if(cycle_counter[16 - 1] == 1'b0) begin
        cycle_counter = cycle_counter + 1;
      end 
    end
  end


  always @(posedge sys_clock_i) begin
    if(sys_reset_i == 1) begin
      cluster_cken_o <= 0;
      cmp_grst_o <= 0;
      cmp_arst_o <= 0;
      ctu_tst_pre_grst_o <= 0;
      adbginit_o <= 0;
      gdbginit_o <= 0;
      sys_reset_final_o <= 1;
    end else begin
      if(cycle_counter < 100) begin
        cluster_cken_o <= 0;
        cmp_grst_o <= 0;
        cmp_arst_o <= 0;
        ctu_tst_pre_grst_o <= 0;
        adbginit_o <= 0;
        gdbginit_o <= 0;
        sys_reset_final_o <= 1;
      end else if(cycle_counter < 1000) begin
        cluster_cken_o <= 0;
        cmp_grst_o <= 0;
        cmp_arst_o <= 1;
        ctu_tst_pre_grst_o <= 0;
        adbginit_o <= 1;
        gdbginit_o <= 0;
        sys_reset_final_o <= 1;
      end else if(cycle_counter < 2000) begin
        cluster_cken_o <= 1;
        cmp_grst_o <= 0;
        cmp_arst_o <= 1;
        ctu_tst_pre_grst_o <= 1;
        adbginit_o <= 1;
        gdbginit_o <= 0;
        sys_reset_final_o <= 1;
      end else if(cycle_counter < 3000) begin
        cluster_cken_o <= 1;
        cmp_grst_o <= 1;
        cmp_arst_o <= 1;
        ctu_tst_pre_grst_o <= 1;
        adbginit_o <= 1;
        gdbginit_o <= 1;
        sys_reset_final_o <= 1;
      end else begin
        cluster_cken_o <= 1;
        cmp_grst_o <= 1;
        cmp_arst_o <= 1;
        ctu_tst_pre_grst_o <= 1;
        adbginit_o <= 1;
        gdbginit_o <= 1;
        sys_reset_final_o <= 0;
      end
    end
  end

  assign gclk_o = (cycle_counter > 899) & sys_clock_i;

endmodule

