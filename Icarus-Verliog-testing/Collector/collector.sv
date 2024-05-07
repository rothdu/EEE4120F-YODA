`include "./Constants/constants.vh"


`define WATING = 1'b1
`define SENDING = 1'b0


module Collector(
    input wire clk,
    input wire reset,
    //QSPI
    output reg [3:0] qspi_data,
    output reg qspi_sending,
    input wire qspi_ready,
    //To encrypters
    input wire [`ENCRYPTER_WIDTH-1:0] encrypters_data  [`NUM_ENCRYPTERS-1:0],
    input wire [`NUM_ENCRYPTERS-1:0] encrypters_data_ready,
    output reg [`NUM_ENCRYPTERS-1:0] encrypters_capture,
    //Watchers
    
); // 4-bit collector

    reg state;

    reg [`ENCRYPTER_WIDTH-1:0] encrypter_data_packet;
    reg [`ENCRYPTER_WIDTH_COUNT_REG-1:0] encrypter_data_subindex;

    reg [`NUM_ENCRYPTERS_REG-1:0] encrypter_index;

    reg [`ENCRYPTER_QSPI_COUNT_REG-1:0] encrypter_data_index;
    

    always @(posedge reset) begin
        state <= `WAITING;
        encrypter_index <= 0;
    end  
    
    integer i= 0;

    always @(posedge clk) begin
        if (state == `WAITING) begin
            if(encrypters_data_ready[encrypter_index]) begin
                    for (encrypter_data_subindex = 0; encrypter_data_subindex < `ENCRYPTER_WIDTH; encrypter_data_subindex = encrypter_data_subindex + 1) begin
                        encrypter_data_packet[encrypter_data_subindex]=encrypters_data[encrypter_index][encrypter_data_subindex];
                    end
                    state <= `SENDING;
                end
        end
    end 

    always @(negedge clk) begin 
        if (encrypters_capture[encrypter_index]) encrypters_capture[encrypter_index] <= 0;

        if (state == `SENDING) begin  encrypters_capture[encrypter_index] <= 1;  
            if (~encrypter_data_index) encrypters_capture[encrypter_index] <= 1;  
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
            else qspi_sending = 0   

        end     
    end 


endmodule



