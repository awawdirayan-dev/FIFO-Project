module fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  logic clk,
    input  logic rst,

    input  logic wr_en,
    input  logic rd_en,

    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,

    output logic full,
    output logic empty
);

    // FIFO memory
    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Pointer widths
    localparam PTR_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH);

    // Read and write pointers
    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    // Number of stored elements
    localparam COUNT_WIDTH = $clog2(FIFO_DEPTH + 1);
    logic [COUNT_WIDTH-1:0] count;

    // Accepted operations
    logic write_accept;
    logic read_accept;

    // FIFO status
    assign full  = (count == FIFO_DEPTH);
    assign empty = (count == 0);

    // Operation control
    assign read_accept  = rd_en && !empty;
    assign write_accept = wr_en && (!full || read_accept);

    
    // Sequential logic
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= 0;
        end
        else begin

            // Write operation
            if (write_accept) begin
                mem[wr_ptr] <= din;

                if (wr_ptr == FIFO_DEPTH - 1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
            end

            // Read operation
            if (read_accept) begin
                dout <= mem[rd_ptr];

                if (rd_ptr == FIFO_DEPTH - 1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
            end

            // Update element count
            case ({write_accept, read_accept})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase

        end
    end


endmodule