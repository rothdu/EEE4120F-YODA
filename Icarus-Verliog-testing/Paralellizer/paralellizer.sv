`include "./Constants/constants.vh"

`define STATE_IDLE 3'b000
`define STATE_PROGRAMMING 3'b001
`define STATE_RECEIVING_KEY 3'b010
`define STATE_PROGRAMMING_ENCRYPTERS 3'b011
`define STATE_WAITING_FOR_READY_ENCRYPTERS 3'b100
`define STATE_ENCRYPTING 3'b101

module Paralellizer (
    input wire clk,
    input wire reset,
    //QSPI
    input wire [3:0] qspi_data,
    input wire qspi_sending,
    output reg qspi_ready,
    //Program
    input wire prog,
    //To encrypters
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_data [`ENCRYPTER_WIDTH-1:0],
    output reg [`NUM_ENCRYPTERS-1] encrypters_key_rotation [`KEY_ROTATION_WIDTH-1:0],
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_program,
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_data_ready,
    input wire [`NUM_ENCRYPTERS-1:0] encrypters_ready
);

reg [2:0] state = `STATE_IDLE;
reg [`KEY_WIDTH-1:0] key;
reg [`KEY_ROTATION_WIDTH-1:0] key_rotation;
reg [`KEY_QSPI_COUNT_REG-1:0] key_index;
reg [`ENCRYPTER_WIDTH-1:0] encrypter_data_packet;
reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index;
reg [`NUM_ENCRYPTERS_REG-1:0] encrypter_index;

initial begin
    qspi_ready = 1'b0;
    encrypters_program = 0;
    key = 0;
    key_index = 0;
end

always @(posedge reset) begin
    state <= `STATE_IDLE;
    qspi_ready = 1'b1;
end

always @(posedge prog) begin
    if (state == `STATE_IDLE) begin
        state <= `STATE_PROGRAMMING;
        qspi_ready = 1'b1;
        key_index = 0;
    end
end

always @(posedge qspi_sending) begin
    case (state)

        `STATE_IDLE: begin
            state <= `STATE_ENCRYPTING;
            encrypter_index = 0;
            encrypter_data_index = 0;
            key_rotation = 0;
        end

        `STATE_PROGRAMMING: state <= `STATE_RECEIVING_KEY;

        default:;

    endcase
end

always @(negedge qspi_sending) begin
    case (state)
        `STATE_ENCRYPTING: state = `STATE_IDLE;
        `STATE_RECEIVING_KEY: state = `STATE_IDLE;
        default:;
    endcase
end

//read on positive
always @(posedge clk) begin
    case (state)

        `STATE_RECEIVING_KEY: begin 
            key[key_index*4] = qspi_data[0];
            key[key_index*4+1] = qspi_data[1];
            key[key_index*4+2] = qspi_data[2];
            key[key_index*4+3] = qspi_data[3];
            key_index = key_index + 1;
            if (key_index == `KEY_QSPI_COUNT) begin
                state = `STATE_PROGRAMMING_ENCRYPTERS;
                qspi_ready = 1'b0;
            end
        end

        `STATE_WAITING_FOR_READY_ENCRYPTERS: begin
            state = `STATE_IDLE;
            for (encrypter_index = 0; encrypter_index < `NUM_ENCRYPTERS; encrypter_index++) begin
                if (~encrypters_ready[encrypter_index]) begin
                    state = `STATE_WAITING_FOR_READY_ENCRYPTERS;
                end
            end
            if (state == `STATE_IDLE) qspi_ready = 1'b1;
        end

        default:;

    endcase
end

//write on negative
always @(negedge clk) begin
    case (state)

        `STATE_PROGRAMMING_ENCRYPTERS: begin
            for (encrypter_index = 0; encrypter_index < `NUM_ENCRYPTERS; encrypter_index++) begin
                encrypters_data[encrypter_index] = key;
                encrypters_program[encrypter_index] = 1'b1;
            end
            state = `STATE_WAITING_FOR_READY_ENCRYPTERS;
        end

        `STATE_ENCRYPTING: begin
            encrypter_data_packet[encrypter_data_index*4] = qspi_data[0];
            encrypter_data_packet[encrypter_data_index*4+1] = qspi_data[1];
            encrypter_data_packet[encrypter_data_index*4+2] = qspi_data[2];
            encrypter_data_packet[encrypter_data_index*4+3] = qspi_data[3];
            encrypter_data_index = encrypter_data_index + 1;

            if (encrypter_data_index == `ENCRYPTER_QSPI_COUNT) begin
                encrypter_data_index = 0;
                encrypters_data[encrypter_index] = encrypter_data_packet;
                encrypters_key_rotation[encrypter_index] = key_rotation;

                encrypter_index = encrypter_index + 1;
                if (encrypter_index == `NUM_ENCRYPTERS) encrypter_data_index = 0;

                key_rotation = key_rotation + 1;
                if (key_rotation == `KEY_ROTATION_WIDTH) key_rotation = 0;
            end
        end

        default:;

    endcase
end

endmodule