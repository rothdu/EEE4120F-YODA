`include "./Constants/constants.vh"

`define IDLE 3'b000
`define WAITING_RDY_DATA_IN 3'b001
`define READING_KEY 3'b010
`define READING_DATA 3'b011
`define ENCRYPTING 3'b100
`define WAITING_RDY_DATA_OUT 3'b101
`define SENDING_DATA 3'b110


module Encrypter (
    input wire clk,
    input wire reset,

    input wire [`ENCRYPTER_WIDTH-1:0] dataIn,
    input wire [`KEY_ROTATION_WIDTH-1:0] rot_offset,
    input wire rdyIn,
    input wire rdyOut,
    input wire prog,
    input wire error,

    output reg [`ENCRYPTER_WIDTH-1:0] dataOut,
    output reg reqIn,
    output reg reqOut,

    output reg [2:0] state,
    output reg [`KEY_WIDTH-1:0] key,
    output reg [`ENCRYPTER_WIDTH-1:0] data_in
);
    
    reg [`KEY_WIDTH-1:0] keyTemp;
    reg [`KEY_ROTATION_WIDTH:0] offset;

    initial begin
        state <= `IDLE;
        reqIn = 1;
        reqOut = 0;
        dataOut = 0;
        data_in = 0;
        key = 0;
        offset = 0;
    end

    always @(posedge reset) begin
        state <= `IDLE;
        reqIn = 1;
        reqOut = 0;
        dataOut = 0;
        data_in = 0;
        key = 0;
        offset = 0;
    end

    always @(posedge prog) begin
        if (state == `WAITING_RDY_DATA_OUT) begin
            state <= `SENDING_DATA;
        end
        state <= `WAITING_RDY_DATA_IN;
    end

    always @(posedge rdyIn) begin
        case (state)
            `IDLE: state <= `READING_KEY;
            `WAITING_RDY_DATA_IN: state <= `READING_DATA;
        endcase 
    end

    always @(posedge rdyOut) begin
        if (state == `WAITING_RDY_DATA_OUT) begin
            state <= `SENDING_DATA;
        end
    end

    // always @(posedge error) begin
    //     state = encryption;
    // end

    always @(posedge clk) begin
        case (state)
            `IDLE: begin
                reqIn = 1;
            end

            `READING_KEY: begin
                reqIn <= 0;
                keyTemp <= dataIn;
                state <= `WAITING_RDY_DATA_IN;
                reqIn <= 1;
            end

            `READING_DATA: begin
                reqIn = 0;
                data_in = dataIn;
                offset = rot_offset;
                state = `ENCRYPTING;
            end

            `ENCRYPTING: begin
                key = (keyTemp << offset) | (keyTemp >> (`KEY_WIDTH-offset));
                dataOut = data_in ^ key;
                state = `WAITING_RDY_DATA_OUT;
                reqOut = 1;
            end

            `SENDING_DATA: begin
                reqOut = 0;
                state = `WAITING_RDY_DATA_IN;
            end
        endcase
    end
endmodule