package axi_env_pkg;

  import uvm_pkg::*;
  import axi_agent_pkg::*;
  import mem_agent_pkg::*;
  import axi_scoreboard_pkg::*;
  import axi_coverage_pkg::*;
  import mem_scoreboard_pkg::*;
  import mem_coverage_pkg::*;
  import common_config_pkg::*;

  `include "uvm_macros.svh"

  class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)

    // AXI agent and memory agent
    axi_agent agt;
    mem_agent agt2;

    axi_scoreboard sb;
    axi_coverage cov;
    mem_scoreboard mem_sb;
    mem_coverage mem_cov;
    common_config m_cfg;

    function new(string name = "axi_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      // Create the AXI agent and memory agent
      agt = axi_agent::type_id::create("agt", this);
      agt2 = mem_agent::type_id::create("agt2", this);
      // Create the scoreboards and coverage collectors
      sb = axi_scoreboard::type_id::create("sb", this);
      cov = axi_coverage::type_id::create("cov", this);
      mem_sb = mem_scoreboard::type_id::create("mem_sb", this);
      mem_cov = mem_coverage::type_id::create("mem_cov", this);

      if (!uvm_config_db#(common_config)::get(this, "", "m_cfg", m_cfg)) begin
        `uvm_fatal(get_type_name(), "Failed to retrieve the configuration object")
      end else begin
        `uvm_info(get_type_name(), "Successfully retrieved the configuration object", UVM_LOW)
      end
      // set the configuration object in the config_db for the agents and scoreboards
      uvm_config_db#(common_config)::set(this, "agt.*", "m_cfg", m_cfg);
      uvm_config_db#(common_config)::set(this, "agt2.*", "m_cfg", m_cfg);

      `uvm_info(get_type_name(), "Inside build env class", UVM_LOW);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      // ========================================================
      // PASS CONFIGURATION TO DRIVER
      // ========================================================
      // The environment has the configuration object.
      // Give the same configuration handle to the driver.
      agt.drv.m_cfg  = m_cfg;


      // ========================================================
      // PASS CONFIGURATION TO MONITOR
      // ========================================================
      // Give the same configuration handle to the monitor.
      agt.mon.m_cfg  = m_cfg;
      agt2.mon.m_cfg = m_cfg;

      // Connect the monitor's analysis port to the scoreboard's analysis export
      // ========================================================
      // AXI_MONITOR → COVERAGE/SCOREBOARD
      // ========================================================
      // The monitor publishes axi_transaction objects through
      agt.mon.mon_ap.connect(sb.analysis_export);
      agt.mon.mon_ap.connect(cov.analysis_export);

      // ========================================================
      // MEMORY MONITOR -> memory checker / memory coverage
      // ========================================================
      agt2.mon.mon_ap.connect(mem_sb.analysis_export);
      agt2.mon.mon_ap.connect(mem_cov.analysis_export);
    endfunction
  endclass

endpackage
