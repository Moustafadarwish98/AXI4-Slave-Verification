package axi_test_pkg;

  import uvm_pkg::*;
  import axi_env_pkg::*;
  import axi_sequence_pkg::*;
  import axi_driver_delay_pkg::*;
  import axi_driver_pkg::*;
  import axi_rst_sequence_pkg::*;
  import common_config_pkg::*;
  `include "uvm_macros.svh"

  class axi_test extends uvm_test;
    `uvm_component_utils(axi_test)

    axi_env env;
    axi_sequence seq;
    axi_rst_sequence rst_seq;
    common_config m_cfg;

    function new(string name = "axi_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      env = axi_env::type_id::create("env", this);
      // Create the sequences
      seq = axi_sequence::type_id::create("seq");
      rst_seq = axi_rst_sequence::type_id::create("rst_seq");
      // Add reset sequence here
      m_cfg = common_config::type_id::create("m_cfg", this);

      // Set the configuration object in the config_db for the environment
      uvm_config_db#(common_config)::set(this, "env", "m_cfg", m_cfg);

      `uvm_info(get_type_name(), "Inside build test class", UVM_LOW);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      // Print the UVM component hierarchy
      uvm_top.print_topology();
      `uvm_info(get_type_name(), "Inside end_of_elaboration_phase test class", UVM_LOW);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);

      phase.raise_objection(this);
      fork
        begin
          rst_seq.start(env.agt.sqr);
          seq.start(env.agt.sqr);
          #100ns;
        end
        begin
          `uvm_info(get_type_name(), "Starting axi sequence", UVM_LOW)
        end
      join
      phase.drop_objection(this);
    endtask

  endclass

  // Factory override to replace axi_driver with axi_driver_delay in the test
  class axi_test_driver_delay extends axi_test;
    `uvm_component_utils(axi_test_driver_delay)

    function new(string name = "axi_test_driver_delay", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      // Override the axi_driver with axi_driver_delay in the factory before the build phase of the test
      set_type_override_by_type(axi_driver::get_type(), axi_driver_delay::get_type());
      super.build_phase(phase);
    endfunction

  endclass
endpackage
