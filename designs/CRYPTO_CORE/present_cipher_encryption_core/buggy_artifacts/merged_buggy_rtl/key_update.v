

module key_update
(
  output [79:0] data_o,
  input [79:0] data_i,
  input [4:0] round_counter
);

  wire [79:0] s1;wire [79:0] s2;wire [79:0] s3;

  sbox
  key_update_sbox
  (
    .data_o(s1[79:76]),
    .data_i(s2[79:76])
  );

  assign s1 = { data_i[18:0], data_i[78:18] };
  assign s2[75:0] = s1[75:0];
  assign s3 = { s2[79:20], s2[19:17] ^ round_counter, s2[14:0] };
  assign data_o = s3;

endmodule

