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
    wire [`ENCRYPTER_WIDTH-1:0] encrypters_data_ec;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_data_ready_ec;
    wire [`NUM_ENCRYPTERS-1:0] encrypters_capture_ec;

    // Collector <-> Toplevel signals
    wire [3:0] qspi_data_ct;
    wire qspi_sending_ct;
    reg qspi_ready_ct = 0;

    // Watchers
    wire [2:0] state_out_p;
    wire [`KEY_WIDTH-1:0] key_out;

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
        .state_out(state_out_p),
        .key_out(key_out)
    );

    // Encrypter e_inst0(
    //     .clk(clk),
    //     .reset(reset),
    //     .dataIn(encrypters_data_pe[0]),
    //     .rot_offset(encrypters_key_rotation_pe[0]),
    //     .dataRdyIn(encrypters_ready_pe[0]),
    //     .cap(encrypters_capture_ec[0]),
    // );

    reg [3:0] spi_data_values[255:0];
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
        $dumpfile("TopLevel/top_level.vcd");
        $dumpvars(0, TopLevel);
        $display("Starting simulation");

        //set data on neg edge, read on the rising
        #2 reset = 1; #2 reset = 0;
        #2 prog_tp = 1; #2 prog_tp = 0;

        while (!qspi_ready_tp);

        #2 qspi_sending_tp = 1;
        for (i = 0; i < `KEY_QSPI_COUNT; i = i + 1) begin
            qspi_data_tp = spi_data_values[i];
            $display("Setting qspi_data to 0x%h", spi_data_values[i]);
            #2;
        end
        qspi_sending_tp = 0;

        #4 $finish;
    end

    always begin
        #1 clk = ~clk;
    end

endmodule
