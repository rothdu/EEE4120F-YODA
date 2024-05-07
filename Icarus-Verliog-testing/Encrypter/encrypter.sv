`include "./Constants/constants.vh"

`define IDLE 3'b000
`define READING_KEY 3'b001
`define WAITING_RDY_DATA_IN 3'b010
`define READING_DATA 3'b011
`define ENCRYPTING 3'b100
`define SENDING_DATA 3'b101

module Encrypter (
    input wire clk,
    input wire reset,

    input wire [`ENCRYPTER_WIDTH-1:0] dataIn,
    input wire [`KEY_ROTATION_WIDTH-1:0] rot_offset,
    input wire rdyIn,
    input wire rdyOut,
    input wire prog,

    output reg [`ENCRYPTER_WIDTH-1:0] dataOut,
    output reg reqIn,
    output reg reqOut,

    output reg [2:0] state,
    output reg [`KEY_WIDTH-1:0] key,
    output reg [`ENCRYPTER_WIDTH-1:0] data_in
);

    reg [`ENCRYPTER_WIDTH-1:0] data_out;
    reg [`KEY_WIDTH-1:0] keyTemp;
    reg [`KEY_ROTATION_WIDTH:0] offset;

    initial begin
        state <= `IDLE;
        reqIn = 0;
        reqOut = 0;
        dataOut = 0;
        data_in = 0;
        key = 0;
        offset = 0;
    end

    always @(posedge reset) begin
        state <= `IDLE;
        reqIn = 0;
        reqOut = 0;
        dataOut = 0;
        data_in = 0;
        key = 0;
        offset = 0;
    end

    always @(posedge prog) begin
        state <= `READING_KEY;
    end

    always @(posedge rdyIn) begin
        state <= `READING_DATA;
    end

    always @(posedge rdyOut) begin
        state <= `WAITING_RDY_DATA_IN;
        reqOut = 0;
        reqIn = 1;
    end

    always @(posedge clk) begin
        case (state)
            `READING_KEY: begin
                keyTemp = dataIn;
                state = `WAITING_RDY_DATA_IN;
                reqIn = 1;
            end

            `READING_DATA: begin
                data_in = dataIn;
                offset = rot_offset;
                state = `ENCRYPTING;
                reqIn = 0;
            end

            `ENCRYPTING: begin
                key = (keyTemp << offset) | (keyTemp >> (`KEY_WIDTH-offset));
                data_out = data_in ^ key;
                state = `SENDING_DATA;
            end
        endcase
    end

    always @(negedge clk) begin
        case (state)
            `SENDING_DATA: begin
                dataOut = data_out;
                reqOut = 1;
            end
        endcase
    end
endmodule