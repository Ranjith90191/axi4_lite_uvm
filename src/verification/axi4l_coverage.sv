class axi4l_coverage extends uvm_subscriber #(axi4l_seq_item);
  `uvm_component_utils(axi4l_coverage)

  bit        is_write;
  bit        is_read;
  bit [31:0] addr;
  bit [3:0]  wstrb;
  bit [1:0]  resp;

  covergroup axi4l_cg;
    option.per_instance = 1;
    option.name = "axi4l_functional_coverage";

    cp_operation_type: coverpoint {is_write, is_read} {
      bins bin_op_write = {2'b10};
      bins bin_op_read  = {2'b01};
    }

    cp_address_region: coverpoint addr {
      bins bin_addr_normal_rw     = {[32'h00:32'h24], 32'h3C};
      bins bin_addr_read_only     = {32'h28, 32'h2C, 32'h30};
      bins bin_addr_write_only    = {32'h34, 32'h38};
      bins bin_addr_out_of_bounds = {[32'h40:32'hFFFFFFFF]};
    }

    cp_write_strobe: coverpoint wstrb iff (is_write == 1) {
      bins bin_wstrb_combinations[] = {[4'b0000:4'b1111]};
    }

    cp_axi_response: coverpoint resp {
      bins bin_resp_okay   = {`AXI_OKAY};
      bins bin_resp_slverr = {`AXI_SLVERR};
      bins bin_resp_decerr = {`AXI_DECERR};
    }

    cross_op_x_address: cross cp_operation_type, cp_address_region;
    
    cross_op_x_response: cross cp_operation_type, cp_axi_response;
    
    //cross_address_x_response: cross cp_address_region, cp_axi_response;

  endgroup

  function new(string name="axi4l_coverage", uvm_component parent=null);
    super.new(name, parent);
    axi4l_cg = new();
  endfunction

  virtual function void write(axi4l_seq_item t);
    if (t.txn_sel[`TXN_BIT_WRITE]) begin
      is_write = 1; 
      is_read  = 0;
      addr     = t.AWADDR;
      wstrb    = t.WSTRB;
      resp     = t.RESP;
      axi4l_cg.sample();
    end

    if (t.txn_sel[`TXN_BIT_READ]) begin
      is_write = 0; 
      is_read  = 1;
      addr     = t.ARADDR;
      wstrb    = 4'b0000;
      resp     = t.RESP;
      axi4l_cg.sample();
    end
  endfunction
endclass
