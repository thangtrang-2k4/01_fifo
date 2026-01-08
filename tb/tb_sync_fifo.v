`timescale 1ns/1ps
module tb_sync_fifo;

    parameter integer DATA_WIDTH = 8;
    parameter integer DEPTH      = 8;
    parameter         AF_LEVEL   = 1;
    parameter         AE_LEVEL   = 1;

    // input
    reg                        clk;
    reg                        sclr_n;
    reg                        aclr_n;
    reg  [DATA_WIDTH-1:0]      din;
    reg                        wr_en;
    reg                        rd_en;
    
    // out put
    wire [DATA_WIDTH-1:0]      dout;
    wire                       full;
    wire                       almost_full;
    wire                       empty;
    wire                       almost_empty;
    wire                       overflow;
    wire [$clog2(DEPTH+1)-1:0] usedw;

    // Reference module
    reg  [DATA_WIDTH-1:0] ref_fifo [0:DEPTH-1];

    sync_fifo  #(
       .DATA_WIDTH (DATA_WIDTH),
       .DEPTH      (DEPTH),
       .AF_LEVEL   (AF_LEVEL),
       .AE_LEVEL   (AE_LEVEL)
    ) dut (
       // input
       .clk         (clk),
       .sclr_n      (sclr_n),
       .aclr_n      (aclr_n),
       .din         (din),
       .wr_en       (wr_en),
       .rd_en       (rd_en),
       
       // output
       .dout        (dout),
       .full        (full),
       .almost_full (almost_full),
       .empty       (empty),
       .almost_empty(almost_empty),
       .overflow    (overflow),
       .usedw       (usedw)
    );

    // Clock Generator
    initial clk = 0;
    always #5 clk = ~clk;

    // Initial value
    initial begin 
        
        sclr_n = 1;
        aclr_n = 1;
        din    = 0;
        wr_en  = 0;
        rd_en  = 0;

    end

    initial begin 
        async_reset_test();
        sync_reset_test();
        write_test();
        read_test();
        full_flag_test();
        empty_flag_test();
        almost_full_flag_test();
        almost_empty_flag_test();
        rd_wr_comb_test();
        overflow_test();
        wrap_around_test ();
        #100;
        $finish;
    end
    // =====================================================
    // RESET TESTS
    // =====================================================
    // =========================
    // ASYNC RESET TEST
    // =========================
    task async_reset_test;
        begin
            $display("=== ASYNC RESET TEST ===");

            // Assert async reset
            aclr_n = 0;
            sclr_n = 1;
            #10;

            // WHEN async reset asserted
            check_reset_values("when async reset is asserted");

            // Release async reset
            aclr_n = 1;
            #10;

            // AFTER async reset released
            check_reset_values("after async reset release");

            $display("=== ASYNC RESET TEST DONE ===");
        end
    endtask

    // =========================
    // SYNC RESET TEST
    // =========================
    task sync_reset_test;
        begin
            $display("=== SYNC RESET TEST ===");

            // Assert sync reset
            aclr_n = 1;
            sclr_n = 0;
            @(posedge clk);
            #1;

            // WHEN sync reset asserted
            check_reset_values("when sync reset is asserted");

            // Release sync reset
            sclr_n = 1;
            @(posedge clk);
            #1;
            // AFTER sync reset released
            check_reset_values("after sync reset release");

            $display("=== SYNC RESET TEST DONE ===");
        end
    endtask

    // =========================
    // COMMON RESET CHECKER
    // =========================
    task check_reset_values(input [8*40:1] phase);
        begin
            if (empty !== 1'b1)
                $display("ERROR: empty should be 1 %s", phase);
            else
                $display("PASS : empty = 1 %s", phase);

            if (full !== 1'b0)
                $display("ERROR: full should be 0 %s", phase);
            else
                $display("PASS : full = 0 %s", phase);

            if (almost_empty !== 1'b1)
                $display("ERROR: almost_empty should be 1 %s", phase);
            else
                $display("PASS : almost_empty = 1 %s", phase);

            if (almost_full !== 1'b0)
                $display("ERROR: almost_full should be 0 %s", phase);
            else
                $display("PASS : almost_full = 0 %s", phase);

            if (usedw !== 0)
                $display("ERROR: usedw should be 0 %s", phase);
            else
                $display("PASS : usedw = 0 %s", phase);

            if (overflow !== 1'b0)
                $display("ERROR: overflow should be 0 %s", phase);
            else
                $display("PASS : overflow = 0 %s", phase);
        end
    endtask

    // =====================================================
    // BASIC READ / WRITE TESTS
    // =====================================================
    // =========================
    // WRITE TEST
    // =========================
    task write_test;
        integer i;
        reg [DATA_WIDTH-1:0] data;
        begin
            $display("=== WRITE TEST ===");

            for (i=0; i<DEPTH; i=i+1) begin
                @(posedge clk);
                data = $random;
                din = data;
                wr_en = 1;
                @(posedge clk);
                $display("[WRITE] Write %0h to FIFO", data);
                $display("[WRITE] Write %0h to reference FIFO", data);
                ref_fifo[i] = data;
                wr_en = 0;
            end

            $display("=== WRITE TEST DONE ===");
        end
    endtask

    // =========================
    // READ TEST
    // =========================
    task read_test;
        integer i;
        reg [DATA_WIDTH-1:0] data;
        begin
            $display("=== READ TEST ===");

            for (i=0; i<DEPTH; i=i+1) begin
                @(posedge clk);
                rd_en = 1;
                @(posedge clk);
                rd_en = 0;
                #1;
                data = dout;
                $display("[READ] Read %0h from FIFO", data);
                if(data == ref_fifo[i])
                    $display("[COMPARE] Data matching at FIFO: %0h, ref FIFO: %0h", data, ref_fifo[i]);
                else
                    $display("[COMPARE] Data not matching at FIFO: %0h, ref FIFO: %0h", data, ref_fifo[i]);
            end

            $display("=== READ TEST DONE ===");
        end
    endtask
    
    // =====================================================
    // PRIMITIVE STIMULUS TASKS
    // (single write / single read)
    // =====================================================
    task write_one(input [DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);
            din   = data;
            wr_en = 1;
            @(posedge clk);
            wr_en = 0;
            $display("[WRITE] Write %0h to FIFO", data);
       end
    endtask

    task read_one(output [DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);   // wait dout valid
            rd_en = 1;
            @(posedge clk);
            rd_en = 0;
            #1;
            data = dout;
            $display("[READ] Read %0h from FIFO", data);
        end
    endtask

    task sync_reset();
        
        begin
            $display("[SYNCHONOUS RESET]");
            @(posedge clk);
            sclr_n = 0;
            @(posedge clk);
            sclr_n = 1;
        end
    endtask

    // =====================================================
    // SCENARIO STIMULUS TASKS
    // (drive FIFO to specific states)
    // =====================================================
    task write_until_full;
        reg [DATA_WIDTH-1:0] data;
        reg [3:0] i;
        begin
            //for ( i=0; i<8; i=i+1) begin 
            //    data = $random;
            //    write_one(data);
            //end
            while (!full) begin
                data = $random;
                write_one(data);
                #1;
            end
        end
    endtask

    task read_until_empty;
        reg [DATA_WIDTH-1:0] data;
        begin
            while (!empty) begin
                read_one(data);
            end
        end
    endtask

    task write_until_almost_full;
        reg [DATA_WIDTH-1:0] data;
        begin
            while (usedw < (DEPTH - AF_LEVEL)) begin
                data = $random;
                write_one(data);
                #1;
            end
        end
    endtask

    task read_until_almost_empty;
        reg [DATA_WIDTH-1:0] data;
        begin
            while (usedw > AE_LEVEL) begin
                read_one(data);
            end
        end
    endtask

    // =====================================================
    // FLAG CHECKER TASKS
    // =====================================================

    task check_full;
        begin
            if (full !== 1'b1)
                $display("ERROR: full should be 1 when FIFO is full");
            else
                $display("PASS : full flag asserted");
    
            if (usedw !== DEPTH)
                $display("ERROR: usedw should be DEPTH (%0d), got %0d", DEPTH, usedw);
            else
                $display("PASS : usedw = DEPTH");
        end
    endtask

    task check_empty;
        begin
            if (empty !== 1'b1)
                $display("ERROR: empty should be 1 when FIFO is empty");
            else
                $display("PASS : empty flag asserted");
    
            if (usedw !== 0)
                $display("ERROR: usedw should be 0 when FIFO is empty");
            else
                $display("PASS : usedw = 0");
        end
    endtask

    task check_almost_full;
        begin
            if (almost_full !== 1'b1)
                $display("ERROR: almost_full should be 1 at AF threshold");
            else
                $display("PASS : almost_full asserted");
    
            if (full !== 1'b0)
                $display("ERROR: full should be 0 at almost_full");
            else
                $display("PASS : full = 0");
    
            if (usedw !== (DEPTH - AF_LEVEL))
                $display("ERROR: usedw should be %0d, got %0d",
                         DEPTH-AF_LEVEL, usedw);
            else
                $display("PASS : usedw reached AF threshold");
        end
    endtask

    task check_almost_empty;
        begin
            if (almost_empty !== 1'b1)
                $display("ERROR: almost_empty should be 1 at AE threshold");
            else
                $display("PASS : almost_empty asserted");
    
            if (empty !== 1'b0)
                $display("ERROR: empty should be 0 at almost_empty");
            else
                $display("PASS : empty = 0");
    
            if (usedw !== AE_LEVEL)
                $display("ERROR: usedw should be %0d, got %0d",
                         AE_LEVEL, usedw);
            else
                $display("PASS : usedw reached AE threshold");
        end
    endtask

    // =====================================================
    // STATUS FLAG TEST CASES
    // (mapping 1–1 with test plan)
    // =====================================================

    // =========================
    // FULL FLAG TEST
    // =========================
    task full_flag_test;
        begin
            $display("=== FULL FLAG TEST ===");
    
            sync_reset();     // ensure clean state
            write_until_full();    // stimulus
            check_full();          // checker
    
            $display("=== FULL FLAG TEST DONE ===");
        end
    endtask

    // =========================
    // EMPTY FLAG TEST
    // =========================
    task empty_flag_test;
        begin
            $display("=== EMPTY FLAG TEST ===");
    
            read_until_empty();
            check_empty();
    
            $display("=== EMPTY FLAG TEST DONE ===");
        end
    endtask

    // =========================
    // ALMOST FULL FLAG TEST
    // =========================
    task almost_full_flag_test;
        begin
            $display("=== ALMOST FULL FLAG TEST ===");
    
            sync_reset();         // clean state
            write_until_almost_full();     // stimulus
            //#3;
            check_almost_full();       // checker
    
            $display("=== ALMOST FULL FLAG TEST DONE ===");
        end
    endtask

    // =========================
    // ALMOST EMPTY FLAG TEST
    // =========================
    task almost_empty_flag_test;
        begin
            $display("=== ALMOST EMPTY FLAG TEST ===");
            sync_reset();
            write_until_full();        // cần có data trước
            read_until_almost_empty();
            //#3;
            check_almost_empty();
    
            $display("=== ALMOST EMPTY FLAG TEST DONE ===");
        end
    endtask

    // =====================================================
    // RW_COMBINATION
    // =====================================================

    task rd_wr_comb_test;
        
        reg [$clog2(DEPTH+1)-1:0] usedw_pre;
        integer i;
        reg [DATA_WIDTH-1:0] data;

        begin
        
            $display("=== READ WRITE COMBINATION TEST ===");
            sync_reset();
            write_one(8'h98);
            ref_fifo[0] = 8'h89;
            
            for(i=0; i<DEPTH-1; i=i+1) begin
                #1;
                usedw_pre = usedw;
                @(posedge clk);
                data = $random;
                wr_en = 1;
                rd_en = 1;
                din = data;
                ref_fifo[i+1] = data;
                @(posedge clk);
                wr_en = 0;
                rd_en = 0;
                #1;
                if(dout == ref_fifo[i]) 
    
                    $display("PASS: data matching");
                else 
                    $display("ERROR: data not match at dout: %0h, expected: %0h", dout, ref_fifo[i]);

                if(usedw == usedw_pre)
                    $display("PASS usedw unchanged");
                else
                    $display("ERORR usedw changed");

            end
            $display("=== READ WRITE COMBINATION TEST DONE ===");
        end
    endtask

    // =====================================================
    // OVERFLOW 
    // =====================================================
    task overflow_test();
        begin
            $display("=== OVERFLOW TEST ===");
            sync_reset();
            write_until_full();
            @(posedge clk);
            wr_en = '1;
            din = 0'h56;
            @(posedge clk);
            wr_en = 0;
            #1;
            if(overflow == 1)
                $display("PASS: Overfolow is assserted");
            else 
                $display("ERROR: Overfolow is not assserted");
            $display("=== OVERFLOW TEST DONE ===");
        end
    endtask

    // =====================================================
    // WRAP AROUND
    // =====================================================
    task wrap_around_test;
        integer i;
        reg [DATA_WIDTH-1:0] data;
        begin
            $display("=== WRAP AROUND TEST ===");
            sync_reset();
    
            for (i = 0; i < 2*DEPTH; i = i + 1) begin
                write_one(i);
                read_one(data);
                if (data !== i[DATA_WIDTH-1:0])
                    $display("ERROR: wrap fail @i=%0d exp=%0h got=%0h", i, i[DATA_WIDTH-1:0], data);
            end
    
            $display("=== WRAP AROUND TEST DONE ===");
        end
    endtask
endmodule
