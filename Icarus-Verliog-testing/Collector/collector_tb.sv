`timescale 1ns / 1ns
`include "./Constants/constants.vh"
`include "./Collector/collector.sv"


module Collector_tb;

  reg clk=1'b0;
  reg reset;

  // QSPI signals
  wire [3:0] qspi_data;
  wire qspi_sending;
  reg qspi_ready;

  // Encrypters signals
  reg [`ENCRYPTER_WIDTH-1:0] encrypters_data [0:`NUM_ENCRYPTERS-1];
  reg [`NUM_ENCRYPTERS-1:0] encrypters_data_ready;
  wire [`NUM_ENCRYPTERS-1:0] encrypters_capture;

  // Watchers signals
  wire [1:0] state_out;
  wire [`ENCRYPTER_WIDTH-1:0] encrypter_data_packe_out;
  // wire [`ENCRYPTER_WIDTH_COUNT_REG-1:0] encrypter_data_subindex;
  // wire [`NUM_ENCRYPTERS_REG-1:0] encrypter_index;
  // wire [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index;
  
  // DUT (Device Under Test)
  Collector uut (
    .clk(clk),
    .reset(reset),
    .qspi_data(qspi_data),
    .qspi_sending(qspi_sending),
    .qspi_ready(qspi_ready),
    .encrypters_data(encrypters_data),
    .encrypters_data_ready(encrypters_data_ready),
    .encrypters_capture(encrypters_capture),
    .state_out(state_out),
    .encrypter_data_packe_out(encrypter_data_packe_out),
    .encrypter_data_subindex_out(encrypter_data_subindex_out),
    .encrypter_index_out(encrypter_index_out),
    .encrypter_data_index_out(encrypter_data_index_out)
  );

  // Clock generation
  always begin
    #5 clk = ~clk;
  end

    // Reset generation
    initial begin
      $display("Start test");

      $dumpfile("wave.vcd");
      $dumpvars(0, Collector_tb);

      // initializing to zero 
      reset = 1'b0;
      qspi_ready = 1'b1;
      encrypters_data_ready = 0;

      #10
      
      // checking reset
      reset = 1'b1;
      #20
      

      // checking if the data is ready
      encrypters_data[0] = 32'h12345678;
      encrypters_data_ready[0] = 1'b1;
      
      #100; // Add a delay here
      encrypters_data_ready[0] = 1'b0;
      encrypters_data[1] = 32'h123458;
      encrypters_data_ready[1] = 1'b1;

      #1000
      $finish; 
    end

endmodule