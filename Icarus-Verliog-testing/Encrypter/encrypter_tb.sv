`timescale 1ns/1ps

`include "./Constants/constants.vh"
`include "./Encrypter/encrypter.sv"

module Encrypter_tb;

    reg clk;
    reg reset;

    reg [`ENCRYPTER_WIDTH-1:0] dataIn;
    reg [`KEY_ROTATION_WIDTH-1:0] rot_offset;
    reg rdyIn;
    reg rdyOut;
    reg prog;

    wire [`ENCRYPTER_WIDTH-1:0] dataOut;
    wire reqIn;
    wire reqOut;
    wire [2:0] state;
    wire [`KEY_WIDTH-1:0] key;
    wire [`ENCRYPTER_WIDTH-1:0] data_in;

Encrypter DUT(
    .clk(clk),
    .reset(reset),
    .dataIn(dataIn),
    .rot_offset(rot_offset),
    .rdyIn(rdyIn),
    .rdyOut(rdyOut),
    .prog(prog),
    .dataOut(dataOut),
    .reqIn(reqIn),
    .reqOut(reqOut),
    .state(state),
    .key(key),
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

    $monitor("data_out: %b\trdyIn: %d\trdyOut: %d\treqIn: %d\treqOut: %d\tkey: %b\toffset: %d",dataOut,rdyIn,rdyOut,reqIn,reqOut,key,rot_offset);
    #170;$finish;
end

always @(posedge reqOut) begin
    #10 rdyOut = 0;
    #20 rdyOut = 1;
end

always @(posedge reqIn) begin
    #5 
    dataIn = 16'b1111000011110000;
    rot_offset = 4'b0111; #5;
    rdyIn = 1;
end

always @(negedge reqIn) begin
    #10 rdyIn = 0;
end

endmodule