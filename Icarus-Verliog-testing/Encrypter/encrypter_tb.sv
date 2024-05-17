`timescale 1ns/1ps

`include "./Constants/constants.vh"
`include "./Encrypter/encrypter.sv"

module Encrypter_tb;

    reg clk;
    reg reset;

    reg [`ENCRYPTER_WIDTH-1:0] dataIn;
    reg [`KEY_ROTATION_WIDTH-1:0] rot_offset;
    reg dataRdyIn;
    reg cap;
    reg prog;

    wire [`ENCRYPTER_WIDTH-1:0] dataOut;
    wire rdyIn;
    wire dataRdyOut;
    wire [2:0] state;
    wire [`KEY_WIDTH-1:0] keyRotated;
    wire [`ENCRYPTER_WIDTH-1:0] data_in;

Encrypter DUT(
    .clk(clk),
    .reset(reset),
    .dataIn(dataIn),
    .rot_offset(rot_offset),
    .dataRdyIn(dataRdyIn),
    .cap(cap),
    .prog(prog),
    .dataOut(dataOut),
    .rdyIn(rdyIn),
    .dataRdyOut(dataRdyOut),
    .state(state),
    .keyRotated(keyRotated),
    .data_in(data_in)
);

initial begin
    //clock generation
    clk = 1;
    forever #5 clk = ~clk;
end

initial begin
    //initialization
    reset = 1;#10;
    reset = 0;
end

initial begin
    
    #20;
    dataIn = 16'b1100110011100011; #10;
    prog = 1;#10;

end

initial begin
    //monitoring
    $dumpfile("Encrypter/encrypter_tb.vcd");
    $dumpvars(1, Encrypter_tb);

    $monitor("data_out: %b\tdataRdyIn: %d\tcap: %d\trdyIn: %d\tdataRdyOut: %d\tkeyRotated: %b\toffset: %d",dataOut,dataRdyIn,cap,rdyIn,dataRdyOut,keyRotated,rot_offset);
    #170;$finish;
end

always @(posedge dataRdyOut) begin
    #10 cap = 0;
    #10 cap = 1;
end

always @(posedge rdyIn) begin
    #5 
    dataIn = 16'b1111000011110000;
    rot_offset = 4'b0111; #5;
    dataRdyIn = 1;
end

always @(negedge rdyIn) begin
    #10 dataRdyIn = 0;
end

endmodule