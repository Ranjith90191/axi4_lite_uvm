class axi4l_base_sequence extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_base_sequence)
  function new(string name = "axi4l_base_sequence");
    super.new(name);
  endfunction
endclass

class write_only_sequence extends axi4l_base_sequence;
  `uvm_object_utils(write_only_sequence)
  function new(string name = "write_only_sequence");
    super.new(name);
  endfunction
  task body();
    repeat (`NUM_TXN) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { OPERATION == WRITE_TXN;})
        `uvm_fatal(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class read_only_sequence extends axi4l_base_sequence;
  `uvm_object_utils(read_only_sequence)
  function new(string name = "read_only_sequence");
    super.new(name);
  endfunction
  task body();
    repeat (`NUM_TXN) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { OPERATION == READ_TXN; })
        `uvm_fatal(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class mixed_random_sequence extends axi4l_base_sequence;
  `uvm_object_utils(mixed_random_sequence)
  function new(string name = "mixed_random_sequence");
    super.new(name);
  endfunction
  task body();
    repeat (`NUM_TXN) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { OPERATION inside {WRITE_TXN, READ_TXN}; })
        `uvm_fatal(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class concurrent_rw_sequence extends axi4l_base_sequence;
  `uvm_object_utils(concurrent_rw_sequence)
  function new(string name = "concurrent_rw_sequence");
    super.new(name);
  endfunction
  task body();
    repeat (`NUM_TXN) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { OPERATION == MIXED_TXN; })
        `uvm_fatal(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class write_then_read_sequence extends axi4l_base_sequence;
  `uvm_object_utils(write_then_read_sequence)
  function new(string name = "write_then_read_sequence");
    super.new(name);
  endfunction
  task body();
    axi4l_seq_item wr, rd;
    repeat (`NUM_TXN) begin
      wr = axi4l_seq_item::type_id::create("wr");
      start_item(wr);
      if (!wr.randomize() with { OPERATION == WRITE_TXN; })
        `uvm_fatal(get_type_name(), "Randomization failed")
      finish_item(wr);

      rd = axi4l_seq_item::type_id::create("rd");
      start_item(rd);
      if (!rd.randomize() with { OPERATION == READ_TXN; ARADDR == wr.AWADDR; })
        `uvm_fatal(get_type_name(), "Randomization failed")
      finish_item(rd);
    end
  endtask
endclass
