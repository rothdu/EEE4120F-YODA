`timescale 1ns / 1ns
`include "./Constants/constants.vh"
`include "./Parallelizer/parallelizer.sv"

module Parallelizer_tb;

    reg clk; 
    reg reset;
    //QSPI
    reg [3:0] qspi_data;
    reg qspi_sending;
    wire qspi_ready;
    //Program
    reg prog;
    //To encrypters
    wire[`ENCRYPTER_WIDTH-1:0] encrypters_data;
    wire [`KEY_ROTATION_WIDTH-1:0] encrypters_key_rotation;
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

    Parallelizer uut(
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
        .state_out(state_out)
        // .key_out(key_out),
        // .key_rotation_out(key_rotation_out),
        // .key_index_out(key_index_out),
        // .key_encrypter_index_out(key_encrypter_index_out),
        // .encrypter_data_packet_out(encrypter_data_packet_out),
        // .encrypter_data_index_out(encrypter_data_index_out),
        // .encrypter_index_out(encrypter_index_out)
    );
    
    reg [3:0] spi_data_values[256:0];
    reg [3:0] encrypters_delays [`NUM_ENCRYPTERS-1:0];
    integer fd, i, j;

    initial begin
        //fill spi_data_values with data from file
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

        for (j = 0; j < `NUM_ENCRYPTERS-1; j = j + 1) begin
            encrypters_delays[j] = 0;
        end
    end

    initial begin
        $dumpfile("Parallelizer/parallelizer_tb.vcd");
        $dumpvars(0, Parallelizer_tb);
        $display("Starting parallelizer testbench");
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
        //simulate encrypters receiving key after parallelizer send it out
        for (i = 0; i < `NUM_ENCRYPTERS; i = i + 1) begin
            encrypters_ready[i] = 1;
            #1;
        end

        //start encrypting data. can only be started from idle state
        #4 qspi_sending = 1;
        for (i = `ENCRYPTER_QSPI_COUNT; i < 200; i = i + 1) begin
            qspi_data = spi_data_values[i];
            $display("Setting qspi_data to 0x%h", spi_data_values[i]);
            #2;
        end
        #2 qspi_sending = 0;
        #10
        $display("Ending parallelizer testbench");
        $finish;
    end

    always begin
        #1 clk = ~clk;
        //update slice of encrypters data to be seen on gktwave
        // encrypters_data_slice[`ENCRYPTER_WIDTH-1:0] = encrypters_data[0][`ENCRYPTER_WIDTH-1:0];
        if (clk)
            for (j = 0; j < `NUM_ENCRYPTERS-1; j = j + 1) begin
                if (encrypters_ready[j] && encrypters_data_ready[j]) begin
                    encrypters_ready[j] = 0;
                end
                if (encrypters_data_ready[j]) encrypters_delays[j] = 4;
                if (encrypters_delays[j]) begin
                    if (encrypters_delays[j] == 1) encrypters_ready[j] = 1;
                    encrypters_delays[j] = encrypters_delays[j] - 1;
                end
            end
    end

endmodule