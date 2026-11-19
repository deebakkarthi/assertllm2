

module tiny
(
  clk,
  reset,
  sel,
  addr,
  w,
  data,
  out,
  done
);

  input clk;input reset;
  input sel;
  input [5:0] addr;
  input w;
  input [197:0] data;
  output [197:0] out;
  output done;
  wire [5:0] fsm_addr;
  wire [5:0] ram_a_addr;wire [5:0] ram_b_addr;
  wire [197:0] ram_b_data_in;
  wire ram_a_w;wire ram_b_w;
  wire [197:0] ram_a_data_out;wire [197:0] ram_b_data_out;
  wire [197:0] const0_out;wire [197:0] const1_out;
  wire const0_effective;wire const1_effective;
  wire [197:0] muxer0_out;wire [197:0] muxer1_out;
  wire [8:0] rom_addr;
  wire [25:0] rom_q;
  wire [10:0] pe_ctrl;
  assign out = ram_a_data_out;

  select
  select0
  (
    sel,
    addr,
    fsm_addr,
    w,
    ram_a_addr,
    ram_a_w
  );


  rom
  rom0
  (
    clk,
    rom_addr,
    rom_q
  );


  FSM
  fsm0
  (
    clk,
    reset,
    rom_addr,
    rom_q,
    fsm_addr,
    ram_b_addr,
    ram_b_w,
    pe_ctrl,
    done
  );


  pairing_const
  const0
  (
    clk,
    ram_a_addr,
    const0_out,
    const0_effective
  ),
  const1
  (
    clk,
    ram_b_addr,
    const1_out,
    const1_effective
  );


  ram
  ram0
  (
    clk,
    ram_a_w,
    ram_a_addr,
    data,
    ram_a_data_out,
    ram_b_w,
    ram_b_addr[3:0],
    ram_b_data_in,
    ram_b_data_out
  );


  muxer
  muxer0
  (
    ram_a_data_out,
    const0_out,
    const0_effective,
    muxer0_out
  ),
  muxer1
  (
    ram_b_data_out,
    const1_out,
    const1_effective,
    muxer1_out
  );


  PE
  pe0
  (
    clk,
    reset,
    pe_ctrl,
    muxer1_out,
    muxer0_out[193:0],
    muxer0_out[193:0],
    ram_b_data_in[193:0]
  );

  assign ram_b_data_in[197:194] = 0;

endmodule



module select
(
  sel,
  addr_in,
  addr_fsm_in,
  w_in,
  addr_out,
  w_out
);

  input sel;
  input [5:0] addr_in;
  input [5:0] addr_fsm_in;
  input w_in;
  output [5:0] addr_out;
  output w_out;
  assign addr_out = (sel)? addr_in : addr_fsm_in;
  assign w_out = sel & w_in;

endmodule



module muxer
(
  from_ram,
  from_const,
  const_effective,
  out
);

  input [197:0] from_ram;input [197:0] from_const;
  input const_effective;
  output [197:0] out;
  assign out = (const_effective)? from_const : from_ram;

endmodule

