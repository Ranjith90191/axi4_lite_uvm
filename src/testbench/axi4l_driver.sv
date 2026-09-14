class axi4l_driver extends uvm_driver #(axi4l_seq_item);
  `uvm_component_utils(axi4l_driver)

  virtual axi4l_if.DRV vif;

  function new(string name = "axi4l_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi4l_if.DRV)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual Interface get failed")
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset_signals();
    wait (vif.ARESETn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task reset_signals();
    vif.drv_cb.AWVALID <= 0;
    vif.drv_cb.WVALID  <= 0;
    vif.drv_cb.ARVALID <= 0;
    vif.drv_cb.BREADY  <= 0;
    vif.drv_cb.RREADY  <= 0;
  endtask

  virtual task drive(axi4l_seq_item pkt);
    case (pkt.OPERATION)
      WRITE_TXN: write_drive(pkt);
      READ_TXN : read_drive(pkt);
      MIXED_TXN: fork
                   write_drive(pkt);
                   read_drive(pkt);
                 join
      default  : `uvm_error(get_type_name(), "UNKNOWN OPERATION")
    endcase
  endtask

  virtual task write_drive(axi4l_seq_item pkt);
    fork
      begin
        repeat (pkt.aw_wait_cyc) @(vif.drv_cb);
        vif.drv_cb.AWADDR  <= pkt.AWADDR;
        vif.drv_cb.AWPROT  <= pkt.AWPROT;
        vif.drv_cb.AWVALID <= 1;
        while (!vif.drv_cb.AWREADY);
        
        vif.drv_cb.AWVALID <= 0;
      end
      begin
        repeat (pkt.w_wait_cyc) @(vif.drv_cb);
        vif.drv_cb.WDATA  <= pkt.WDATA;
        vif.drv_cb.WSTRB  <= pkt.WSTRB;
        vif.drv_cb.WVALID <= 1;
        do @(vif.drv_cb); while (!vif.drv_cb.WREADY);
        vif.drv_cb.WVALID <= 0;
      end
    join

    vif.drv_cb.BREADY <= 1;
    do @(vif.drv_cb); while (!vif.drv_cb.BVALID);
    pkt.BRESP = vif.drv_cb.BRESP;
    vif.drv_cb.BREADY <= 0;
  endtask

  virtual task read_drive(axi4l_seq_item pkt);
    @(vif.drv_cb);
    vif.drv_cb.ARADDR  <= pkt.ARADDR;
    vif.drv_cb.ARPROT  <= pkt.ARPROT;
    vif.drv_cb.ARVALID <= 1;
    do @(vif.drv_cb); while (!vif.drv_cb.ARREADY);
    vif.drv_cb.ARVALID <= 0;

    vif.drv_cb.RREADY <= 1;
    do @(vif.drv_cb); while (!vif.drv_cb.RVALID);
    pkt.RDATA = vif.drv_cb.RDATA;
    pkt.RRESP = vif.drv_cb.RRESP;
    vif.drv_cb.RREADY <= 0;
  endtask

endclass
