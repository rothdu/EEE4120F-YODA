`timescale 10ns / 10ns
`include "./Constants/constants.vh"
`include "./Parallelizer/parallelizer.sv"
`include "./Encrypter/encrypter.sv"
`include "./Collector/collector.sv"

`define ENCRYPT 0
`define MAX_BYTES 4*1


module TopLevel();

    // Toplevel signals
    reg clk = 0;
    reg reset = 0;

    // Toplevel <-> Parallelizer signals
    reg [3:0] qspi_data_tp = 0;
    reg qspi_sending_tp = 0;
    wire qspi_ready_tp;
    reg prog_tp = 0;

    // Parallelizer <-> Encrypter signals
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_pe;
    wire [`KEY_ROTATION_WIDTH-1:0] encrypters_key_rotation_pe;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_program_pe;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_data_ready_pe;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_ready_pe;

    // Encrypter <-> Collector signals
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_ec [`NUM_ENCRYPTERS-1:0];
    wire [`NUM_ENCRYPTERS-1:0] encrypters_data_ready_ec;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_capture_ec;

    // Collector <-> Toplevel signals
    wire [3:0] qspi_data_ct;
    wire qspi_sending_ct;
    reg qspi_ready_ct = 1;

    // Watchers
    // wire [2:0] state_out_p;
    wire [`ENCRYPTER_WIDTH-1:0] key_out;
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_ec0;
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_ec1;

    assign encrypters_data_ec0 = encrypters_data_ec[0];
    assign encrypters_data_ec1 = encrypters_data_ec[1];

    Parallelizer p_inst(
        .clk(clk),
        .reset(reset),
        .qspi_data(qspi_data_tp),
        .qspi_sending(qspi_sending_tp),
        .qspi_ready(qspi_ready_tp),
        .prog(prog_tp),
        .encrypters_data(encrypters_data_pe),
        .encrypters_key_rotation(encrypters_key_rotation_pe),
        .encrypters_program(encrypters_program_pe),
        .encrypters_data_ready(encrypters_data_ready_pe),
        .encrypters_ready(encrypters_ready_pe)
        // .state_out(state_out_p),
        // .key_out(key_out)
    );

    generate
        genvar e;
        for (e = 0; e < `NUM_ENCRYPTERS; e = e + 1) begin : encrypter_loop
            EncrypterADV e_inst (
                .clk(clk),
                .reset(reset),
                .data_in_p(encrypters_data_pe),
                .key_rotation_p(encrypters_key_rotation_pe),
                .prog_p(encrypters_program_pe[e]),
                .data_ready_in_p(encrypters_data_ready_pe[e]),
                .ready_p(encrypters_ready_pe[e]),
                .data_out_c(encrypters_data_ec[e]),
                .data_ready_out_c(encrypters_data_ready_ec[e]),
                .capture_c(encrypters_capture_ec[e])
            );
        end
    endgenerate

    Collector c_inst(
        .clk(clk),
        .reset(reset),
        .qspi_data(qspi_data_ct),
        .qspi_sending(qspi_sending_ct),
        .qspi_ready(qspi_ready_ct),
        .encrypters_data(encrypters_data_ec),
        .encrypters_data_ready(encrypters_data_ready_ec),
        .encrypters_capture(encrypters_capture_ec)
    );

    reg [31:0] key = 32'hB4352B93;
    integer fd_read, fd_write, fd_csv, i, j, bytes_sent = 0, packets;
    reg [7:0] char_read, char_write;
    logic char_write_progress = 0;

    initial begin
        fd_csv = $fopen("./TopLevel/encrypter_output.csv", "w");
        if (fd_csv == -1) begin
            $display("Error data file!");
            $finish;  // Exit simulation on error
        end
        $fwrite(fd_csv, "#Blocks,Test1\n");
    end

    initial begin
        $dumpfile("TopLevel/top_level.vcd");
        $dumpvars(0, TopLevel);

        for (packets = 2**15; packets <= 2**15; packets = packets * 2) begin
            $display("Starting simulation with %d packets", packets);

            //fill spi_data_values with data from file
            if (`ENCRYPT) begin
                fd_read = $fopen("../data/unencrypted/starwarsscript.txt", "r");
            end else begin
                fd_read = $fopen("../data/encrypted/starwarsscript_verilogADV.enc", "r");
            end

            if (fd_read == -1) begin
                $display("Error data file!");
                $finish;  // Exit simulation on error
            end

            if (`ENCRYPT) begin
                fd_write = $fopen("../data/encrypted/starwarsscript_verilogADV.enc", "w");
            end else begin
                fd_write = $fopen("../data/deencrypted/starwarsscript_verilogADV.txt", "w");
            end
            if (fd_write == -1) begin
                $display("Error encrypted data file!");
                $finish;  // Exit simulation on error
            end


            //set data on neg edge, read on the rising
            #2 reset = 1; #2 reset = 0;
            #2 prog_tp = 1; #2 prog_tp = 0;

            //send key
            while (!qspi_ready_tp) #2;
            #2 qspi_sending_tp = 1; #2
            for (i = `ENCRYPTER_QSPI_COUNT-1; i > -1; i = i - 1) begin
                qspi_data_tp[0] = key[i*4];
                qspi_data_tp[1] = key[i*4+1];
                qspi_data_tp[2] = key[i*4+2];
                qspi_data_tp[3] = key[i*4+3];
                #2;
                // $display("[KEY] 0x%x", qspi_data_tp);
            end
            qspi_sending_tp = 0;

            //send data
            bytes_sent = 0;
            while (!qspi_ready_tp) #2;
            #2 qspi_sending_tp = 1; #2
            while (!$feof(fd_read) && (bytes_sent < packets*4)) begin
                char_read = $fgetc(fd_read);
                // $display("[RAW] 0x%x", char_read);

                while (!qspi_ready_tp) #2;
                qspi_data_tp = char_read[7:4]; #2;
                // $display("[DAT] 0x%x", qspi_data_tp);

                while (!qspi_ready_tp) #2;
                qspi_data_tp = char_read[3:0]; #2;
                // $display("[DAT] 0x%x", qspi_data_tp);

                bytes_sent = bytes_sent + 1;
                // $display("Bytes sent: %d", bytes_sent);
            end
            #2 qspi_sending_tp = 0; #10;

            while (qspi_sending_ct) #2;
            $fclose(fd_read); $fclose(fd_write);
            $display("Simulation time: %.8f s", $time/(10.0**8));
            $fwrite(fd_csv, "%d,%.8f\n", packets, $time/(10.0**8));
        end
        $fclose(fd_csv); $finish;
    end

    always begin
        #1 clk = ~clk;
        if (clk) begin
            if (qspi_sending_ct) begin
                if (char_write_progress == 0) begin
                    char_write_progress = 1;
                    char_write[7:4] = qspi_data_ct;
                end else begin
                    char_write_progress = 0;
                    char_write[3:0] = qspi_data_ct;
                    // $display("[ENC] 0x%x", char_write);
                    j = $fputc(char_write, fd_write);
                end
            end
        end
    end

endmodule