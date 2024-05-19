`timescale 1ns/1ps

`include "./Constants/constants.vh"
`include "./Encrypter/encrypter.sv"

module EncrypterADV_tb;

    reg clk;
    reg reset;

    reg [`ENCRYPTER_WIDTH-1:0] data_in_p;
    reg [`KEY_ROTATION_WIDTH-1:0] key_rotation_p;
    reg prog_p;
    reg data_ready_in_p;
    wire ready_p;

    wire [`ENCRYPTER_WIDTH-1:0] data_out_c;
    wire data_ready_out_c;
    reg capture_c;

EncrypterADV DUT(
    .clk(clk),
    .reset(reset),

    .data_in_p(data_in_p),
    .key_rotation_p(key_rotation_p),
    .prog_p(prog_p),
    .data_ready_in_p(data_ready_in_p),
    .ready_p(ready_p),

    .data_out_c(data_out_c),
    .data_ready_out_c(data_ready_out_c),
    .capture_c(capture_c)
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
    data_in_p = 32'b10110100001101010010101110010011; #10;
    prog_p = 1;#10;

end

initial begin
    //monitoring
    $dumpfile("Encrypter/encrypterADVtb.vcd");
    $dumpvars(1, EncrypterADV_tb);

    //$monitor("data_out: %b\tdataRdyIn: %d\tcap: %d\trdyIn: %d\tdataRdyOut: %d\tkeyRotated: %b\toffset: %d",dataOut,dataRdyIn,cap,rdyIn,dataRdyOut,keyRotated,rot_offset);
    #170;$finish;
end

always @(posedge data_ready_out_c) begin
    #10 capture_c = 0;
    #10 capture_c = 1;
end

always @(posedge ready_p) begin
    #5 
    data_in_p = 32'h1F537C8A;
    key_rotation_p = 5'b00000; #5;
    data_ready_in_p = 1;
end

always @(negedge ready_p) begin
    #10 data_ready_in_p = 0;
end

endmodule