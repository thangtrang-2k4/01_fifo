`timescale 1ns/1ps

module tb_sync_fifo;

   // =====================================================
   // Parameters
   // =====================================================
   localparam DATA_WIDTH = 8;
   localparam DEPTH      = 8;

   // =====================================================
   // DUT signals
   // =====================================================
   reg                       clk;
   reg                       aclr_n;
   reg                       sclr_n;
   reg  [DATA_WIDTH-1:0]     din;
   reg                       wr_en;
   reg                       rd_en;

   wire [DATA_WIDTH-1:0]     dout;
   wire                      full;
   wire                      almost_full;
   wire                      empty;
   wire                      almost_empty;
   wire                      overflow;
   wire [$clog2(DEPTH+1)-1:0] usedw;

   // =====================================================
   // Instantiate DUT
   // =====================================================
   sync_fifo #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(DEPTH)
   ) dut (
      .clk(clk),
      .aclr_n(aclr_n),
      .sclr_n(sclr_n),
      .din(din),
      .wr_en(wr_en),
      .rd_en(rd_en),
      .dout(dout),
      .full(full),
      .almost_full(almost_full),
      .empty(empty),
      .almost_empty(almost_empty),
      .overflow(overflow),
      .usedw(usedw)
   );

   // =====================================================
   // Clock generator (100 MHz)
   // =====================================================
   initial clk = 0;
   always #5 clk = ~clk;

   // =====================================================
   // Reset task
   // =====================================================
   task reset_fifo;
   begin
      $display("\n--- RESET FIFO ---");
      aclr_n = 0;
      sclr_n = 1;
      wr_en  = 0;
      rd_en  = 0;
      din    = 0;
      #20;

      aclr_n = 1;
      #20;

      if (empty !== 1'b1)
         $display("❌ ERROR: FIFO not empty after reset");
      else
         $display("✅ Reset OK");
   end
   endtask

   // =====================================================
   // FIFO write task
   // =====================================================
   task fifo_write(input [DATA_WIDTH-1:0] data);
   begin
      @(negedge clk);
      if (!full) begin
         din   = data;
         wr_en = 1;
      end
      @(negedge clk);
      wr_en = 0;
   end
   endtask

   // =====================================================
   // FIFO read task
   // =====================================================
   task fifo_read(output [DATA_WIDTH-1:0] data);
   begin
      @(negedge clk);
      if (!empty)
         rd_en = 1;

      @(negedge clk);
      rd_en = 0;

      @(posedge clk);
      data = dout;
   end
   endtask

   // =====================================================
   // Test sequence
   // =====================================================
   integer i;
   reg [DATA_WIDTH-1:0] rdata;

   initial begin
      // -------------------------------
      // Init
      // -------------------------------
      aclr_n = 1;
      sclr_n = 1;
      wr_en  = 0;
      rd_en  = 0;
      din    = 0;

      // -------------------------------
      // Test 1: Reset
      // -------------------------------
      reset_fifo;

      // -------------------------------
      // Test 2: Write FIFO
      // -------------------------------
      $display("\n--- WRITE TEST ---");
      for (i = 0; i < 4; i = i + 1) begin
         fifo_write(8'h10 + i);
         $display("WRITE: %h  usedw=%0d", 8'h10+i, usedw);
      end

      if (usedw !== 4)
         $display("❌ ERROR: usedw wrong after write");
      else
         $display("✅ Write OK");

      // -------------------------------
      // Test 3: Read FIFO
      // -------------------------------
      $display("\n--- READ TEST ---");
      for (i = 0; i < 4; i = i + 1) begin
         fifo_read(rdata);
         $display("READ : %h", rdata);
      end

      if (!empty)
         $display("❌ ERROR: FIFO not empty after read");
      else
         $display("✅ Read OK");

      // -------------------------------
      // Test 4: Read & Write same cycle
      // -------------------------------
      $display("\n--- READ & WRITE SAME CYCLE TEST ---");

      fifo_write(8'hAA);

      @(negedge clk);
      din   = 8'hBB;
      wr_en = 1;
      rd_en = 1;

      @(negedge clk);
      wr_en = 0;
      rd_en = 0;

      @(posedge clk);
      $display("RW SAME CYCLE: dout = %h (expect AA)", dout);

      if (dout !== 8'hAA)
         $display("❌ ERROR: Read-before-write violated");
      else
         $display("✅ Read-before-write OK");

      // -------------------------------
      // Finish
      // -------------------------------
      #20;
      $display("\n🎉 ALL TESTS DONE 🎉");
      $finish;
   end

endmodule
