`uvm_analysis_imp_decl(_mon)
class axi4l_ref_model extends uvm_component;
  `uvm_component_utils(axi4l_ref_model)
  uvm_analysis_imp_mon #(axi4l_seq_item, axi4l_ref_model) mon_export;
  uvm_analysis_port #(axi4l_seq_item) exp_port;

  bit [31:0] mem [16]; 

  function new(string name="axi4l_ref_model", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_export = new("mon_export", this);
    exp_port = new("exp_port", this);
    foreach(mem[i]) mem[i] = 32'h0;
  endfunction

  virtual function void write_mon(axi4l_seq_item t);
    axi4l_seq_item exp = axi4l_seq_item::type_id::create("exp");
    exp.copy(t);
       `uvm_info("REF_TRACE", "Ref model processed item", UVM_LOW)
    if (t.txn_sel[`TXN_BIT_WRITE]) process_write(exp);
    else if (t.txn_sel[`TXN_BIT_READ]) process_read(exp);
    exp_port.write(exp);
  endfunction

  local function void process_write(axi4l_seq_item txn);
    bit [3:0] word_idx = txn.AWADDR[5:2]; 
    if (txn.AWADDR[1:0] != 2'b00) txn.RESP = `AXI_SLVERR;
    else if (txn.AWADDR > 32'h3F) txn.RESP = `AXI_DECERR;
    else if (word_idx >= 10 && word_idx <= 12) txn.RESP = `AXI_SLVERR; 
    else begin
      txn.RESP = `AXI_OKAY;

      if (txn.WSTRB[0]) mem[word_idx][7:0]   = txn.DATA[7:0];
      if (txn.WSTRB[1]) mem[word_idx][15:8]  = txn.DATA[15:8];
      if (txn.WSTRB[2]) mem[word_idx][23:16] = txn.DATA[23:16];
      if (txn.WSTRB[3]) mem[word_idx][31:24] = txn.DATA[31:24];
    end
  endfunction

  local function void process_read(axi4l_seq_item txn);
    bit [3:0] word_idx = txn.ARADDR[5:2];
    if (txn.ARADDR[1:0] != 2'b00) txn.RESP = `AXI_SLVERR;
    else if (txn.ARADDR > 32'h3F) txn.RESP = `AXI_DECERR;
    else if (word_idx >= 13 && word_idx <= 14) txn.RESP = `AXI_SLVERR;
    else begin
      txn.RESP  = `AXI_OKAY;
      txn.RDATA = mem[word_idx];
    end
  endfunction
endclass
