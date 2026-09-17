`timescale 1ns/1ps

module axi4_lite_slave #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 32,
    parameter MEM_DEPTH    = 16,
    parameter [2:0] DEFAULT_PROT = 3'b000
)(
    input  wire                          ACLK,
    input  wire                          ARESETn,

    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0]         AWADDR,
    input  wire [2:0]                    AWPROT,
    input  wire                          AWVALID,
    output reg                           AWREADY,

    // Write Data Channel
    input  wire [DATA_WIDTH-1:0]         WDATA,
    input  wire [(DATA_WIDTH/8)-1:0]     WSTRB,
    input  wire                          WVALID,
    output reg                           WREADY,

    // Write Response Channel
    output reg  [1:0]                    BRESP,
    output reg                           BVALID,
    input  wire                          BREADY,

    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0]         ARADDR,
    input  wire [2:0]                    ARPROT,
    input  wire                          ARVALID,
    output reg                           ARREADY,

    // Read Data Channel
    output reg  [DATA_WIDTH-1:0]         RDATA,
    output reg  [1:0]                    RRESP,
    output reg                           RVALID,
    input  wire                          RREADY
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
    // WRITE CHANNEL LOGIC (Decoupled Latches & Priority Checking)
    // =========================================================================
    reg aw_latched, w_latched;
    reg [ADDR_WIDTH-1:0]     awaddr_lat;
    reg [DATA_WIDTH-1:0]     wdata_lat;
    reg [(DATA_WIDTH/8)-1:0] wstrb_lat;

    // Word Address & Region Checks (evaluated strictly on latched address)
    wire [$clog2(MEM_DEPTH)-1:0] wr_word_idx       = awaddr_lat[$clog2(MEM_DEPTH)+1:2];
    wire                         wr_addr_unaligned = |awaddr_lat[1:0];
    wire                         wr_addr_out_of_bounds = (awaddr_lat >= (MEM_DEPTH * 4));
    // Specialized Read-Only area: words 10 to 12 (0x28, 0x2C, 0x30)
    wire                         wr_addr_ro        = (!wr_addr_out_of_bounds) && (wr_word_idx >= 10 && wr_word_idx <= 12);

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY     <= 1'b1;
            WREADY      <= 1'b1;
            BVALID      <= 1'b0;
            BRESP       <= RESP_OKAY;
            aw_latched  <= 1'b0;
            w_latched   <= 1'b0;
            awaddr_lat  <= {ADDR_WIDTH{1'b0}};
            wdata_lat   <= {DATA_WIDTH{1'b0}};
            wstrb_lat   <= {(DATA_WIDTH/8){1'b0}};
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                reg_file[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            // 1. Latch Address Channel
            if (AWVALID && AWREADY) begin
                awaddr_lat <= AWADDR;
                aw_latched <= 1'b1;
                AWREADY    <= 1'b0; // Slam door shut immediately
            end

            // 2. Latch Data Channel
            if (WVALID && WREADY) begin
                wdata_lat  <= WDATA;
                wstrb_lat  <= WSTRB;
                w_latched  <= 1'b1;
                WREADY     <= 1'b0; // Slam door shut immediately
            end

            // 3. Process Write (when both channels are captured and no unacknowledged response)
            if (aw_latched && w_latched && !BVALID) begin
                // Priority 1: Alignment Violation (SLVERR)
                if (wr_addr_unaligned) begin
                    BRESP <= RESP_SLVERR;
                end
                // Priority 2: Permission Violation - RO Region (SLVERR)
                else if (wr_addr_ro) begin
                    BRESP <= RESP_SLVERR;
                end
                // Priority 3: Out-of-Bounds Memory (DECERR)
                else if (wr_addr_out_of_bounds) begin
                    BRESP <= RESP_DECERR;
                end
                // Normal write operation
                else begin
                    BRESP <= RESP_OKAY;
                    if (wstrb_lat[0]) reg_file[wr_word_idx][ 7: 0] <= wdata_lat[ 7: 0];
                    if (wstrb_lat[1]) reg_file[wr_word_idx][15: 8] <= wdata_lat[15: 8];
                    if (wstrb_lat[2]) reg_file[wr_word_idx][23:16] <= wdata_lat[23:16];
                    if (wstrb_lat[3]) reg_file[wr_word_idx][31:24] <= wdata_lat[31:24];
                end

                BVALID     <= 1'b1;
                aw_latched <= 1'b0;
                w_latched  <= 1'b0;
            end

            // 4. Response Handshake and ready reset
            if (BVALID && BREADY) begin
                BVALID  <= 1'b0;
                AWREADY <= 1'b1;
                WREADY  <= 1'b1;
            end
        end
    end

    // =========================================================================
    // READ CHANNEL LOGIC (Decoupled Latches & Priority Checking)
    // =========================================================================
    reg ar_latched;
    reg [ADDR_WIDTH-1:0] araddr_lat;

    // Word Address & Region Checks (evaluated strictly on latched address)
    wire [$clog2(MEM_DEPTH)-1:0] rd_word_idx       = araddr_lat[$clog2(MEM_DEPTH)+1:2];
    wire                         rd_addr_unaligned = |araddr_lat[1:0];
    wire                         rd_addr_out_of_bounds = (araddr_lat >= (MEM_DEPTH * 4));
    // Specialized Write-Only area: words 13 to 14 (0x34, 0x38)
    wire                         rd_addr_wo        = (!rd_addr_out_of_bounds) && (rd_word_idx >= 13 && rd_word_idx <= 14);

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY    <= 1'b1;
            RVALID     <= 1'b0;
            RDATA      <= {DATA_WIDTH{1'b0}};
            RRESP      <= RESP_OKAY;
            ar_latched <= 1'b0;
            araddr_lat <= {ADDR_WIDTH{1'b0}};
        end else begin
            // 1. Latch Address Channel
            if (ARVALID && ARREADY) begin
                araddr_lat <= ARADDR;
                ar_latched <= 1'b1;
                ARREADY    <= 1'b0; // Slam door shut immediately
            end

            // 2. Process Read (when address is captured and no unacknowledged read data)
            if (ar_latched && !RVALID) begin
                // Priority 1: Alignment Violation (SLVERR)
                if (rd_addr_unaligned) begin
                    RRESP <= RESP_SLVERR;
                    RDATA <= {DATA_WIDTH{1'b0}};
                end
                // Priority 2: Permission Violation - WO Region (SLVERR)
                else if (rd_addr_wo) begin
                    RRESP <= RESP_SLVERR;
                    RDATA <= {DATA_WIDTH{1'b0}};
                end
                // Priority 3: Out-of-Bounds Memory (DECERR)
                else if (rd_addr_out_of_bounds) begin
                    RRESP <= RESP_DECERR;
                    RDATA <= {DATA_WIDTH{1'b0}};
                end
                // Normal read operation
                else begin
                    RRESP <= RESP_OKAY;
                    RDATA <= reg_file[rd_word_idx];
                end

                RVALID     <= 1'b1;
                ar_latched <= 1'b0;
            end

            // 3. Data Handshake and ready reset
            if (RVALID && RREADY) begin
                RVALID  <= 1'b0;
                ARREADY <= 1'b1;
            end
        end
    end

endmodule
