`timescale 1ns / 1ns
`include "./Constants/constants.vh"
`include "./Paralellizer/paralellizer.sv"

module Paralellizer_tb;

    reg clk; 
    reg reset;
    //QSPI
    reg [3:0] qspi_data;
    reg qspi_sending;
    wire qspi_ready;
    //Program
    reg prog;
    //To encrypters
    wire[`ENCRYPTER_WIDTH-1:0] encrypters_data [`NUM_ENCRYPTERS-1:0];
    wire [`KEY_ROTATION_WIDTH-1:0] encrypters_key_rotation [`NUM_ENCRYPTERS-1];
    wire [`NUM_ENCRYPTERS-1:0] encrypters_program;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_data_ready;
    reg [`NUM_ENCRYPTERS-1:0] encrypters_ready;
    //Watchers
    wire [2:0] state_out;
    wire [`KEY_WIDTH-1:0] key_out;
    wire [`KEY_ROTATION_WIDTH-1:0] key_rotation_out;
    wire [`KEY_QSPI_COUNT_REG-1:0] key_index_out;
    wire [`KEY_ENCRYPTER_COUNT_REG-1:0] key_encrypter_index_out;
    wire [`ENCRYPTER_WIDTH-1:0] encrypter_data_packet_out;
    wire [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index_out;
    wire [`NUM_ENCRYPTERS_REG-1:0] encrypter_index_out;
    reg [`ENCRYPTER_WIDTH-1:0] encrypters_data_slice;

    Paralellizer uut(
        .clk(clk),
        .reset(reset),
        .qspi_data(qspi_data),
        .qspi_sending(qspi_sending),
        .qspi_ready(qspi_ready),
        .prog(prog),
        .encrypters_data(encrypters_data),
        .encrypters_key_rotation(encrypters_key_rotation),
        .encrypters_program(encrypters_program),
        .encrypters_data_ready(encrypters_data_ready),
        .encrypters_ready(encrypters_ready),
        .state_out(state_out),
        .key_out(key_out),
        .key_rotation_out(key_rotation_out),
        .key_index_out(key_index_out),
        .key_encrypter_index_out(key_encrypter_index_out),
        .encrypter_data_packet_out(encrypter_data_packet_out),
        .encrypter_data_index_out(encrypter_data_index_out),
        .encrypter_index_out(encrypter_index_out)
    );
    
    reg [3:0] spi_data_values[15:0];
    integer fd, i, j;
    initial begin
        fd = $fopen("./Constants/qspi_data.csv", "r");
        if (fd == -1) begin
            $display("Error opening file!");
            $finish;  // Exit simulation on error
        end
        for (i = 0; i < 256; i++) begin
            j = $fscanf(fd, "%h", spi_data_values[i]);
        end
        $fclose(fd);
        $display(spi_data_values[0]);
    end

    initial begin
        $dumpfile("Paralellizer/paralellizer_tb.vcd");
        $dumpvars(0, Paralellizer_tb);
        $display("Starting paralellizer testbench");
        clk = 0;
        reset = 0;
        qspi_data = 0;
        qspi_sending = 0;
        prog = 0;
        encrypters_ready = 0;


        //expected use
        //set data on neg edge, read on the rising
        #2 reset = 1; #2 reset = 0;
        #2 prog = 1; #2 prog = 0;
        //send key
        #2 qspi_sending = 1;
        for (i = 0; i < `KEY_QSPI_COUNT; i = i + 1) begin
            qspi_data = spi_data_values[i];
            $display("Setting qspi_data to 0x%h", spi_data_values[i]);
            #2;
        end
        qspi_sending = 0;

        #10;
        //simulate encrypters receiving key after paralellizer send it out
        for (i = 0; i < `NUM_ENCRYPTERS; i = i + 1) begin
            encrypters_ready[i] = 1;
            #1;
        end

        //start encrypting data. can only be started from idle state
        #4 qspi_sending = 1;
        for (i = `KEY_QSPI_COUNT; i < 32; i = i + 1) begin
            qspi_data = spi_data_values[i];
            $display("Setting qspi_data to 0x%h", spi_data_values[i]);
            #2;
        end
        #2 qspi_sending = 0;
        #10
        $display("Ending paralellizer testbench");
        $finish;
    end

    always begin
        #1 clk = ~clk;
        encrypters_data_slice[`ENCRYPTER_WIDTH-1:0] = encrypters_data[1][`ENCRYPTER_WIDTH-1:0];
    end

endmodule