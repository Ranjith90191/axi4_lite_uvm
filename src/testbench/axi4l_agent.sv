class axi4l_agent extends uvm_agent;
  `uvm_component_utils(axi4l_agent)

  axi4l_sequencer     sqr;
  axi4l_driver        drv;
  axi4l_write_monitor wr_mon;
  axi4l_read_monitor  rd_mon;

  function new(string name = "axi4l_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_mon = axi4l_write_monitor::type_id::create("wr_mon", this);
    rd_mon = axi4l_read_monitor::type_id::create("rd_mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = axi4l_sequencer::type_id::create("sqr", this);
      drv = axi4l_driver::type_id::create("drv", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass
