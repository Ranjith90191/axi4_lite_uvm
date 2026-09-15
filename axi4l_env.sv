class axi4l_env extends uvm_env;
  `uvm_component_utils(axi4l_env)
  axi4l_agent      agt;
  axi4l_ref_model  ref_mod;
  axi4l_scoreboard scb;

  function new(string name="axi4l_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt     = axi4l_agent::type_id::create("agt", this);
    ref_mod = axi4l_ref_model::type_id::create("ref_mod", this);
    scb     = axi4l_scoreboard::type_id::create("scb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    agt.mon.ap.connect(ref_mod.mon_export);
    agt.mon.ap.connect(scb.act_fifo.analysis_export);
    ref_mod.exp_port.connect(scb.exp_fifo.analysis_export);
  endfunction
endclass
