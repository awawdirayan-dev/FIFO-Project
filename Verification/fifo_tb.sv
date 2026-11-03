
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

    wait (rst == 0);
    @(negedge clk);
    din = 25;
    wr_en = 1;
    @(negedge clk);
    wr_en = 0;
    @(negedge clk);
    rd_en = 1;
    @(negedge clk);
    rd_en = 0;
    @(negedge clk);
    if (dout == 25)
        $display("TEST PASSED: dout = %0d", dout);
    else
        $display("TEST FAILED: dout = %0d", dout);

    @(negedge clk);
    rst = 1;
    repeat (2) @(negedge clk);
    rst = 0;


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
    if (full && !empty)
        $display("TEST PASSED: FIFO is full");
    else
        $display("TEST FAILED: FIFO is not full");
    
    //checking enable writing when full, test 3
    @(negedge clk);
    din = 100;
    wr_en = 1;
    rd_en = 0;
    @(negedge clk);
    wr_en = 0;
    if (full && !empty)
        $display("TEST PASSED: Over flow protection");
    else
        $display("TEST FAILED: Over flow protection");
    

    //checking old element is still there, test 4
    @(negedge clk);
    for (int i = 0; i < FIFO_DEPTH; i++) begin
        if (dut.mem[i] !== i + 1) begin
            $display("TEST FAILED: mem[%0d] = %0d", i, dut.mem[i]);
            $finish;
        end
    end
    $display("TEST PASSED: Old elements are still there");

    @(negedge clk);
    rst = 1;
    repeat (2) @(negedge clk);
    rst = 0;

    //Underflow protection, test 5
    if (empty !== 1'b1) begin
        $display("TEST FAILED: FIFO is not empty");
        $finish;
    end
    @(negedge clk);
    wr_en = 0;
    rd_en = 1;
    @(negedge clk);
    rd_en = 0;
    if (empty === 1'b1 && full === 1'b0 && dut.count === 5'd0) begin
        $display("TEST PASSED: Underflow protection");
    end
    else begin
        $display("TEST FAILED: Underflow protection");
    end

    // Test 6: Simultaneous Read and Write
    @(negedge clk);
    din = 10;
    wr_en = 1;
    @(negedge clk);
    din = 20;
    @(negedge clk);
    wr_en = 0;
    rd_en = 1;
    wr_en = 1;
    din = 30;
    @(negedge clk);
    rd_en = 0;
    wr_en = 0;
    if (dout === 8'd10 && empty === 1'b0 && full === 1'b0 && dut.count === 5'd2)
        $display("TEST PASSED: Simultaneous Read and Write");
    else
        $display("TEST FAILED: Simultaneous Read and Write");
    $finish;

end

endmodule
