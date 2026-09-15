class axi4l_monitor extends uvm_monitor;
  `uvm_component_utils(axi4l_monitor)

  virtual axi4l_if.MON vif;
  uvm_analysis_port #(axi4l_seq_item) ap;

  function new(string name="axi4l_monitor", uvm_component parent=null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi4l_if.MON)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual interface get failed")
  endfunction

  virtual task run_phase(uvm_phase phase);
    // FIX 1: Wait for reset to finish so signals are no longer 'X'
    wait (vif.ARESETn === 1'b1);
    
    fork 
      collect_writes(); 
      collect_reads(); 
    join
  endtask

  virtual task collect_writes();
    forever begin
      axi4l_seq_item txn = axi4l_seq_item::type_id::create("txn");
      txn.txn_sel = (1 << `TXN_BIT_WRITE); 
      
      fork
        begin
          // FIX 2: Use !== 1'b1 to strictly handle 'X' states
          while (vif.mon_cb.AWVALID !== 1'b1 || vif.mon_cb.AWREADY !== 1'b1) @(vif.mon_cb);
          txn.AWADDR = vif.mon_cb.AWADDR; 
          txn.AWPROT = vif.mon_cb.AWPROT;
        end
        begin
          while (vif.mon_cb.WVALID !== 1'b1 || vif.mon_cb.WREADY !== 1'b1) @(vif.mon_cb);
          txn.DATA  = vif.mon_cb.WDATA; 
          txn.WSTRB = vif.mon_cb.WSTRB;
        end
      join
      
      while (vif.mon_cb.BVALID !== 1'b1 || vif.mon_cb.BREADY !== 1'b1) @(vif.mon_cb);
      txn.RESP = vif.mon_cb.BRESP;
      
      ap.write(txn); 
    end
  endtask

  virtual task collect_reads();
    forever begin
      axi4l_seq_item txn = axi4l_seq_item::type_id::create("txn");
      txn.txn_sel = (1 << `TXN_BIT_READ); 
      
      while (vif.mon_cb.ARVALID !== 1'b1 || vif.mon_cb.ARREADY !== 1'b1) @(vif.mon_cb);
      txn.ARADDR = vif.mon_cb.ARADDR; 
      txn.ARPROT = vif.mon_cb.ARPROT;
      
      while (vif.mon_cb.RVALID !== 1'b1 || vif.mon_cb.RREADY !== 1'b1) @(vif.mon_cb);
      txn.RDATA = vif.mon_cb.RDATA; 
      txn.RESP  = vif.mon_cb.RRESP;
      
      ap.write(txn);
    end
  endtask
endclass
