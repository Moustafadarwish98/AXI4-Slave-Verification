package mem_agent_pkg;

  import uvm_pkg::*;
  import mem_monitor_pkg::*;

  `include "uvm_macros.svh"

  class mem_agent extends uvm_agent;
    `uvm_component_utils(mem_agent)

    mem_monitor mon;

    function new(string name = "mem_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
        `uvm_info(get_type_name(), "is_active not set in config_db, defaulting to UVM_PASSIVE",
                  UVM_LOW)
        is_active = UVM_PASSIVE;
      end else if (is_active == UVM_ACTIVE) begin
        `uvm_error(get_type_name(), "is_active set to UVM_ACTIVE, but this agent is passive-only")
      end

      mon = mem_monitor::type_id::create("mon", this);
    endfunction
  endclass
endpackage
