`include "./Constants/constants.vh"

`define IDLE 3'b000
`define READING_KEY 3'b001
`define WAITING_RDY_DATA_IN 3'b010
`define READING_DATA_ENCRYPTING 3'b011
`define SENDING_DATA 3'b100

module Encrypter (
    input wire clk,
    input wire reset,

    // Parallelizer <-> Encrypter signals
    input wire [`ENCRYPTER_WIDTH-1:0] data_in_p,
    input wire [`KEY_ROTATION_WIDTH-1:0] key_rotation_p,
    input wire prog_p,
    input wire data_ready_in_p,
    output reg ready_in_p,

    // Encrypter <-> Collector signals
    output reg [`ENCRYPTER_WIDTH-1:0] data_out_c,
    output reg data_ready_out_c,
    input wire capture_c
);

    reg [2:0] state;
    reg [`KEY_WIDTH-1:0] keyRotated;
    reg [`ENCRYPTER_WIDTH-1:0] data_in_store;
    reg [`KEY_WIDTH-1:0] keyOrigin;
    reg [`KEY_ROTATION_WIDTH:0] offset;

    initial begin
        state <= `IDLE;
        ready_in_p = 0;
        data_ready_out_c = 0;
        data_out_c = 0;
        data_in_store = 0;
        keyOrigin = 0;
        keyRotated = 0;
        offset = 0;
    end

    always @(posedge reset) begin
        state <= `IDLE;
        ready_in_p = 0;
        data_ready_out_c = 0;
        data_out_c = 0;
        data_in_store = 0;
        keyOrigin = 0;
        keyRotated = 0;
        offset = 0;
    end

    always @(posedge prog_p) begin
        state <= `READING_KEY;
    end

    always @(posedge data_ready_in_p) begin
        state <= `READING_DATA_ENCRYPTING;
    end

    always @(posedge capture_c) begin
        state <= `WAITING_RDY_DATA_IN;
        data_ready_out_c = 0;
        ready_in_p = 1;
    end

    always @(posedge clk) begin
        case (state)
            `READING_KEY: begin
                keyOrigin = data_in_p;
                state = `WAITING_RDY_DATA_IN;
                ready_in_p = 1;
            end

            `READING_DATA_ENCRYPTING: begin
                data_in_store = data_in_p;
                offset = key_rotation_p;
                ready_in_p = 0;
                keyRotated = (keyOrigin << offset) | (keyOrigin >> (`KEY_WIDTH-offset));
                data_out_c = data_in_store ^ keyRotated;
                state = `SENDING_DATA;
            end
        endcase
    end

    always @(negedge clk) begin
        case (state)
            `SENDING_DATA: begin
                data_ready_out_c = 1;
            end
        endcase
    end
endmodule