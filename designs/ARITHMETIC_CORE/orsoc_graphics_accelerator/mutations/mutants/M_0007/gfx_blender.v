

module gfx_blender
(
  clk_i,
  rst_i,
  blending_enable_i,
  target_base_i,
  target_size_x_i,
  target_size_y_i,
  color_depth_i,
  x_counter_i,
  y_counter_i,
  z_i,
  alpha_i,
  global_alpha_i,
  write_i,
  ack_o,
  target_ack_i,
  target_addr_o,
  target_data_i,
  target_sel_o,
  target_request_o,
  wbm_busy_i,
  pixel_x_o,
  pixel_y_o,
  pixel_z_o,
  pixel_color_i,
  pixel_color_o,
  write_o,
  ack_i
);

  parameter point_width = 16;
  input clk_i;
  input rst_i;
  input blending_enable_i;
  input [31:2] target_base_i;
  input [point_width-1:0] target_size_x_i;
  input [point_width-1:0] target_size_y_i;
  input [1:0] color_depth_i;
  input [point_width-1:0] x_counter_i;
  input [point_width-1:0] y_counter_i;
  input signed [point_width-1:0] z_i;
  input [7:0] alpha_i;
  input [7:0] global_alpha_i;
  input [31:0] pixel_color_i;
  input write_i;
  output ack_o;reg ack_o;
  input target_ack_i;
  output [31:2] target_addr_o;
  input [31:0] target_data_i;
  output [3:0] target_sel_o;reg [3:0] target_sel_o;
  output target_request_o;reg target_request_o;
  input wbm_busy_i;
  output [point_width-1:0] pixel_x_o;reg [point_width-1:0] pixel_x_o;
  output [point_width-1:0] pixel_y_o;reg [point_width-1:0] pixel_y_o;
  output signed [point_width-1:0] pixel_z_o;reg signed [point_width-1:0] pixel_z_o;
  output [31:0] pixel_color_o;reg [31:0] pixel_color_o;
  output write_o;reg write_o;
  input ack_i;
  reg [1:0] state;
  parameter wait_state = 2'b00;parameter target_read_state = 2'b01;parameter write_pixel_state = 2'b10;
  reg [15:0] combined_alpha_reg;
  wire [7:0] alpha;assign alpha = combined_alpha_reg[15:8];
  wire [31:0] pixel_offset;
  assign pixel_offset = (color_depth_i == 2'b00)? target_size_x_i * y_counter_i + { 16'h0, x_counter_i } : 
                        (color_depth_i == 2'b01)? target_size_x_i * y_counter_i + { 16'h0, x_counter_i } << 1 : target_size_x_i * y_counter_i + { 16'h0, x_counter_i } << 2;
  assign target_addr_o = target_base_i + pixel_offset[31:2];
  wire [7:0] blend_color_r;assign blend_color_r = (color_depth_i == 2'b00)? pixel_color_i[7:0] : 
                         (color_depth_i == 2'b01)? pixel_color_i[15:11] : pixel_color_i[23:16];
  wire [7:0] blend_color_g;assign blend_color_g = (color_depth_i == 2'b00)? pixel_color_i[7:0] : 
                         (color_depth_i == 2'b01)? pixel_color_i[10:5] : pixel_color_i[15:8];
  wire [7:0] blend_color_b;assign blend_color_b = (color_depth_i == 2'b00)? pixel_color_i[7:0] : 
                         (color_depth_i == 2'b01)? pixel_color_i[4:0] : pixel_color_i[7:0];
  wire [7:0] target_color_r;assign target_color_r = (color_depth_i == 2'b00)? dest_color[7:0] : 
                          (color_depth_i == 2'b01)? dest_color[15:11] : target_data_i[23:16];
  wire [7:0] target_color_g;assign target_color_g = (color_depth_i == 2'b00)? dest_color[7:0] : 
                          (color_depth_i == 2'b01)? dest_color[10:6] : target_data_i[15:8];
  wire [7:0] target_color_b;assign target_color_b = (color_depth_i == 2'b00)? dest_color[7:0] : 
                          (color_depth_i == 2'b01)? dest_color[4:0] : target_data_i[7:0];
  wire [15:0] alpha_color_r;assign alpha_color_r = blend_color_r * alpha + target_color_r * (8'hff - alpha);
  wire [15:0] alpha_color_g;assign alpha_color_g = blend_color_g * alpha + target_color_g * (8'hff - alpha);
  wire [15:0] alpha_color_b;assign alpha_color_b = blend_color_b * alpha + target_color_b * (8'hff - alpha);
  wire [31:0] dest_color;

  memory_to_color
  memory_proc
  (
    .color_depth_i(color_depth_i),
    .mem_i(target_data_i),
    .mem_lsb_i(x_counter_i[1:0]),
    .color_o(dest_color),
    .sel_o()
  );


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      ack_o <= 1'b0;
      write_o <= 1'b0;
      pixel_x_o <= 1'b0;
      pixel_y_o <= 1'b0;
      pixel_z_o <= 1'b0;
      pixel_color_o <= 1'b0;
      target_request_o <= 1'b0;
      target_sel_o <= 4'b1111;
    end else begin
      case(state)
        wait_state: begin
          ack_o <= 1'b0;
          if(write_i) begin
            if(!blending_enable_i) begin
              pixel_x_o <= x_counter_i;
              pixel_y_o <= y_counter_i;
              pixel_z_o <= z_i;
              pixel_color_o <= pixel_color_i;
              write_o <= 1'b1;
            end else begin
              target_request_o <= !wbm_busy_i;
              combined_alpha_reg <= alpha_i * global_alpha_i;
            end
          end 
        end
        target_read_state: if(target_ack_i) begin
          write_o <= 1'b1;
          pixel_x_o <= x_counter_i;
          pixel_y_o <= y_counter_i;
          pixel_z_o <= z_i;
          target_request_o <= 1'b0;
          pixel_color_o <= (color_depth_i == 2'b00)? { alpha_color_r[15:8] } : 
                           (color_depth_i == 2'b01)? { alpha_color_r[12:8], alpha_color_g[13:8], alpha_color_b[12:8] } : { alpha_color_r[15:8], alpha_color_g[15:8], alpha_color_b[15:8] };
        end else target_request_o <= !wbm_busy_i | target_request_o;
        write_pixel_state: begin
          write_o <= 1'b0;
          if(ack_i) ack_o <= 1'b1; 
        end
      endcase
    end
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) state <= wait_state; 
    else case(state)
      wait_state: if(write_i & blending_enable_i) state <= target_read_state; 
      else if(write_i) state <= write_pixel_state; 
      target_read_state: if(target_ack_i) state <= write_pixel_state; 
      write_pixel_state: if(ack_i) state <= wait_state; 
    endcase
  end


endmodule

