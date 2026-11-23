package mem_coverage_pkg;

  import uvm_pkg::*;
  import parameters_pkg::*;
  import mem_transaction_pkg::*;

  `include "uvm_macros.svh"

  class mem_coverage extends uvm_component;
    `uvm_component_utils(mem_coverage)


    // Analysis port to receive transactions from the monitor port
    // uvm_analysis_imp #(transaction type, coverage type) analysis_export;
    uvm_analysis_imp #(mem_transaction, mem_coverage) analysis_export;

    mem_transaction trans;

    covergroup mem_cg;
      option.per_instance = 1;

      cp_operation: coverpoint trans.mem_we {bins read = {1'b0}; bins write = {1'b1};}

      cp_addr: coverpoint trans.mem_addr {
        bins low = {[0 : 15]};
        bins middle = {[16 : MEMORY_DEPTH - 17]};
        bins high = {[MEMORY_DEPTH - 16 : MEMORY_DEPTH - 1]};
      }

      cp_addr_edges: coverpoint trans.mem_addr {
        bins first = {0}; bins last = {MEMORY_DEPTH - 1}; bins others = default;
      }

      cp_wdata: coverpoint trans.mem_wdata iff (trans.mem_we) {
        bins zero = {32'h0000_0000}; bins ones = {32'hFFFF_FFFF}; bins other = default;
      }

      cp_rdata: coverpoint trans.mem_rdata iff (!trans.mem_we) {
        bins zero = {32'h0000_0000}; bins ones = {32'hFFFF_FFFF}; bins other = default;
      }

      //--------------------------------------------------------
      // Cross Coverage
      //--------------------------------------------------------
      cross_op_addr: cross cp_operation, cp_addr;

    endgroup

    function new(string name = "mem_coverage", uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
      mem_cg = new();
    endfunction

    // implementation of the analysis_export write method, which is called by the monitor port
    // when a transaction is received.
    function void write(mem_transaction tr);
      // Store the transaction for coverage sampling
      trans = tr;
      mem_cg.sample();
      `uvm_info(get_type_name(), $sformatf("Coverage sampled: %s", trans.convert2string()),
                UVM_HIGH)
    endfunction

    function void extract_phase(uvm_phase phase);
      super.extract_phase(phase);
      `uvm_info(get_type_name(), $sformatf("MEM COVERAGE: %.2f%%", mem_cg.get_coverage()), UVM_LOW)
    endfunction

  endclass
endpackage
