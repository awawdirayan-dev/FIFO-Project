
module fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;

    // Testbench signals
    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;

    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;

    logic full;
    logic empty;


    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // DUT instantiation
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

endmodule
