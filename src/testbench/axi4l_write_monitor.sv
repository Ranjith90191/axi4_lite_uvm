class axi4l_write_monitor extends uvm_monitor;
  `uvm_component_utils(axi4l_write_monitor)

  virtual axi4l_if.WR_MON vif;
  uvm_analysis_port #(axi4l_seq_item) ap;

  function new(string name = "axi4l_write_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi4l_if.WR_MON)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual Interface get failed")
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [`AW-1:0]   aw_addr;
    bit [2:0]       aw_prot;
    bit [`DW-1:0]   w_data;
    bit [`DW/8-1:0] w_strb;

    forever begin
      // AW and W can complete on different cycles - watch both independently
      fork
        begin
          do @(vif.wr_mon_cb);
          while (!(vif.wr_mon_cb.AWVALID && vif.wr_mon_cb.AWREADY));
          aw_addr = vif.wr_mon_cb.AWADDR;
          aw_prot = vif.wr_mon_cb.AWPROT;
        end
        begin
          do @(vif.wr_mon_cb);
          while (!(vif.wr_mon_cb.WVALID && vif.wr_mon_cb.WREADY));
          w_data = vif.wr_mon_cb.WDATA;
          w_strb = vif.wr_mon_cb.WSTRB;
        end
      join

      do @(vif.wr_mon_cb);
      while (!(vif.wr_mon_cb.BVALID && vif.wr_mon_cb.BREADY));

      begin
        axi4l_seq_item item = axi4l_seq_item::type_id::create("wr_item");
        item.kind   = WRITE_TXN;
        item.AWADDR = aw_addr;
        item.AWPROT = aw_prot;
        item.WDATA  = w_data;
        item.WSTRB  = w_strb;
        item.BRESP  = vif.wr_mon_cb.BRESP;
        ap.write(item);
      end
    end
  endtask
endclass
