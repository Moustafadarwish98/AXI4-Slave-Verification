package axi_rst_sequence_pkg;

  import uvm_pkg::*;
  import axi_transaction_pkg::*;

  `include "uvm_macros.svh"

  class axi_rst_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_rst_sequence)

    function new(string name = "axi_rst_sequence");
      super.new(name);

      `uvm_info(get_type_name(), "Inside new reset sequence class", UVM_LOW)
    endfunction


    task body();

      axi_transaction reset_trans;

      // ==========================================================
      // RESET TRANSACTION
      // ==========================================================

      reset_trans = axi_transaction::type_id::create("reset_trans");

      start_item(reset_trans);

      reset_trans.ARESETn = 1'b0;

      finish_item(reset_trans);

      `uvm_info(get_type_name(), "Reset transaction sent", UVM_LOW)

    endtask

  endclass

endpackage
