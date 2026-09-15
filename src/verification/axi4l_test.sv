class axi4l_test extends uvm_test;
  `uvm_component_utils(axi4l_test)
  axi4l_env env;

  function new(string name="axi4l_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4l_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi4l_write_seq seq = axi4l_write_seq::type_id::create("seq");
    axi4l_read_seq seq1 = axi4l_read_seq::type_id::create("seq1");
    phase.raise_objection(this);
    #30;

    `uvm_info(get_type_name(), "Starting sequence now...", UVM_LOW)
    seq.start(env.agt.sqr);
    #20000;
    seq1.start(env.agt.sqr);
    #20000;
    phase.drop_objection(this);
  endtask
endclass
