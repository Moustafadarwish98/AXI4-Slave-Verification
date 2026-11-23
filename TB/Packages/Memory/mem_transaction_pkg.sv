package mem_transaction_pkg;

  import uvm_pkg::*;
  import parameters_pkg::*;

  `include "uvm_macros.svh"

  class mem_transaction extends uvm_sequence_item;

    bit                        mem_en;
    bit                        mem_we;
    logic [MEM_ADDR_WIDTH-1:0] mem_addr;
    logic [    DATA_WIDTH-1:0] mem_wdata;
    logic [    DATA_WIDTH-1:0] mem_rdata;


    `uvm_object_utils_begin(mem_transaction)
      `uvm_field_int(mem_en, UVM_ALL_ON)
      `uvm_field_int(mem_we, UVM_ALL_ON)
      `uvm_field_int(mem_addr, UVM_ALL_ON)
      `uvm_field_int(mem_wdata, UVM_ALL_ON)
      `uvm_field_int(mem_rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "mem_transaction");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf(
          "mem_transaction: %s addr=0x%0h wdata=0x%0h rdata=0x%0h",
          mem_we ? "WRITE" : "READ",
          mem_addr,
          mem_wdata,
          mem_rdata
      );
    endfunction

  endclass

endpackage
