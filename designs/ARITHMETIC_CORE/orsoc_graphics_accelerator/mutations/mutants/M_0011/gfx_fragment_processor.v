

module gfx_fragment_processor
(
  clk_i,
  rst_i,
  pixel_alpha_i,
  x_counter_i,
  y_counter_i,
  z_i,
  u_i,
  v_i,
  bezier_factor0_i,
  bezier_factor1_i,
  bezier_inside_i,
  write_i,
  curve_write_i,
  ack_o,
  pixel_x_o,
  pixel_y_o,
  pixel_z_o,
  pixel_color_i,
  pixel_color_o,
  pixel_alpha_o,
  write_o,
  ack_i,
  texture_ack_i,
  texture_data_i,
  texture_addr_o,
  texture_sel_o,
  texture_request_o,
  texture_enable_i,
  tex0_base_i,
  tex0_size_x_i,
  tex0_size_y_i,
  color_depth_i,
  colorkey_enable_i,
  colorkey_i
);

  parameter point_width = 16;
  input clk_i;
  input rst_i;
  input [7:0] pixel_alpha_i;
  input [point_width-1:0] x_counter_i;
  input [point_width-1:0] y_counter_i;
  input signed [point_width-1:0] z_i;
  input [point_width-1:0] u_i;
  input [point_width-1:0] v_i;
  input [point_width-1:0] bezier_factor0_i;
  input [point_width-1:0] bezier_factor1_i;
  input bezier_inside_i;
  input [31:0] pixel_color_i;
  input write_i;
  input curve_write_i;
  output ack_o;reg ack_o;
  output [point_width-1:0] pixel_x_o;reg [point_width-1:0] pixel_x_o;
  output [point_width-1:0] pixel_y_o;reg [point_width-1:0] pixel_y_o;
  output signed [point_width-1:0] pixel_z_o;reg signed [point_width-1:0] pixel_z_o;
  output [31:0] pixel_color_o;reg [31:0] pixel_color_o;
  output [7:0] pixel_alpha_o;reg [7:0] pixel_alpha_o;
  output write_o;reg write_o;
  input ack_i;
  input texture_ack_i;
  input [31:0] texture_data_i;
  output [31:2] texture_addr_o;
  output [3:0] texture_sel_o;reg [3:0] texture_sel_o;
  output texture_request_o;reg texture_request_o;
  input texture_enable_i;
  input [31:2] tex0_base_i;
  input [point_width-1:0] tex0_size_x_i;
  input [point_width-1:0] tex0_size_y_i;
  input [1:0] color_depth_i;
  input colorkey_enable_i;
  input [31:0] colorkey_i;
  wire [31:0] pixel_offset;
  assign pixel_offset = (color_depth_i == 2'b00)? tex0_size_x_i * v_i + { 16'h0, u_i } : 
                        (color_depth_i == 2'b01)? tex0_size_x_i * v_i + { 16'h0, u_i } << 1 : tex0_size_x_i * v_i + { 16'h0, u_i } << 2;
  assign texture_addr_o = tex0_base_i + pixel_offset[31:2];
  reg [1:0] state;
  parameter wait_state = 2'b00;parameter texture_read_state = 2'b01;parameter write_pixel_state = 2'b10;
  wire [31:0] mem_conv_color_o;

  memory_to_color
  color_proc
  (
    .color_depth_i(u_i[1:0]),
    .mem_i(texture_data_i),
    .mem_lsb_i(color_depth_i),
    .color_o(mem_conv_color_o),
    .sel_o()
  );

  wire transparent_pixel;assign transparent_pixel = (color_depth_i == 2'b00)? mem_conv_color_o[7:0] == colorkey_i[7:0] : 
                             (color_depth_i == 2'b01)? mem_conv_color_o[15:0] == colorkey_i[15:0] : mem_conv_color_o == colorkey_i;
  wire [2*point_width-1:0] bezier_factor0_squared;assign bezier_factor0_squared = bezier_factor0_i * bezier_factor0_i;
  wire bezier_eval;assign bezier_eval = bezier_factor0_squared[2*point_width-1:point_width] > bezier_factor1_i;
  wire bezier_draw;assign bezier_draw = bezier_inside_i ^ bezier_eval;

  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      ack_o <= 1'b0;
      write_o <= 1'b0;
      pixel_x_o <= 1'b0;
      pixel_y_o <= 1'b0;
      pixel_z_o <= 1'b0;
      pixel_color_o <= 1'b0;
      pixel_alpha_o <= 1'b0;
      texture_request_o <= 1'b0;
      texture_sel_o <= 4'b1111;
    end else begin
      case(state)
        wait_state: begin
          ack_o <= write_i & curve_write_i & ~bezier_draw;
          if(write_i & texture_enable_i & (~curve_write_i | bezier_draw)) texture_request_o <= 1'b1; 
          else if(write_i & (~curve_write_i | bezier_draw)) begin
            pixel_x_o <= x_counter_i;
            pixel_y_o <= y_counter_i;
            pixel_z_o <= z_i;
            pixel_color_o <= pixel_color_i;
            pixel_alpha_o <= pixel_alpha_i;
            write_o <= 1'b1;
          end 
        end
        texture_read_state: if(texture_ack_i) begin
          pixel_x_o <= x_counter_i;
          pixel_y_o <= y_counter_i;
          pixel_z_o <= z_i;
          pixel_color_o <= mem_conv_color_o;
          pixel_alpha_o <= pixel_alpha_i;
          texture_request_o <= 1'b0;
          if(colorkey_enable_i & transparent_pixel) ack_o <= 1'b1; 
          else write_o <= 1'b1;
        end 
        write_pixel_state: begin
          write_o <= 1'b0;
          ack_o <= ack_i;
        end
      endcase
    end
  end


  always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) state <= wait_state; 
    else case(state)
      wait_state: if(write_i & texture_enable_i & (~curve_write_i | bezier_draw)) state <= texture_read_state; 
      else if(write_i & (~curve_write_i | bezier_draw)) state <= write_pixel_state; 
      texture_read_state: if(texture_ack_i & colorkey_enable_i) state <= (transparent_pixel)? wait_state : write_pixel_state; 
      else if(texture_ack_i) state <= write_pixel_state; 
      write_pixel_state: if(ack_i) state <= wait_state; 
    endcase
  end


endmodule

