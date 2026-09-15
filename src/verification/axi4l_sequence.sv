class axi4l_write_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_write_seq)
  function new(string name="axi4l_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (100) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize()with{txn_sel==2'b01;});
      finish_item(req);
    end
  endtask
endclass

class axi4l_read_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_read_seq)
  function new(string name="axi4l_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (100) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize()with{txn_sel==2'b10;});
      finish_item(req);
    end
  endtask
endclass
