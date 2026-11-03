
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

    logic [DATA_WIDTH-1:0] reference_queue[$];
    logic model_read_accept;
    logic model_write_accept;
    logic [DATA_WIDTH-1:0] expected_dout;


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

    always @(posedge clk) begin

    if (rst) begin
        reference_queue.delete();
    end

    else begin

        model_read_accept = rd_en && (reference_queue.size() > 0);

        model_write_accept = wr_en &&
                             ((reference_queue.size() < FIFO_DEPTH) ||
                              model_read_accept);

        if (model_read_accept)
            expected_dout = reference_queue.pop_front();

        if (model_write_accept)
            reference_queue.push_back(din);

        #1;

        if (model_read_accept) begin
            if (dout !== expected_dout) begin
                $display("SCOREBOARD FAILED: Expected %0d, Got %0d",
                         expected_dout, dout);
                $finish;
            end
        end

        if (dut.count !== reference_queue.size()) begin
            $display("SCOREBOARD FAILED: Count mismatch");
            $display("Expected count = %0d, Actual count = %0d",
                     reference_queue.size(), dut.count);
            $finish;
        end

        if (full !== (reference_queue.size() == FIFO_DEPTH)) begin
            $display("SCOREBOARD FAILED: Full flag mismatch");
            $finish;
        end

        if (empty !== (reference_queue.size() == 0)) begin
            $display("SCOREBOARD FAILED: Empty flag mismatch");
            $finish;
        end

    end
end

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




    // pointer location, test 7  
    @(negedge clk);
    rst = 1;
    wr_en = 0;
    rd_en = 0;
    repeat (2) @(negedge clk);
    rst = 0;
    for (int i = 1; i <= FIFO_DEPTH; i++) begin
    @(negedge clk);
    din = i;
    wr_en = 1;
end
@(negedge clk);
wr_en = 0;
    @(negedge clk);
    wr_en = 0;
    if (dut.wr_ptr === 0)
        $display("TEST PASSED: Write pointer wrapped around");
    else
        $display("TEST FAILED: wr_ptr = %0d", dut.wr_ptr);
    @(negedge clk);
    rd_en = 1;
    for (int i = 1; i <= FIFO_DEPTH; i++) begin
        @(negedge clk);

        if (dout !== i) begin
            $display("TEST FAILED: Expected %0d, Got %0d", i, dout);
            $finish;
        end
    end
    rd_en = 0;
    if (dut.rd_ptr === 0 && empty === 1'b1)
        $display("TEST PASSED: Read pointer wrapped around");
    else
        $display("TEST FAILED: rd_ptr = %0d", dut.rd_ptr);  

    @(negedge clk);
    rst = 1;
    repeat (2) @(negedge clk);
    rst = 0;


    //read write when full, test 8
    for (int i = 1; i <= FIFO_DEPTH; i++) begin
        @(negedge clk);
        din = i;
        wr_en = 1;
    end
    @(negedge clk);
    wr_en = 0;
    if (full !== 1'b1) begin
        $display("TEST FAILED: FIFO is not full");
        $finish;
    end
    @(negedge clk);
    rd_en = 1;
    wr_en = 1;
    din = 99;
    @(negedge clk);
    rd_en = 0;
    wr_en = 0;
    if (dout === 8'd1 && dut.count === 5'd16 && full === 1'b1 && empty === 1'b0)
        $display("TEST PASSED: Simultaneous Read/Write When Full");
    else begin
        $display("TEST FAILED: Full FIFO simultaneous operation");
        $display("dout = %0d, count = %0d", dout, dut.count);
        $finish;
    end
    @(negedge clk);
    rd_en = 1;
    for (int i = 2; i <= FIFO_DEPTH; i++) begin
     @(negedge clk);
     if (dout !== i) begin
          $display("TEST FAILED: Expected %0d, Got %0d", i, dout);
          $finish;
        end
    end
    @(negedge clk);
    if (dout !== 8'd99) begin
     $display("TEST FAILED: Expected 99, Got %0d", dout);
        $finish;
    end
    rd_en = 0;
    $display("TEST PASSED: Data integrity after simultaneous operation");
    $finish;  

end

endmodule
