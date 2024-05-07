`include "./Constants/constants.vh"

`define IDLE 3'b000
`define READING_KEY 3'b001
`define WAITING_RDY_DATA_IN 3'b010
`define READING_DATA_ENCRYPTING 3'b011
`define SENDING_DATA 3'b100

module Encrypter (
    input wire clk,
    input wire reset,

    input wire [`ENCRYPTER_WIDTH-1:0] dataIn,
    input wire [`KEY_ROTATION_WIDTH-1:0] rot_offset,
    input wire dataRdyIn,
    input wire cap,
    input wire prog,

    output reg [`ENCRYPTER_WIDTH-1:0] dataOut,
    output reg rdyIn,
    output reg dataRdyOut,

    output reg [2:0] state,
    output reg [`KEY_WIDTH-1:0] keyRotated,
    output reg [`ENCRYPTER_WIDTH-1:0] data_in
);

    reg [`KEY_WIDTH-1:0] keyOrigin;
    reg [`KEY_ROTATION_WIDTH:0] offset;

    initial begin
        state <= `IDLE;
        rdyIn = 0;
        dataRdyOut = 0;
        dataOut = 0;
        data_in = 0;
        keyOrigin = 0;
        keyRotated = 0;
        offset = 0;
    end

    always @(posedge reset) begin
        state <= `IDLE;
        rdyIn = 0;
        dataRdyOut = 0;
        dataOut = 0;
        data_in = 0;
        keyOrigin = 0;
        keyRotated = 0;
        offset = 0;
    end

    always @(posedge prog) begin
        state <= `READING_KEY;
    end

    always @(posedge dataRdyIn) begin
        state <= `READING_DATA_ENCRYPTING;
    end

    always @(posedge cap) begin
        state <= `WAITING_RDY_DATA_IN;
        dataRdyOut = 0;
        rdyIn = 1;
    end

    always @(posedge clk) begin
        case (state)
            `READING_KEY: begin
                keyOrigin = dataIn;
                state = `WAITING_RDY_DATA_IN;
                rdyIn = 1;
            end

            `READING_DATA_ENCRYPTING: begin
                data_in = dataIn;
                offset = rot_offset;
                rdyIn = 0;
                keyRotated = (keyOrigin << offset) | (keyOrigin >> (`KEY_WIDTH-offset));
                dataOut = data_in ^ keyRotated;
                state = `SENDING_DATA;
            end
        endcase
    end

    always @(negedge clk) begin
        case (state)
            `SENDING_DATA: begin
                dataRdyOut = 1;
            end
        endcase
    end
endmodule