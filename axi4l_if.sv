interface axi4l_if(input logic ACLK, input logic ARESETn);
  // Write Address Channel[cite: 1]
  logic [31:0] AWADDR;
  logic [2:0]  AWPROT;
  logic        AWVALID;
  logic        AWREADY;

  // Write Data Channel[cite: 1]
  logic [31:0] WDATA;
  logic [3:0]  WSTRB;
  logic        WVALID;
  logic        WREADY;

  // Write Response Channel[cite: 1]
  logic [1:0]  BRESP;
  logic        BVALID;
  logic        BREADY;

  // Read Address Channel[cite: 1]
  logic [31:0] ARADDR;
  logic [2:0]  ARPROT;
  logic        ARVALID;
  logic        ARREADY;

  // Read Data Channel[cite: 1]
  logic [31:0] RDATA;
  logic [1:0]  RRESP;
  logic        RVALID;
  logic        RREADY;

  // Clocking block for driver
  clocking drv_cb @(posedge ACLK);
    default input #1step output #1;
    output AWADDR, AWPROT, AWVALID, WDATA, WSTRB, WVALID, BREADY, ARADDR, ARPROT, ARVALID, RREADY;
    input  AWREADY, WREADY, BRESP, BVALID, ARREADY, RDATA, RRESP, RVALID;
  endclocking

  // Clocking block for monitor
  clocking mon_cb @(posedge ACLK);
    default input #1step;
    input AWADDR, AWPROT, AWVALID, AWREADY;
    input WDATA, WSTRB, WVALID, WREADY;
    input BRESP, BVALID, BREADY;
    input ARADDR, ARPROT, ARVALID, ARREADY;
    input RDATA, RRESP, RVALID, RREADY;
  endclocking

  modport DRV (clocking drv_cb, input ARESETn);
  modport MON (clocking mon_cb, input ARESETn);
endinterface
