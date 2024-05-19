`include "./Constants/constants.vh"

`define IDLE 3'b000
`define READING_KEY 3'b001
`define WAITING_RDY_DATA_IN 3'b010
`define READING_DATA_ENCRYPTING 3'b011
`define SENDING_DATA 3'b100
`define ACKNOWLEDGING_CAPTURE 3'b101

module Encrypter (
    input wire clk,
    input wire reset,

    // Parallelizer <-> Encrypter signals
    input wire [`ENCRYPTER_WIDTH-1:0] data_in_p,
    input wire [`KEY_ROTATION_WIDTH-1:0] key_rotation_p,
    input wire prog_p,
    input wire data_ready_in_p,
    output reg ready_p,

    // Encrypter <-> Collector signals
    output reg [`ENCRYPTER_WIDTH-1:0] data_out_c,
    output reg data_ready_out_c,
    input wire capture_c
);

    reg [2:0] state;
    reg [`ENCRYPTER_WIDTH-1:0] keyRotated;
    reg [`ENCRYPTER_WIDTH-1:0] data_in_store;
    reg [`ENCRYPTER_WIDTH-1:0] keyOrigin;
    reg [`KEY_ROTATION_WIDTH:0] offset;

    initial begin
        state <= `IDLE;
        ready_p = 0;
        data_ready_out_c = 0;
        data_out_c = 0;
        data_in_store = 0;
        keyOrigin = 0;
        keyRotated = 0;
        offset = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= `IDLE;
            ready_p = 0;
            data_ready_out_c = 0;
            data_out_c = 0;
            data_in_store = 0;
            keyOrigin = 0;
            keyRotated = 0;
            offset = 0;
        end
        
        case (state)

            `IDLE: begin
                if (prog_p) state <= `READING_KEY;
            end

            `WAITING_RDY_DATA_IN: begin
                if (data_ready_in_p) state <= `READING_DATA_ENCRYPTING;
            end

            `READING_KEY: begin
                keyOrigin = data_in_p;
                state = `WAITING_RDY_DATA_IN;
            end

            `READING_DATA_ENCRYPTING: begin
                data_in_store = data_in_p;
                offset = key_rotation_p;
                ready_p = 0;
                keyRotated = (keyOrigin << offset) | (keyOrigin >> (`ENCRYPTER_WIDTH-offset));
                #20;
                state = `SENDING_DATA;
            end

            `SENDING_DATA: begin
                if (capture_c)
                state <= `ACKNOWLEDGING_CAPTURE;
            end

        endcase
    end

    always @(negedge clk) begin
        case (state)
            `SENDING_DATA: begin
                data_out_c = data_in_store ^ keyRotated;
                data_ready_out_c = 1;
            end

            `WAITING_RDY_DATA_IN: begin
                if (~ready_p) ready_p = 1;
            end

            `ACKNOWLEDGING_CAPTURE: begin
                state <= `WAITING_RDY_DATA_IN;
                data_ready_out_c = 0;
                ready_p = 1;
            end
        endcase
    end
endmodule


module EncrypterADV (
    input wire clk,
    input wire reset,

    // Parallelizer <-> Encrypter signals
    input wire [`ENCRYPTER_WIDTH-1:0] data_in_p,
    input wire [`KEY_ROTATION_WIDTH-1:0] key_rotation_p,
    input wire prog_p,
    input wire data_ready_in_p,
    output reg ready_p,

    // Encrypter <-> Collector signals
    output reg [`ENCRYPTER_WIDTH-1:0] data_out_c,
    output reg data_ready_out_c,
    input wire capture_c
);

    reg [2:0] state;
    reg [`ENCRYPTER_WIDTH-1:0] keyRotated;
    reg [64-1:0] keySquared;
    reg [`ENCRYPTER_WIDTH-1:0] keyNew;
    reg [`ENCRYPTER_WIDTH-1:0] keyMod;
    reg [`ENCRYPTER_WIDTH-1:0] data_in_store;
    reg [`ENCRYPTER_WIDTH-1:0] keyOrigin;
    reg [`KEY_ROTATION_WIDTH:0] offset;
    reg [`ENCRYPTER_WIDTH-1:0] xorOffset;

    initial begin
        state <= `IDLE;
        ready_p = 0;
        data_ready_out_c = 0;
        data_out_c = 0;
        data_in_store = 0;
        keyNew = 0;
        keyRotated = 0;
        keyOrigin = 0;
        keySquared = 0;
        keyMod = 0;
        offset = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= `IDLE;
            ready_p = 0;
            data_ready_out_c = 0;
            data_out_c = 0;
            data_in_store = 0;
            keyNew = 0;
            keyRotated = 0;
            keyOrigin = 0;
            keySquared = 0;
            keyMod = 0;
            offset = 0;
        end
        
        case (state)

            `IDLE: begin
                if (prog_p) state <= `READING_KEY;
            end

            `WAITING_RDY_DATA_IN: begin
                if (data_ready_in_p) state <= `READING_DATA_ENCRYPTING;
            end

            `READING_KEY: begin
                keyOrigin = data_in_p;
                state = `WAITING_RDY_DATA_IN;
            end

            `READING_DATA_ENCRYPTING: begin
                data_in_store = data_in_p;
                offset = key_rotation_p;
                ready_p = 0;
                xorOffset = (keyOrigin & 5'b11111)^offset;
                keyNew = keyOrigin^(xorOffset<<27);
                keyRotated = (keyNew << xorOffset) | (keyNew >> (`ENCRYPTER_WIDTH-xorOffset));
                keySquared = keyRotated*keyRotated;
                keyMod = keySquared%4294967311;
                #20;
                state = `SENDING_DATA;
            end

            `SENDING_DATA: begin
                if (capture_c)
                state <= `ACKNOWLEDGING_CAPTURE;
            end

        endcase
    end

    always @(negedge clk) begin
        case (state)
            `SENDING_DATA: begin
                data_out_c = data_in_store ^ keyMod;
                data_ready_out_c = 1;
            end

            `WAITING_RDY_DATA_IN: begin
                if (~ready_p) ready_p = 1;
            end

            `ACKNOWLEDGING_CAPTURE: begin
                state <= `WAITING_RDY_DATA_IN;
                data_ready_out_c = 0;
                ready_p = 1;
            end
        endcase
    end
endmodule