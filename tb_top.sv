`timescale 1ns/1ps
import uvm_pkg::*;
import axi4l_pkg::*;

module tb_top;
  logic ACLK;
  logic ARESETn;

  // AXI interface signal ACLK runs globally[cite: 1]
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
  end

  initial begin
    ARESETn = 0;
    #20 ARESETn = 1;
  end

  axi4l_if vif(.ACLK(ACLK), .ARESETn(ARESETn));

  // Connect your DUT here
  // axi4l_slave_dut dut (...);

  initial begin
    uvm_config_db#(virtual axi4l_if)::set(null, "uvm_test_top.env.agt.*", "vif", vif);
    run_test("axi4l_test");
  end
endmodule
