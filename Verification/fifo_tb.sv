
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

// Reset Sequence
initial begin
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;
end

// Stimulus
initial begin

    // Wait until reset is completed
    wait (rst == 0);


    // Write operation, test 1
    @(negedge clk);
    din = 25;
    wr_en = 1;
    @(negedge clk);
    wr_en = 0;

    
    // Read operation
    @(negedge clk);
    rd_en = 1;
    @(negedge clk);
    rd_en = 0;


     // Check output test 1
    @(negedge clk);
    if (dout == 25)
        $display("TEST PASSED: dout = %0d", dout);
    else
        $display("TEST FAILED: dout = %0d", dout);



    //16 Writes operation filling the FIFO, test 2
    din = 0;
    repeat (FIFO_DEPTH) begin
        @(negedge clk);
        din += 1;
        wr_en = 1;
        @(negedge clk);
        wr_en = 0;
    end

    //check output test 2
    @(negedge clk);
    if (full)
        $display("TEST PASSED: FIFO is full");
    else
        $display("TEST FAILED: FIFO is not full");
    
    //checking enable writing when full, test 3
    @(negedge clk);
    din = 100;
    wr_en = 1;
    rd_en = 0;
    @(negedge clk);
    if (full && !empty)
        $display("TEST PASSED: Over flow protection");
    else
        $display("TEST FAILED: Over flow protection");
    $finish;

end

endmodule
