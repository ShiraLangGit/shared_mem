module dual_port_ram (
    input  wire                  clk,
    input  wire                  rst_n,

    // Port A — write
    input  wire                  wr_en,
    input  wire [MEM_ADDR_W-1:0] wr_addr,
    input  wire [MEM_DATA_W-1:0] wr_data,

    // Port B — read
    input  wire                  rd_en,
    input  wire [MEM_ADDR_W-1:0] rd_addr,
    output reg  [MEM_DATA_W-1:0] rd_data
);

    reg [MEM_DATA_W-1:0] mem [0:MEM_DEPTH-1];

    reg [MEM_ADDR_W-1:0] rd_addr_r;
    reg [MEM_DATA_W-1:0] rd_data_r;

    // Write: 1 clock cycle latency (samples registered write_ctrl outputs)
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

    // Read: 2 clock cycle latency (addr register → data register → output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr_r <= {MEM_ADDR_W{1'b0}};
            rd_data_r <= {MEM_DATA_W{1'b0}};
            rd_data   <= {MEM_DATA_W{1'b0}};
        end else begin
            if (rd_en)
                rd_addr_r <= rd_addr;

            rd_data_r <= mem[rd_addr_r];
            rd_data   <= rd_data_r;
        end
    end

endmodule