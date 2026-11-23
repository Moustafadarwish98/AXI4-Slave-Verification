package axi_agent_pkg;
  import uvm_pkg::*;
  import axi_transaction_pkg::*;
  import axi_sequencer_pkg::*;
  import axi_driver_pkg::*;
  import axi_monitor_pkg::*;
  `include "uvm_macros.svh"

  class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_driver drv;
    axi_monitor mon;
    axi_sequencer sqr;
    uvm_active_passive_enum is_active;

    function new(string name = "axi_agent", uvm_component parent);
      super.new(name, parent);

    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      mon = axi_monitor::type_id::create("mon", this);

      if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
        `uvm_fatal(get_type_name(), "Failed to retrieve the is_active configuration")
      end

      `uvm_info(get_type_name(), $sformatf("Agent type is %p", is_active), UVM_LOW);

      if (is_active == UVM_ACTIVE) begin
        drv = axi_driver::type_id::create("drv", this);
        sqr = axi_sequencer::type_id::create("sqr", this);
      end

      `uvm_info(get_type_name(), "Inside build agent class", UVM_LOW);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (is_active == UVM_ACTIVE) begin
        drv.seq_item_port.connect(sqr.seq_item_export);
      end
    endfunction
  endclass
endpackage
