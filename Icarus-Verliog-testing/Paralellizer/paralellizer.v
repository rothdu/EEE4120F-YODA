`include "./Constants/constants.vh"

module Paralellizer (
    input wire clk,
    input wire reset,
    //To test bench
    input wire [3:0] qspi_data,
    input wire program,
    output wire qspi_ready,
    //To encrypters
    output wire [(`NUM_ENCRYPTERS-1) * (`ENCRYPTER_WIDTH-1):0] encrypters_data,
    output wire [`NUM_ENCRYPTERS-1:0] encrypters_key_rotation [`KEY_ROTATION_WIDTH-1:0],
    output wire [`NUM_ENCRYPTERS-1:0] encrypters_program,
    input wire [`NUM_ENCRYPTERS-1:0] encrypters_ready
);

reg

endmodule