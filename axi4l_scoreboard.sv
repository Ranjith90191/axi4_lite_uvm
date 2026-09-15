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
    bit match;
    
    forever begin
      exp_fifo.get(exp); 
      act_fifo.get(act);
      match = 1; 
      
      if (act.RESP !== exp.RESP) begin
        `uvm_error("SCB_FAIL", $sformatf("RESP Mismatch. Act: %0h, Exp: %0h", act.RESP, exp.RESP))
        match = 0;
      end
      
      if (act.txn_sel[`TXN_BIT_READ] && (act.RESP == `AXI_OKAY)) begin
        if (act.RDATA !== exp.RDATA) begin
          `uvm_error("SCB_FAIL", $sformatf("RDATA Mismatch at Addr %0h. Act: %0h, Exp: %0h", act.ARADDR, act.RDATA, exp.RDATA))
          match = 0;
        end
      end
      
      if (match) begin
        if (act.txn_sel[`TXN_BIT_WRITE]) begin
          `uvm_info("SCB_PASS", $sformatf("WRITE PASS -> Addr: %0h | Data: %0h | RESP: %0h", act.AWADDR, act.DATA, act.RESP), UVM_LOW)
        end
        if (act.txn_sel[`TXN_BIT_READ]) begin
          `uvm_info("SCB_PASS", $sformatf("READ PASS  -> Addr: %0h | RDATA: %0h | RESP: %0h", act.ARADDR, act.RDATA, act.RESP), UVM_LOW)
        end
      end
      
    end
  endtask
endclass
