class axi4l_basic_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_basic_seq)
  function new(string name="axi4l_basic_seq"); super.new(name); endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (2000) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize());
      finish_item(req);
    end
  endtask
endclass

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
    axi4l_basic_seq seq = axi4l_basic_seq::type_id::create("seq");
    
    phase.raise_objection(this);
    #30ns;

    `uvm_info(get_type_name(), "Starting sequence now...", UVM_LOW)
    seq.start(env.agt.sqr);
    #2000ns;
    `uvm_info(get_type_name(), "Sequence finished dispatching, draining bus...", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
endclass
