class axi4l_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi4l_scoreboard)
  uvm_tlm_analysis_fifo #(axi4l_seq_item) act_fifo;
  uvm_tlm_analysis_fifo #(axi4l_seq_item) exp_fifo;

  function new(string name="axi4l_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    act_fifo = new("act_fifo", this);
    exp_fifo = new("exp_fifo", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi4l_seq_item act, exp;
    forever begin
      exp_fifo.get(exp); act_fifo.get(act);
      if (act.RESP !== exp.RESP)
        `uvm_error("SCB_FAIL", $sformatf("RESP Mismatch. Act: %0h, Exp: %0h", act.RESP, exp.RESP))
      if (act.txn_sel[`TXN_BIT_READ] && (act.RESP == `AXI_OKAY)) begin
        if (act.RDATA !== exp.RDATA)
          `uvm_error("SCB_FAIL", $sformatf("RDATA Mismatch. Act: %0h, Exp: %0h", act.RDATA, exp.RDATA))
      end
    end
  endtask
endclass
