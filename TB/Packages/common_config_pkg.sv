package common_config_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class common_config extends uvm_object;
    `uvm_object_utils(common_config)

    event drv_stimulus_sent;

    function new(string name = "common_config");
      super.new(name);
    endfunction  //new()

  endclass  //common_config
endpackage
