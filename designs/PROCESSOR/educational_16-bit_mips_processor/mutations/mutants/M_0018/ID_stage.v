

module ID_stage
(
  input clk,
  input rst,
  input instruction_decode_en,
  output reg [56:0] pipeline_reg_out,
  input [15:0] instruction,
  output [5:0] branch_offset_imm,
  output reg branch_taken,
  output [2:0] reg_read_addr_1,
  output [2:0] reg_read_addr_2,
  input [15:0] reg_read_data_1,
  input [15:0] reg_read_data_2,
  output [2:0] decoding_op_src1,
  output [2:0] decoding_op_src2
);

  reg [15:0] instruction_reg;
  wire [3:0] ir_op_code;
  wire [2:0] ir_dest;
  wire [2:0] ir_src1;
  wire [2:0] ir_src2;
  wire [5:0] ir_imm;
  reg write_back_en;
  wire [2:0] write_back_dest;
  reg write_back_result_mux;
  wire mem_write_en;
  wire [15:0] mem_write_data;
  reg [2:0] ex_alu_cmd;
  wire [15:0] ex_alu_src1;
  wire [15:0] ex_alu_src2;
  reg alu_src2_mux;
  wire decoding_op_is_branch;
  wire decoding_op_is_store;
  wire [3:0] ir_op_code_with_bubble;
  wire [2:0] ir_dest_with_bubble;

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      instruction_reg <= 0;
    end else begin
      if(instruction_decode_en) begin
        instruction_reg <= instruction;
      end 
    end
  end

  assign ir_op_code = instruction_reg[15:12];
  assign ir_dest = instruction_reg[11:9];
  assign ir_src1 = instruction_reg[8:6];
  assign ir_src2 = (decoding_op_is_store)? instruction_reg[11:9] : instruction_reg[5:3];
  assign ir_imm = instruction_reg[5:0];
  assign ir_op_code_with_bubble = (instruction_decode_en)? ir_op_code : 0;
  assign ir_dest_with_bubble = (instruction_decode_en)? ir_dest : 0;

  always @(*) begin
    if(rst) begin
      write_back_en = 0;
      write_back_result_mux = 0;
      ex_alu_cmd = 0;
      alu_src2_mux = 0;
    end else begin
      case(ir_op_code_with_bubble)
        4'b0000: begin
          write_back_en = 0;
          write_back_result_mux = 1'bx;
          ex_alu_cmd = 3'bxxx;
          alu_src2_mux = 1'bx;
        end
        4'b0001: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b000;
          alu_src2_mux = 0;
        end
        4'b0010: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b001;
          alu_src2_mux = 0;
        end
        4'b0011: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b010;
          alu_src2_mux = 0;
        end
        4'b0100: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b011;
          alu_src2_mux = 0;
        end
        4'b0101: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b100;
          alu_src2_mux = 1'bx;
        end
        4'b0110: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b101;
          alu_src2_mux = 0;
        end
        4'b0111: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b110;
          alu_src2_mux = 0;
        end
        4'b1000: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b111;
          alu_src2_mux = 0;
        end
        4'b1001: begin
          write_back_en = 1;
          write_back_result_mux = 0;
          ex_alu_cmd = 3'b000;
          alu_src2_mux = 1;
        end
        4'b1010: begin
          write_back_en = 1;
          write_back_result_mux = 1;
          ex_alu_cmd = 3'b000;
          alu_src2_mux = 1;
        end
        4'b1011: begin
          write_back_en = 0;
          write_back_result_mux = 1'bx;
          ex_alu_cmd = 3'b000;
          alu_src2_mux = 1;
        end
        4'b1100: begin
          write_back_en = 0;
          write_back_result_mux = 1'bx;
          ex_alu_cmd = 3'bxxx;
          alu_src2_mux = 1;
        end
        default: begin
          write_back_en = 0;
          write_back_result_mux = 1'bx;
          ex_alu_cmd = 3'bxxx;
          alu_src2_mux = 1'bx;
          $display("ERROR: Unknown Instruction: %b", ir_op_code_with_bubble);
        end
      endcase
    end
  end

  assign decoding_op_is_branch = (ir_op_code == 4'b1100)? 1 : 0;
  assign decoding_op_is_store = (ir_op_code == 4'b1011)? 1 : 0;
  assign mem_write_data = reg_read_data_2;
  assign mem_write_en = decoding_op_is_store;
  assign write_back_dest = ir_dest_with_bubble;
  assign ex_alu_src1 = reg_read_data_1;
  assign ex_alu_src2 = (alu_src2_mux)? { { 10{ ir_imm[5] } }, ir_imm } : reg_read_data_2;

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      pipeline_reg_out[56:0] <= 0;
    end else begin
      pipeline_reg_out[56:0] <= { ex_alu_cmd[2:0], ex_alu_src1[15:0], ex_alu_src2[15:0], mem_write_en, mem_write_data[15:0], write_back_en, write_back_dest[2:0], write_back_result_mux };
    end
  end

  assign reg_read_addr_1 = ir_src1;
  assign reg_read_addr_2 = ir_src2;

  always @(*) begin
    if(decoding_op_is_branch) begin
      case(ir_dest_with_bubble)
        3'b000: begin
          if(reg_read_data_1 == 0) branch_taken = 1; 
          else branch_taken = 0;
        end
        default: begin
          branch_taken = 0;
          $display("ERROR: Unknown branch condition %b, in branch instruction %b \n", ir_dest_with_bubble, ir_op_code_with_bubble);
        end
      endcase
    end else begin
      branch_taken = 0;
    end
  end

  assign branch_offset_imm = ir_imm;
  assign decoding_op_src1 = ir_src1;
  assign decoding_op_src2 = ((ir_op_code == 4'b0000) || (ir_op_code == 4'b1011) || (ir_op_code == 4'b1010) || (ir_op_code == 4'b1100))? 3'b000 : ir_src2;

endmodule

