`timescale 1ns/1ps
import uvm_pkg::*;
import axi4l_pkg::*;

module tb_top;
  logic ACLK;
  logic ARESETn;

  // Clock generation
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK; // 100MHz clock
  end

  // Reset generation
  initial begin
    ARESETn = 0;
    #20 ARESETn = 1; // Release reset after 20ns
  end

  // Instantiate the AXI4-Lite Interface
  axi4l_if vif(
    .ACLK(ACLK),
    .ARESETn(ARESETn)
  );

  // Instantiate and connect the DUT
  axi4_lite_slave #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .MEM_DEPTH(16),
    .DEFAULT_PROT(3'b000)
  ) dut (
    .ACLK    (ACLK),
    .ARESETn (ARESETn),

    // Write Address Channel
    .AWADDR  (vif.AWADDR),
    .AWPROT  (vif.AWPROT),
    .AWVALID (vif.AWVALID),
    .AWREADY (vif.AWREADY),

    // Write Data Channel
    .WDATA   (vif.WDATA),
    .WSTRB   (vif.WSTRB),
    .WVALID  (vif.WVALID),
    .WREADY  (vif.WREADY),

    // Write Response Channel
    .BRESP   (vif.BRESP),
    .BVALID  (vif.BVALID),
    .BREADY  (vif.BREADY),

    // Read Address Channel
    .ARADDR  (vif.ARADDR),
    .ARPROT  (vif.ARPROT),
    .ARVALID (vif.ARVALID),
    .ARREADY (vif.ARREADY),

    // Read Data Channel
    .RDATA   (vif.RDATA),
    .RRESP   (vif.RRESP),
    .RVALID  (vif.RVALID),
    .RREADY  (vif.RREADY)
  );

  // Pass the interface to UVM config DB and start the test
  initial begin
    // Note: The DRV/MON modports are handled automatically by the virtual interface declarations in the classes
    uvm_config_db#(virtual axi4l_if)::set(null, "uvm_test_top.env.agt.*", "vif", vif);
    run_test("axi4l_test");
  end

endmodule
