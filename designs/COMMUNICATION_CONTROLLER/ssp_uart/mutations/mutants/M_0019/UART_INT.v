

module UART_INT
(
  input Rst,
  input Clk,
  input TF_HF,
  input TF_EF,
  input RF_HF,
  input RF_EF,
  input RTO,
  input Clr_Int,
  input [3:0] USR,
  output reg iTFE,
  output reg iTHE,
  output reg iRHF,
  output reg iRTO
);

  wire reTF_EF;wire feTF_HF;
  wire reRF_HF;wire feRF_HF;wire reRF_EF;
  wire reRTO;

  redet
  RE1
  (
    .rst(Rst),
    .clk(Clk),
    .din(TF_EF),
    .pls(reTF_EF)
  );


  fedet
  FE1
  (
    .rst(Rst),
    .clk(Clk),
    .din(TF_HF),
    .pls(feTF_HF)
  );


  redet
  RE2
  (
    .rst(Rst),
    .clk(Clk),
    .din(RF_HF),
    .pls(reRF_HF)
  );


  fedet
  FE2
  (
    .rst(Rst),
    .clk(Clk),
    .din(RF_HF),
    .pls(feRF_HF)
  );


  redet
  RE3
  (
    .rst(Rst),
    .clk(Clk),
    .din(RF_EF),
    .pls(reRF_EF)
  );


  redet
  RE4
  (
    .rst(Rst),
    .clk(Clk),
    .din(RTO),
    .pls(reRTO)
  );

  assign Rst_iTFE = Rst | iTFE & Clr_Int & USR[0];

  always @(posedge Clk or posedge reTF_EF) begin
    if(reTF_EF) iTFE <= #1 1; 
    else if(Rst_iTFE) iTFE <= #1 reTF_EF; 
  end

  assign Rst_iTHE = Rst | iTHE & Clr_Int & USR[3];

  always @(posedge Clk or posedge feTF_HF) begin
    if(feTF_HF) iTHE <= #1 1; 
    else if(Rst_iTHE) iTHE <= #1 feTF_HF; 
  end

  assign Rst_iRHF = Rst | iRHF & (Clr_Int | feRF_HF | reRF_EF) & USR[2];

  always @(posedge Clk or posedge reRF_HF) begin
    if(reRF_HF) iRHF <= #1 1; 
    else if(Rst_iRHF) iRHF <= #1 reRF_HF; 
  end

  assign Rst_iRTO = Rst | iRTO & Clr_Int & USR[3];

  always @(posedge Clk or posedge reRTO) begin
    if(reRTO) iRTO <= #1 1; 
    else if(Rst_iRTO) iRTO <= #1 reRTO; 
  end


endmodule

