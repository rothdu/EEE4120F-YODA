`timescale 1ns/1ns
`include "./Collector/collector.sv"



module collector_tb;

reg clk;
reg [31:0] data_in;
wire wire1;
wire wire2;
wire wire3;
wire wire4;
wire [3:0] data_chunk;


Collector uut(clk,data_in,wire1,wire2,wire3,wire4,data_chunk);


initial begin
    $dumpfile("./Collector/collector_tb.vcd");
    $dumpvars(0, collector_tb);
    $display("Starting testbench");
    data_in = 32'h23555765;
    clk = 0;
    #100;
    $finish;    
end

always begin
    #2 clk = ~clk; 
end
    
endmodule