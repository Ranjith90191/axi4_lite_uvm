interface axi4l_if #(parameter AW = 32, DW = 32) (input bit ACLK, input bit ARESETn);
  logic [AW-1:0] AWADDR;
  logic [2:0] AWPROT;
  logic AWVALID;
  logic AWREADY;
  logic [DW-1:0]WDATA;
  logic [DW/8-1:0] WSTRB;
  logic WVALID;
  logic WREADY;
  logic [1:0]BRESP;
  logic BVALID;
  logic BREADY;
  logic [AW-1:0]ARADDR;
  logic [2:0] ARPROT;
  logic ARVALID;
  logic ARREADY;
  logic [DW-1:0]RDATA;
  logic [1:0] RRESP;
  logic RVALID;
  logic RREADY;

  clocking drv_cb @(posedge ACLK);
    output AWADDR,AWPROT,AWVALID;
    input  AWREADY;
    output WDATA,WSTRB,WVALID;
    input  WREADY;
    input  BRESP,BVALID;
    output BREADY;
    output ARADDR,ARPROT,ARVALID;
    input  ARREADY;
    input  RDATA,RRESP,RVALID;
    output RREADY;
  endclocking

  clocking wr_mon_cb @(posedge ACLK);
    input AWADDR, AWPROT, AWVALID, AWREADY;
    input WDATA, WSTRB, WVALID, WREADY;
    input BRESP, BVALID, BREADY;
  endclocking

  clocking rd_mon_cb @(posedge ACLK);
    input ARADDR, ARPROT, ARVALID, ARREADY;
    input RDATA, RRESP, RVALID, RREADY;
  endclocking

  modport DRV(clocking drv_cb,    input ACLK, ARESETn);
  modport WR_MON (clocking wr_mon_cb, input ACLK, ARESETn);
  modport RD_MON (clocking rd_mon_cb, input ACLK, ARESETn);

endinterface
