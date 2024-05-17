`timescale 10ns/10ns
`include "./Constants/constants.vh"
`include "./Parallelizer/parallelizer.sv"
`include "./Encrypter/encrypter.sv"
`include "./Collector/collector.sv"

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
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_ec1;
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_ec2;

    assign encrypters_data_ec1 = encrypters_data_ec[0];
    assign encrypters_data_ec2 = encrypters_data_ec[1];

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
        .encrypters_ready(encrypters_ready_pe),
        // .state_out(state_out_p),
        .key_out(key_out)
    );

    genvar e;
    generate
        for (e = 0; e < `NUM_ENCRYPTERS; e = e + 1) begin : encrypter_loop
            Encrypter e_inst (
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

    reg [3:0] spi_data_values[255:0];
    reg [3:0] encrypters_delays [`NUM_ENCRYPTERS-1:0];
    integer fd, i, j;

    initial begin
        //fill spi_data_values with data from file
        fd = $fopen("./Constants/qspi_data.csv", "r");
        if (fd == -1) begin
            $display("Error data file!");
            $finish;  // Exit simulation on error
        end
        for (i = 0; i < 256; i++) begin
            j = $fscanf(fd, "%h", spi_data_values[i]);
        end
        $fclose(fd);

        fd = $fopen("./TopLevel/encrypted_qspi_data.csv", "w");
        if (fd == -1) begin
            $display("Error encrypted data file!");
            $finish;  // Exit simulation on error
        end

        for (j = 0; j < `NUM_ENCRYPTERS-1; j = j + 1) begin
            encrypters_delays[j] = 0;
        end
    end

    initial begin
        $dumpfile("TopLevel/top_level.vcd");
        $dumpvars(0, TopLevel);
        $display("Starting simulation");

        //set data on neg edge, read on the rising
        #2 reset = 1; #2 reset = 0;
        #2 prog_tp = 1; #2 prog_tp = 0;

        //send key
        while (!qspi_ready_tp) #2;
        #2 qspi_sending_tp = 1; #2
        for (i = 0; i < `ENCRYPTER_QSPI_COUNT; i = i + 1) begin
            qspi_data_tp = spi_data_values[i];
            $display("[KEY] qspi_data_tp <= 0x%h", spi_data_values[i]);
            #2;
        end
        qspi_sending_tp = 0;

        //send data
        while (!qspi_ready_tp) #2;
        #2 qspi_sending_tp = 1; #2
        for (i = `ENCRYPTER_QSPI_COUNT; i < 256; i = i + 1) begin
            if (!qspi_ready_tp) begin
                i = i - 1;
                #2;
            end else begin
                qspi_data_tp = spi_data_values[i];
                $display("[DATA] qspi_data_tp <= 0x%h", spi_data_values[i]);
                #2;
            end
        end
        #2 qspi_sending_tp = 0;

        #4 $fclose(fd); $finish;
    end

    always begin
        #1 clk = ~clk;
        if (clk) begin
            if (qspi_sending_ct) begin
                $fwrite(fd, "0x%x\n", qspi_data_ct);
                $display("[COL] qspi_data_ct >= 0x%h", qspi_data_ct);
            end
        end
    end

endmodule
