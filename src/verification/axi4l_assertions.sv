module axi4_lite_sva #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input wire  ACLK,
    input wire ARESETn,
    input wire [ADDR_WIDTH-1:0]AWADDR,
    input wire [2:0] AWPROT,
    input wire AWVALID,
    input wire AWREADY,
    input wire [DATA_WIDTH-1:0] WDATA,
    input wire [(DATA_WIDTH/8)-1:0] WSTRB,
    input wire  WVALID,
    input wire WREADY,
    input wire [1:0] BRESP,
    input wire  BVALID,
    input wire BREADY,
    input wire [ADDR_WIDTH-1:0] ARADDR,
    input wire [2:0] ARPROT,
    input wire ARVALID,
    input wire  ARREADY,    
    input  wire [DATA_WIDTH-1:0]RDATA,
    input  wire [1:0] RRESP,
    input  wire   RVALID,
    input  wire RREADY
);

    property p_reset_bvalid;
        @(posedge ACLK) (!ARESETn) |=> (!BVALID);
    endproperty
    assert property(p_reset_bvalid) else $error("BVALID must be low after ARESETn drops");

    property p_reset_rvalid;
        @(posedge ACLK) (!ARESETn) |=> (!RVALID);
    endproperty
    assert property(p_reset_rvalid) else $error("RVALID must be low after ARESETn drops");

    property p_awvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (AWVALID && !AWREADY) |=> AWVALID;
    endproperty
    assert property(p_awvalid_stable) else $error("AWVALID dropped without AWREADY");

    property p_awaddr_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (AWVALID && !AWREADY) |=> $stable(AWADDR);
    endproperty
    assert property(p_awaddr_stable) else $error("AWADDR changed while AWVALID high and AWREADY low");

    property p_wvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (WVALID && !WREADY) |=> WVALID;
    endproperty
    assert property(p_wvalid_stable) else $error("WVALID dropped without WREADY");

    property p_wdata_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (WVALID && !WREADY) |=> $stable(WDATA);
    endproperty
    assert property(p_wdata_stable) else $error("WDATA changed while WVALID high and WREADY low");

    property p_wstrb_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (WVALID && !WREADY) |=> $stable(WSTRB);
    endproperty
    assert property(p_wstrb_stable) else $error("WSTRB changed while WVALID high and WREADY low");

    property p_bvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (BVALID && !BREADY) |=> BVALID;
    endproperty
    assert property(p_bvalid_stable) else $error("BVALID dropped without BREADY");

    property p_bresp_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (BVALID && !BREADY) |=> $stable(BRESP);
    endproperty
    assert property(p_bresp_stable) else $error("BRESP changed while BVALID high and BREADY low");

    property p_arvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (ARVALID && !ARREADY) |=> ARVALID;
    endproperty
    assert property(p_arvalid_stable) else $error("ARVALID dropped without ARREADY");

    property p_araddr_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (ARVALID && !ARREADY) |=> $stable(ARADDR);
    endproperty
    assert property(p_araddr_stable) else $error("ARADDR changed while ARVALID high and ARREADY low");

    property p_rvalid_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (RVALID && !RREADY) |=> RVALID;
    endproperty
    assert property(p_rvalid_stable) else $error("RVALID dropped without RREADY");

    property p_rdata_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (RVALID && !RREADY) |=> $stable(RDATA);
    endproperty
    assert property(p_rdata_stable) else $error("RDATA changed while RVALID high and RREADY low");

    property p_rresp_stable;
        @(posedge ACLK) disable iff (!ARESETn)
        (RVALID && !RREADY) |=> $stable(RRESP);
    endproperty
    assert property(p_rresp_stable) else $error("RRESP changed while RVALID high and RREADY low");

endmodule
