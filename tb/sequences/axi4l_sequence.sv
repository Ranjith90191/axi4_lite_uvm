class axi4l_write_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_write_seq)
  function new(string name="axi4l_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (1000) begin
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
    repeat (1000) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize()with{txn_sel==2'b10;});
      finish_item(req);
    end
  endtask
endclass

class axi4l_normal_rw_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_normal_rw_seq)
  function new(string name="axi4l_normal_rw_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (500) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel inside {2'b01, 2'b10}; 
        AWADDR inside {[32'h00:32'h24], 32'h3C};
        ARADDR inside {[32'h00:32'h24], 32'h3C};
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
      });
      finish_item(req);
    end
  endtask
endclass

class axi4l_ro_test_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_ro_test_seq)
  function new(string name="axi4l_ro_test_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (300) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel inside {2'b01, 2'b10};
        AWADDR inside {32'h28, 32'h2C, 32'h30};
        ARADDR inside {32'h28, 32'h2C, 32'h30};
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
      });
      finish_item(req);
    end
  endtask
endclass

class axi4l_wo_test_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_wo_test_seq)
  function new(string name="axi4l_wo_test_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (300) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel inside {2'b01, 2'b10};
        AWADDR inside {32'h34, 32'h38};
        ARADDR inside {32'h34, 32'h38};
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
      });
  
      finish_item(req);
    end
  endtask
endclass

class axi4l_decerr_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_decerr_seq)
  function new(string name="axi4l_decerr_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (200) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel inside {2'b01, 2'b10};
        AWADDR inside {[32'h40:32'hFFFF]};
        ARADDR inside {[32'h40:32'hFFFF]};
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
      });
      finish_item(req);
    end
  endtask
endclass

class axi4l_unaligned_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_unaligned_seq)
  function new(string name="axi4l_unaligned_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (200) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel inside {2'b01, 2'b10};
        AWADDR[1:0] != 2'b00;
        ARADDR[1:0] != 2'b00;
      });
      finish_item(req);
    end
  endtask
endclass

class axi4l_concurrent_seq extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_concurrent_seq)
  function new(string name="axi4l_concurrent_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (5000) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel == 2'b11;
        AWADDR == ARADDR;
        wait_cfg_vector[3:0] == wait_cfg_vector[7:4];
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
      });
      finish_item(req);
    end
  endtask
endclass

class axi4l_fully_rand extends uvm_sequence #(axi4l_seq_item);
  `uvm_object_utils(axi4l_fully_rand)
  function new(string name="axi4l_fully_seq"); 
  	super.new(name); 
  endfunction

  virtual task body();
    axi4l_seq_item req;
    repeat (5000) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        AWADDR[1:0] == 2'b00;
        ARADDR[1:0] == 2'b00;
      });
      finish_item(req);
    end
  endtask
endclass

class axi4l_write_bug_seq extends uvm_sequence #(axi4l_seq_item);
	`uvm_object_utils(axi4l_write_bug_seq)
	function new(string name="axi4l_write_bug_seq");
		super.new(name);
	endfunction
	
	virtual task body();
    axi4l_seq_item req;
    
    repeat(10) begin
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel == 2'b10;  
        AWADDR == 32'h10;
        wait_cfg_vector[3:0] == wait_cfg_vector[7:4]; 
      });
      finish_item(req);
      
      req = axi4l_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        txn_sel == 2'b10;
        ARADDR == 32'h10;
        wait_cfg_vector[3:0] == wait_cfg_vector[7:4]; 
      });
      finish_item(req);
    end
  endtask
endclass
