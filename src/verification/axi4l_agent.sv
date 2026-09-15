class axi4l_agent extends uvm_agent;
  `uvm_component_utils(axi4l_agent)
  axi4l_sequencer sqr;
  axi4l_driver    drv;
  axi4l_monitor   mon;

  function new(string name="axi4l_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = axi4l_sequencer::type_id::create("sqr", this);
    drv = axi4l_driver::type_id::create("drv", this);
    mon = axi4l_monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
