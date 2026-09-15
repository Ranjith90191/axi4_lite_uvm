module axi4_lite_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_DEPTH  = 16,
    parameter [2:0] DEFAULT_PROT = 3'b000
)(
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  AWADDR,
    input  wire [2:0]             AWPROT,
    input  wire                   AWVALID,
    output reg                    AWREADY,

    // Write Data Channel
    input  wire [DATA_WIDTH-1:0]  WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input  wire                   WVALID,
    output reg                    WREADY,

    // Write Response Channel
    output reg  [1:0]             BRESP,
    output reg                    BVALID,
    input  wire                   BREADY,

    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  ARADDR,
    input  wire [2:0]             ARPROT,
    input  wire                   ARVALID,
    output reg                    ARREADY,

    // Read Data Channel
    output reg  [DATA_WIDTH-1:0]  RDATA,
    output reg  [1:0]             RRESP,
    output reg                    RVALID,
    input  wire                   RREADY
);

    // Protocol Response Constants
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_EXOKAY = 2'b01;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;

    // Memory Array
    reg [DATA_WIDTH-1:0] reg_file [0:MEM_DEPTH-1];
    integer i;

    // =========================================================================
    // WRITE CHANNEL LOGIC (Fully Decoupled)
    // =========================================================================
    reg aw_latched, w_latched;
    reg [ADDR_WIDTH-1:0] awaddr_lat;
    reg [DATA_WIDTH-1:0] wdata_lat;
    reg [3:0]            wstrb_lat;

    // Combinatorial Checks on LATCHED Address
    wire [3:0] wr_word_idx = awaddr_lat[5:2];
    wire wr_addr_unaligned = |awaddr_lat[1:0];
    wire wr_addr_out_of_bounds = (awaddr_lat > 32'h3F);
    wire wr_addr_ro = (wr_word_idx >= 10 && wr_word_idx <= 12); // Words 10-12 are Read-Only

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY    <= 1'b1;
            WREADY     <= 1'b1;
            BVALID     <= 1'b0;
            BRESP      <= RESP_OKAY;
            aw_latched <= 1'b0;
            w_latched  <= 1'b0;
            awaddr_lat <= 0;
            wdata_lat  <= 0;
            wstrb_lat  <= 0;
            for (i = 0; i < MEM_DEPTH; i = i + 1) reg_file[i] <= 0;
        end else begin
            
            // 1. Latch Address Channel
            if (AWVALID && AWREADY) begin
                awaddr_lat <= AWADDR;
                aw_latched <= 1'b1;
                AWREADY    <= 1'b0; // Drop ready instantly
            end
            
            // 2. Latch Data Channel
            if (WVALID && WREADY) begin
                wdata_lat <= WDATA;
                wstrb_lat <= WSTRB;
                w_latched <= 1'b1;
                WREADY    <= 1'b0; // Drop ready instantly
            end
            
            // 3. Process Write (Only when BOTH are latched and bus isn't stalled)
            if (aw_latched && w_latched && !BVALID) begin
                if (wr_addr_out_of_bounds) begin
                    BRESP <= RESP_DECERR;
                end else if (wr_addr_unaligned || wr_addr_ro) begin
                    BRESP <= RESP_SLVERR;
                end else begin
                    BRESP <= RESP_OKAY;
                    if (wstrb_lat[0]) reg_file[wr_word_idx][ 7: 0] <= wdata_lat[ 7: 0];
                    if (wstrb_lat[1]) reg_file[wr_word_idx][15: 8] <= wdata_lat[15: 8];
                    if (wstrb_lat[2]) reg_file[wr_word_idx][23:16] <= wdata_lat[23:16];
                    if (wstrb_lat[3]) reg_file[wr_word_idx][31:24] <= wdata_lat[31:24];
                end
                
                BVALID <= 1'b1; // Send Response
                aw_latched <= 1'b0;
                w_latched  <= 1'b0;
            end
            
            // 4. Complete Handshake & Reset for next transaction
            if (BVALID && BREADY) begin
                BVALID  <= 1'b0;
                AWREADY <= 1'b1;
                WREADY  <= 1'b1;
            end
        end
    end

    // =========================================================================
    // READ CHANNEL LOGIC (Fully Decoupled)
    // =========================================================================
    reg ar_latched;
    reg [ADDR_WIDTH-1:0] araddr_lat;

    // Combinatorial Checks on LATCHED Address
    wire [3:0] rd_word_idx = araddr_lat[5:2];
    wire rd_addr_unaligned = |araddr_lat[1:0];
    wire rd_addr_out_of_bounds = (araddr_lat > 32'h3F);
    wire rd_addr_wo = (rd_word_idx >= 13 && rd_word_idx <= 14); // Words 13-14 are Write-Only

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY    <= 1'b1;
            RVALID     <= 1'b0;
            RDATA      <= 0;
            RRESP      <= RESP_OKAY;
            ar_latched <= 1'b0;
            araddr_lat <= 0;
        end else begin
            
            // 1. Latch Address Channel
            if (ARVALID && ARREADY) begin
                araddr_lat <= ARADDR;
                ar_latched <= 1'b1;
                ARREADY    <= 1'b0; // Drop ready instantly
            end
            
            // 2. Process Read (Only when address is latched and bus isn't stalled)
            if (ar_latched && !RVALID) begin
                if (rd_addr_out_of_bounds) begin
                    RRESP <= RESP_DECERR;
                    RDATA <= 0;
                end else if (rd_addr_unaligned || rd_addr_wo) begin
                    RRESP <= RESP_SLVERR;
                    RDATA <= 0;
                end else begin
                    RRESP <= RESP_OKAY;
                    RDATA <= reg_file[rd_word_idx];
                end
                
                RVALID <= 1'b1; // Send Data
                ar_latched <= 1'b0;
            end

            // 3. Complete Handshake & Reset for next transaction
            if (RVALID && RREADY) begin
                RVALID  <= 1'b0;
                ARREADY <= 1'b1;
            end
        end
    end

endmodule
