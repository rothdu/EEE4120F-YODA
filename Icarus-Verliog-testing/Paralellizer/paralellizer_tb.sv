`timescale 1ns / 1ns
`include "./Constants/constants.vh"
`include "./Paralellizer/paralellizer.v"

module Paralellizer_tb;

    reg clk;
    reg reset;

    // QSPI data and program signals
    reg [3:0] qspi_data;
    reg prog;

    // Encrypter ready signals (mocked for testbench)
    reg [`NUM_ENCRYPTERS-1:0] encrypters_ready;

    // Output signals for monitoring
    wire [`NUM_ENCRYPTERS-1:0] encrypters_data [`ENCRYPTER_WIDTH-1:0];
    wire [`NUM_ENCRYPTERS-1:0] encrypters_key_rotation [`ENCRYPTER_WIDTH-1:0];
    wire [`NUM_ENCRYPTERS-1:0] encrypters_program;
    wire qspi_ready;

    Paralellizer uut(
        .clk(clk),
        .reset(reset),
        .qspi_data(qspi_data),
        .prog(prog),
        .qspi_ready(qspi_ready),
        .encrypters_data(encrypters_data),
        .encrypters_key_rotation(encrypters_key_rotation),
        .encrypters_program(encrypters_program),
        .encrypters_ready(encrypters_ready)
    );

endmodule