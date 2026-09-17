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
    axi4l_normal_rw_seq normal_seq = axi4l_normal_rw_seq::type_id::create("normal_seq");
    axi4l_ro_test_seq ro_seq = axi4l_ro_test_seq::type_id::create("ro_seq");
    axi4l_wo_test_seq wo_seq = axi4l_wo_test_seq::type_id::create("wo_seq");
    axi4l_decerr_seq decerr_seq = axi4l_decerr_seq::type_id::create("decerr_seq");
    axi4l_unaligned_seq unalgn_seq = axi4l_unaligned_seq::type_id::create("unalgn_seq");
    axi4l_concurrent_seq conc_seq  = axi4l_concurrent_seq::type_id::create("conc_seq");
    axi4l_fully_rand rand_seq = axi4l_fully_rand::type_id::create("rand_seq");
    
    phase.raise_objection(this);
    #30;
    
    `uvm_info(get_type_name(), "Starting Write only Sequence", UVM_LOW)
    seq.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting Read only Sequence", UVM_LOW)
    seq1.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting Normal Sequence", UVM_LOW)
    normal_seq.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting Read only Sequence", UVM_LOW)
    ro_seq.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting Write Only Sequence", UVM_LOW)
    wo_seq.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting DecErr Sequence", UVM_LOW)
    decerr_seq.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting Unaligned address Sequence", UVM_LOW)
    unalgn_seq.start(env.agt.sqr);
    #200000;
    
    `uvm_info(get_type_name(), "Starting Concurrent Sequence", UVM_LOW)
    conc_seq.start(env.agt.sqr);
    #20000;
    
    `uvm_info(get_type_name(), "Starting Random Sequence", UVM_LOW)
    rand_seq.start(env.agt.sqr);
    #20000;
    phase.drop_objection(this);
  endtask

endclass

class axi4l_write_bug_test extends uvm_test;
  `uvm_component_utils(axi4l_write_bug_test)
  axi4l_env env;

  function new(string name="axi4l_write_bug_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4l_env::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
  	axi4l_write_bug_seq seq;
  	axi4l_concurrent_seq seq1;
  	//seq = axi4l_write_bug_seq::type_id::create("seq");
  	seq1 = axi4l_concurrent_seq::type_id::create("seq1");
  	phase.raise_objection(this);
  	#30;
  	//seq.start(env.agt.sqr);
  	seq1.start(env.agt.sqr);
  	#20000;
  	phase.drop_objection(this);
  endtask
endclass
