class axi4l_seq_item extends uvm_sequence_item;
  rand bit [1:0] txn_sel;
  rand bit [15:0] wait_cfg_vector; // [3:0]=AW, [7:4]=W, [11:8]=AR

  rand bit [31:0] AWADDR;
  rand bit [2:0]  AWPROT;
  rand bit [31:0] ARADDR;
  rand bit [2:0]  ARPROT;

  rand bit [31:0] DATA;
  rand bit [3:0]  WSTRB;

  bit [31:0] RDATA;
  bit [1:0]  RESP;

  `uvm_object_utils_begin(axi4l_seq_item)
    `uvm_field_int(txn_sel, UVM_ALL_ON)
    `uvm_field_int(wait_cfg_vector, UVM_ALL_ON)
    `uvm_field_int(AWADDR, UVM_ALL_ON)
    `uvm_field_int(ARADDR, UVM_ALL_ON)
    `uvm_field_int(DATA, UVM_ALL_ON)
    `uvm_field_int(WSTRB, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "axi4l_seq_item");
    super.new(name);
  endfunction

  constraint addr_c {
    AWADDR <= 32'h3F; AWADDR[1:0] == 2'b00; // Aligned byte addressing[cite: 1]
    ARADDR <= 32'h3F; ARADDR[1:0] == 2'b00;
  }
endclass
