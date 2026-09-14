class axi4l_read_monitor extends uvm_monitor;
  `uvm_component_utils(axi4l_read_monitor)

  virtual axi4l_if.RD_MON vif;
  uvm_analysis_port #(axi4l_seq_item) ap;

  function new(string name = "axi4l_read_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual axi4l_if.RD_MON)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "Virtual Interface get failed")
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      axi4l_seq_item item;
      bit [`AW-1:0] ar_addr;
      bit [2:0]     ar_prot;

      do @(vif.rd_mon_cb);
      while (!(vif.rd_mon_cb.ARVALID && vif.rd_mon_cb.ARREADY));
      ar_addr = vif.rd_mon_cb.ARADDR;
      ar_prot = vif.rd_mon_cb.ARPROT;

      do @(vif.rd_mon_cb);
      while (!(vif.rd_mon_cb.RVALID && vif.rd_mon_cb.RREADY));

      item = axi4l_seq_item::type_id::create("rd_item");
      item.kind   = READ_TXN;
      item.ARADDR = ar_addr;
      item.ARPROT = ar_prot;
      item.RDATA  = vif.rd_mon_cb.RDATA;
      item.RRESP  = vif.rd_mon_cb.RRESP;
      ap.write(item);
    end
  endtask
endclass
