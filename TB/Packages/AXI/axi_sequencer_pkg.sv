package axi_sequencer_pkg;

  import axi_transaction_pkg::*;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // parameterize with the type of transaction
  class axi_sequencer extends uvm_sequencer #(axi_transaction);
    `uvm_component_utils(axi_sequencer)

    function new(string name = "axi_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction  //new()

    // must have it to build the component
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info(get_type_name(), "Inside build sequencer class", UVM_LOW);
    endfunction

  endclass  //axi_sequencer
endpackage

