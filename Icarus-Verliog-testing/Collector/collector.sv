`include "./Constants/constants.vh"
`define IDLE 2'b00
`define WAITING 2'b01
`define SENDING 2'b10


module Collector(
    input wire clk,
    input wire reset,
    //QSPI
    
    output reg [3:0] qspi_data,
    output reg qspi_sending = 0,
    input wire qspi_ready,
    
    //To encrypters
    input wire [`ENCRYPTER_WIDTH-1:0] encrypters_data,
    input wire [`NUM_ENCRYPTERS-1:0] encrypters_data_ready,
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_capture

    //Watchers
    // output reg [1:0] state_out,
    // output reg [`ENCRYPTER_WIDTH-1:0] encrypter_data_packe_out,
    
    // output reg [`ENCRYPTER_WIDTH_COUNT_REG-1:0] encrypter_data_subindex_out,
    // output reg [`NUM_ENCRYPTERS_REG-1:0] encrypter_index_out,
    // output reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index_out    
); // 4-bit collector

    reg [1:0] state = `IDLE;

    reg [`ENCRYPTER_WIDTH-1:0] encrypter_data_packet;
    reg [`ENCRYPTER_WIDTH_COUNT_REG-1:0] encrypter_data_subindex;

    reg [`NUM_ENCRYPTERS_REG-1:0] encrypter_index;

    reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index;

    
    // assign state_out = state;
    // assign encrypter_data_packe_out = encrypter_data_packet;
    // assign encrypter_data_subindex_out = encrypter_data_subindex;
    // assign encrypter_index_out = encrypter_index;
    // assign encrypter_data_index_out = encrypter_data_index;


    

    always @(posedge reset) begin
        state <= `WAITING;
        encrypter_index <= 0;
    end  


    always @(posedge clk) begin
        if (state == `WAITING) begin
            if(encrypters_data_ready[encrypter_index]) begin
                encrypter_data_packet = encrypters_data;
                // for (encrypter_data_subindex = 0; encrypter_data_subindex < `ENCRYPTER_WIDTH; encrypter_data_subindex = encrypter_data_subindex + 1) begin
                //     encrypter_data_packet[encrypter_data_subindex] = encrypters_data[encrypter_index][encrypter_data_subindex];
                // end
                state <= `SENDING;
                encrypter_data_index = 0;
            end
        end
    end 

    always @(negedge clk) begin 
        if (encrypters_capture[encrypter_index]) encrypters_capture[encrypter_index] <= 0;

        if (state == `SENDING) begin  encrypters_capture[encrypter_index] <= 1;  
            if (encrypter_data_index == 0) encrypters_capture[encrypter_index] <= 1;  
                if(qspi_ready) begin
                    qspi_sending = 1;
                    qspi_data[0] = encrypter_data_packet[encrypter_data_index*4];
                    qspi_data[1] = encrypter_data_packet[encrypter_data_index*4+1]; 
                    qspi_data[2] = encrypter_data_packet[encrypter_data_index*4+2];
                    qspi_data[3] = encrypter_data_packet[encrypter_data_index*4+3];  
                    encrypter_data_index = encrypter_data_index + 1;   
                    if(encrypter_data_index == `ENCRYPTER_QSPI_COUNT) begin
                        qspi_sending = 0;
                            encrypter_index = encrypter_index + 1;
                            if (encrypter_index == `NUM_ENCRYPTERS) begin
                                encrypter_index = 0;
                            end
                        state <= `WAITING; 
                    end           
                end
            else qspi_sending = 0;   
        end     
    end 


endmodule



