module sync_fifo #(
   parameter int DATA_WIDTH = 8,
   parameter int DEPTH      = 8
)(
   // input
   input  logic                      clk,
   input  logic                      sclr_n,
   input  logic                      aclr_n,
   input  logic [DATA_WIDTH-1:0]     din,
   input  logic                      wr_en,
   input  logic                      rd_en,

   // output
   output logic [DATA_WIDTH-1:0]     dout,
   output logic                      full,
   output logic                      almost_full,
   output logic                      empty,
   output logic                      almost_empty,
   output logic                      overflow,
   output logic [$clog2(DEPTH+1)-1:0] usedw,
);

   // Register File
   logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];
   
   // Control
   logic                       wr_allow;
   logic                       rd_allow;

   logic [$clog2(DEPTH)-1:0]   wr_ptr;
   logic [$clog2(DEPTH)-1:0]   wr_ptr_next;
   logic [$clog2(DEPTH)-1:0]   rd_ptr;
   logic [$clog2(DEPTH)-1:0]   rd_ptr_next;

   logic                       full_next;
   logic                       almost_full_next;
   logic                       empty_next;
   logic                       almost_empty_next;
   logic                       overflow_next;
   logic [$clog2(DEPTH+1)-1:0] usedw_next;

   // FIFO control
   always_comb begin
       wr_allow   = wr_en && !full;
       rd_allow   = rd_en && !empty;
   
       wr_ptr_next = wr_ptr;
       rd_ptr_next = rd_ptr;
       usedw_next  = usedw;
       overflow_next = overflow;
   
       unique case ({wr_allow, rd_allow})
           2'b01: begin
               rd_ptr_next = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
               usedw_next  = usedw - 1;
           end
           2'b10: begin
               wr_ptr_next = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
               usedw_next  = usedw + 1;
           end
           2'b11: begin
               wr_ptr_next = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
               rd_ptr_next = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
               // usedw_next giữ nguyên
           end
           default: ; // 2'b00 không làm gì
       endcase
   
       if (wr_en && full && !rd_en)
           overflow_next = 1'b1;
   
       full_next         = (usedw_next == DEPTH);
       almost_full_next  = (usedw_next >= DEPTH-2);
       empty_next        = (usedw_next == 0);
       almost_empty_next = (usedw_next <= 2);
   end

   always_ff @(posedge clk or negedge aclr_n) begin

      if(!aclr_n) begin 
         wr_ptr       <= '0;
         rd_ptr       <= '0;
         full         <= 1'b0;
         almost_full  <= 1'b0;
         empty        <= 1'b1;
         almost_empty <= 1'b1;
         overflow     <= 1'b0;
         usedw        <= '0;
      end
      else if (!sclr_n) begin 
         wr_ptr       <= '0;
         rd_ptr       <= '0;
         full         <= 1'b0;
         almost_full  <= 1'b0;
         empty        <= 1'b1;
         almost_empty <= 1'b1;
         overflow     <= 1'b0;
         usedw        <= '0;
      end
      else begin 
         wr_ptr       <= wr_ptr_next;
         rd_ptr       <= rd_ptr_next;
         full         <= full_next;
         almost_full  <= almost_full_next;
         empty        <= empty_next; 
         almost_empty <= almost_empty_next;
         overflow     <= overflow_next;
         usedw        <= usedw_next;    
      end
   end

   // FIFO Register
   always_ff @(posedge clk or negedge aclr_n) begin
      if(!aclr_n) dout <= '0;
      else if (!sclr_n) dout <= '0;
      else begin 
         if(wr_allow) mem[wr_ptr] <= din;
         else mem[wr_ptr] <= mem[wr_ptr];

         if(rd_allow) dout <= mem[rd_ptr];
         else dout <= dout;
      end
   end
endmodule
