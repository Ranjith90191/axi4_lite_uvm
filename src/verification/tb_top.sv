import uvm_pkg::*;
import axi4l_pkg::*;

module tb_top;
  logic ACLK;
  logic ARESETn;

  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK; 
  end

  initial begin
  ARESETn = 0;
  #5; 
    ARESETn = 1; 
  end

  axi4l_if vif(
    .ACLK(ACLK),
    .ARESETn(ARESETn)
  );

  axi4_lite_slave #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .MEM_DEPTH(16),
    .DEFAULT_PROT(3'b000)
  ) dut (
    .ACLK    (ACLK),
    .ARESETn (ARESETn),
    .AWADDR  (vif.AWADDR),
    .AWPROT  (vif.AWPROT),
    .AWVALID (vif.AWVALID),
    .AWREADY (vif.AWREADY),
    .WDATA   (vif.WDATA),
    .WSTRB   (vif.WSTRB),
    .WVALID  (vif.WVALID),
    .WREADY  (vif.WREADY),
    .BRESP   (vif.BRESP),
    .BVALID  (vif.BVALID),
    .BREADY  (vif.BREADY),
    .ARADDR  (vif.ARADDR),
    .ARPROT  (vif.ARPROT),
    .ARVALID (vif.ARVALID),
    .ARREADY (vif.ARREADY),
    .RDATA   (vif.RDATA),
    .RRESP   (vif.RRESP),
    .RVALID  (vif.RVALID),
    .RREADY  (vif.RREADY)
  );

  initial begin
    uvm_config_db#(virtual axi4l_if.DRV)::set(null, "uvm_test_top.env.agt.drv", "vif", vif);
    
    uvm_config_db#(virtual axi4l_if.MON)::set(null, "uvm_test_top.env.agt.mon", "vif", vif);
    run_test("axi4l_test");
  end

endmodule
