`include "./Constants/constants.vh"

`define STATE_IDLE 3'b000
`define STATE_PROGRAMMING 3'b001
`define STATE_RECEIVING_KEY 3'b010
`define STATE_PROGRAMMING_ENCRYPTERS 3'b011
`define STATE_WAITING_FOR_READY_ENCRYPTERS 3'b100
`define STATE_ENCRYPTING 3'b101

module Parallelizer (
    input wire clk,
    input wire reset,
    //QSPI
    input wire [3:0] qspi_data,
    input wire qspi_sending,
    output reg qspi_ready,
    //Program
    input wire prog,
    //To encrypters
    output reg [`ENCRYPTER_WIDTH-1:0] encrypters_data,
    output reg [`KEY_ROTATION_WIDTH-1:0] encrypters_key_rotation,
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_program,
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_data_ready,
    input wire [`NUM_ENCRYPTERS-1:0] encrypters_ready
    //Watchers
    // output reg [2:0] state_out,
    // output reg [`ENCRYPTER_WIDTH-1:0] key_out
    // output reg [`KEY_ROTATION_WIDTH-1:0] key_rotation_out,
    // output reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] key_index_out,
    // output reg [`ENCRYPTER_WIDTH-1:0] encrypter_data_packet_out,
    // output reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index_out,
    // output reg [`NUM_ENCRYPTERS_REG-1:0] encrypter_index_out
);

reg [2:0] state = `STATE_IDLE;
reg [`ENCRYPTER_WIDTH-1:0] key;
reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] key_index;
reg [`KEY_ROTATION_WIDTH-1:0] key_rotation;

reg [`ENCRYPTER_WIDTH-1:0] encrypter_data_packet;

reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index;
reg [`NUM_ENCRYPTERS_REG-1:0] encrypter_index;
integer i;

initial begin
    // assign state_out = state;
    // assign key_out = key;
    // assign key_rotation_out = key_rotation;
    // assign key_index_out = key_index;
    // assign encrypter_data_packet_out = encrypter_data_packet;
    // assign encrypter_data_index_out = encrypter_data_index;
    // assign encrypter_index_out = encrypter_index;

    qspi_ready = 1'b0;
    encrypters_program = 0;
    key = 0;
    key_index = 0;
end

//read on positive
always @(posedge clk) begin

    if (reset) begin
        state <= `STATE_IDLE;
        qspi_ready = 1'b1;
    end

    case (state)

        `STATE_IDLE: begin 
            if (qspi_sending) begin
                state <= `STATE_ENCRYPTING;
                encrypter_index = 0;
                encrypter_data_index = 0;
                encrypters_data_ready = 0;
                key_rotation = 0;
            end
            if (prog) begin
                state <= `STATE_PROGRAMMING;
                qspi_ready = 1'b1;
                key_index = 0;
            end
        end

        `STATE_PROGRAMMING: if (qspi_sending) state <= `STATE_RECEIVING_KEY;

        `STATE_RECEIVING_KEY: begin 
            if (~qspi_sending) begin
                state = `STATE_IDLE;
            end else begin
                key[key_index*4] = qspi_data[0];
                key[key_index*4+1] = qspi_data[1];
                key[key_index*4+2] = qspi_data[2];
                key[key_index*4+3] = qspi_data[3];
                key_index = key_index + 1;
                if (key_index == `ENCRYPTER_QSPI_COUNT) begin
                    state = `STATE_PROGRAMMING_ENCRYPTERS;
                    qspi_ready = 1'b0;
                end
            end
        end

        `STATE_WAITING_FOR_READY_ENCRYPTERS: begin
            if (& encrypters_ready) begin
                state = `STATE_IDLE;
                encrypter_index = 0;
            end
        end

        `STATE_ENCRYPTING: begin
            if (~qspi_sending) begin
                state = `STATE_IDLE;
            end else begin
            //read spi data
                encrypter_data_packet[encrypter_data_index*4] = qspi_data[0];
                encrypter_data_packet[encrypter_data_index*4+1] = qspi_data[1];
                encrypter_data_packet[encrypter_data_index*4+2] = qspi_data[2];
                encrypter_data_packet[encrypter_data_index*4+3] = qspi_data[3];
                encrypter_data_index = encrypter_data_index + 1;
            end
        end

        default:;

    endcase
end

//write on negative
always @(negedge clk) begin
    case (state)

        `STATE_IDLE: begin    
            qspi_ready = 1'b1;
            encrypters_program = 0;
        end

        `STATE_PROGRAMMING_ENCRYPTERS: begin
            encrypters_data = key;
            for (encrypter_index = 0; encrypter_index < `NUM_ENCRYPTERS; encrypter_index = encrypter_index + 1) begin
                encrypters_program[encrypter_index] = 1'b1;
            end
            state = `STATE_WAITING_FOR_READY_ENCRYPTERS;
        end

        `STATE_ENCRYPTING: begin
            //keep ecrypter data index high for only 1 posedge clock cycle
            if (encrypter_index == 0) begin
                if (encrypters_data_ready[`NUM_ENCRYPTERS-1]) encrypters_data_ready[`NUM_ENCRYPTERS-1] = 0;
            end else begin
                if (encrypters_data_ready[encrypter_index-1]) encrypters_data_ready[encrypter_index-1] = 0;
            end

            if (encrypter_data_index == `ENCRYPTER_QSPI_COUNT) begin
                //when packet full, send to encrypters
                encrypter_data_index = 0;
                
                //check if encrypter is ready for new data
                if (encrypters_ready[encrypter_index]) begin
                    //put packet on encrypter bus
                    encrypters_data = encrypter_data_packet;
                    //put key rot on encrypter bus
                    encrypters_key_rotation = key_rotation;

                    //signal data is ready
                    encrypters_data_ready[encrypter_index] = 1'b1;

                    //move to next encrypter
                    encrypter_index = encrypter_index + 1;
                    if (encrypter_index == `NUM_ENCRYPTERS) encrypter_index = 0;

                    //move to next key rotation
                    key_rotation = key_rotation + 1;
                    if (key_rotation == `ENCRYPTER_WIDTH) key_rotation = 0;

                    //ready for more data as current data has been written
                    qspi_ready = 1'b1;
                end else begin
                    //if encrypter is not ready, wait for it
                    qspi_ready = 1'b0;
                end
            end
        end

        default:;

    endcase
end

endmodule