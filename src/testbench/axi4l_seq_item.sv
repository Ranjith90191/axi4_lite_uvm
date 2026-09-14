typedef enum bit [1:0] {WRITE_TXN = 0, READ_TXN = 1, MIXED_TXN = 2} axi4l_txn_kind_e;

class axi4l_seq_item extends uvm_sequence_item;
  rand axi4l_txn_kind_e OPERATION;
  rand bit [`AW-1:0] AWADDR;
  rand bit [2:0]AWPROT;
  rand bit [`DW-1:0]WDATA;
  rand bit [`DW/8-1:0]WSTRB;
  bit[1:0]BRESP;
  rand bit [`AW-1:0]ARADDR;
  rand bit [2:0]ARPROT;
  bit [`DW-1:0]RDATA;
  bit [1:0]RRESP;
  rand int unsigned aw_wait_cyc;
  rand int unsigned w_wait_cyc;

  constraint c_wait {
    aw_wait_cyc inside {[0:4]};
    w_wait_cyc  inside {[0:4]};
  }

  `uvm_object_utils_begin(axi4l_seq_item)
    `uvm_field_enum(axi4l_txn_kind_e,OPERATION,UVM_ALL_ON)
    `uvm_field_int(AWADDR,UVM_ALL_ON)
    `uvm_field_int(AWPROT,UVM_ALL_ON)
    `uvm_field_int(WDATA,UVM_ALL_ON)
    `uvm_field_int(WSTRB,UVM_ALL_ON)
    `uvm_field_int(BRESP,UVM_ALL_ON)
    `uvm_field_int(ARADDR,UVM_ALL_ON)
    `uvm_field_int(ARPROT,UVM_ALL_ON)
    `uvm_field_int(RDATA,UVM_ALL_ON)
    `uvm_field_int(RRESP,UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "axi4l_seq_item");
    super.new(name);
  endfunction

endclass
