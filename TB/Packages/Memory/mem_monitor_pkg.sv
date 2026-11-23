package mem_monitor_pkg;

  import uvm_pkg::*;
  import parameters_pkg::*;
  import common_config_pkg::*;
  import mem_transaction_pkg::*;

  `include "uvm_macros.svh"

  class mem_monitor extends uvm_monitor;
    `uvm_component_utils(mem_monitor)

    virtual mem_if.MON        mon_if;
    common_config             m_cfg;

    uvm_analysis_port #(mem_transaction) mon_ap;

    // One-beat pipeline for a read command awaiting its registered data.
    bit      read_pending;
    bit   [MEM_ADDR_WIDTH-1:0] read_pending_addr;
  
    function new(string name = "mem_monitor", uvm_component parent);
      super.new(name, parent);
      mon_ap = new("mon_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual mem_if.MON)::get(this, "", "mon_if", mon_if)) begin
        `uvm_fatal(get_type_name(), "Failed to get mon_if (virtual mem_if.MON) from config_db")
      end else begin
        `uvm_info(get_type_name(), "Successfully retrieved mon_if (mem_if.MON)", UVM_LOW)
      end
    endfunction

    task run_phase(uvm_phase phase);
      mem_transaction trans;

      read_pending = 1'b0;

      forever begin
        @(posedge mon_if.clk);

        if (!mon_if.rst_n) begin
          read_pending = 1'b0;
          continue;
        end

        //--------------------------------------------------------------
        // Drain a read latched last cycle -- mem_rdata is valid now.
        //--------------------------------------------------------------
        if (read_pending) begin
          trans           = mem_transaction::type_id::create("trans");
          trans.mem_en    = 1'b1;
          trans.mem_we    = 1'b0;
          trans.mem_addr  = read_pending_addr;
          trans.mem_wdata = '0;
          trans.mem_rdata = mon_if.mem_rdata;
          `uvm_info(get_type_name(), trans.convert2string(), UVM_HIGH)
          mon_ap.write(trans);
          read_pending = 1'b0;
        end

        //--------------------------------------------------------------
        // Sample this cycle's command
        //--------------------------------------------------------------
        if (mon_if.mem_en) begin
          if (mon_if.mem_we) begin
            // Write: no data latency.
            trans           = mem_transaction::type_id::create("trans");
            trans.mem_en    = 1'b1;
            trans.mem_we    = 1'b1;
            trans.mem_addr  = mon_if.mem_addr;
            trans.mem_wdata = mon_if.mem_wdata;
            trans.mem_rdata = '0;
            `uvm_info(get_type_name(), trans.convert2string(), UVM_HIGH)
            mon_ap.write(trans);
          end else begin
            // Read: latch the command, publish next cycle once
            // mem_rdata is valid.
            read_pending      = 1'b1;
            read_pending_addr = mon_if.mem_addr;
          end
        end
      end
    endtask
  endclass
endpackage
