package axi_driver_delay_pkg;

  import uvm_pkg::*;
  import axi_driver_pkg::*;
  import axi_transaction_pkg::*;

  `include "uvm_macros.svh"

  //----------------------------------------------------------------------
  // axi_driver_delay
  //
  // Factory-override: identical driving behavior to axi_driver,
  // except idle cycles are inserted before each transfer instead of
  // driving back-to-back. Reuses axi_driver::drive() via super.drive()
  // so the actual WRITE/READ/RESET sequencing logic is not duplicated.
  //----------------------------------------------------------------------
  class axi_driver_delay extends axi_driver;
    `uvm_component_utils(axi_driver_delay)

    function new(string name = "axi_driver_delay", uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual task drive(axi_transaction trans);
      int idle_cycles;
      idle_cycles = $urandom_range(1, 5);

      `uvm_info(get_type_name(), $sformatf("Inserting %0d idle cycle(s) before driving transaction",
                                           idle_cycles), UVM_LOW)

      repeat (idle_cycles) @(posedge drv_if.ACLK);

      super.drive(trans);
    endtask

  endclass

endpackage
