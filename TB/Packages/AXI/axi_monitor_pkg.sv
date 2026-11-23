package axi_monitor_pkg;

  import uvm_pkg::*;
  import axi_transaction_pkg::*;
  import common_config_pkg::*;
  import parameters_pkg::*;

  `include "uvm_macros.svh"

  class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    // analysis port to send the captured transaction to the scoreboard / coverage
    uvm_analysis_port #(axi_transaction) mon_ap;

    common_config m_cfg;
    virtual axi_if.MON mon_if;

    // Sequential ID assigned to each captured transaction, used by the
    // scoreboard to key its failure log / final report.
    int unsigned trans_id_counter;

    // ==========================================================
    // CONSTRUCTOR
    // ==========================================================
    function new(string name = "axi_monitor", uvm_component parent);
      super.new(name, parent);

      // Create analysis port
      mon_ap = new("mon_ap", this);

      `uvm_info(get_type_name(), "Inside new monitor class", UVM_LOW)
    endfunction

    // ==========================================================
    // BUILD PHASE
    // ==========================================================
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // --------------------------------------------------------
      // Get virtual interface
      // --------------------------------------------------------
      if (!uvm_config_db#(virtual axi_if.MON)::get(this, "", "mon_if", mon_if)) begin
        `uvm_fatal(get_type_name(), "Failed to retrieve the interface")
      end

      // --------------------------------------------------------
      // Get common configuration object
      // --------------------------------------------------------
      if (!uvm_config_db#(common_config)::get(this, "", "m_cfg", m_cfg)) begin
        `uvm_fatal(get_type_name(), "Failed to retrieve the configuration object")
      end
    endfunction

    // ==========================================================
    // RUN PHASE
    // ==========================================================
    task run_phase(uvm_phase phase);
      super.run_phase(phase);

      forever begin
        axi_transaction trans;

        // Create transaction object
        trans = axi_transaction::type_id::create("trans");

        // Assign a unique, sequential ID before capture
        trans.trans_id = trans_id_counter++;

        // Capture transaction from DUT
        monitor(trans);

        // Send transaction to scoreboard / coverage
        mon_ap.write(trans);
      end
    endtask

    extern task monitor(axi_transaction trans);
    extern task capture_write(ref axi_transaction tr);
    extern task capture_read(ref axi_transaction tr);
  endclass

  // ==========================================================
  // MAIN MONITOR TASK
  // ==========================================================
  task axi_monitor::monitor(axi_transaction trans);

    // ----------------------------------------------------------
    // Wait for a valid WRITE or READ address handshake
    // ----------------------------------------------------------
    forever begin
      @(posedge mon_if.ACLK);

      // --------------------------------------------------------
      // WRITE address handshake
      // --------------------------------------------------------
      if ((mon_if.AWVALID === 1'b1) && (mon_if.AWREADY === 1'b1)) begin
        capture_write(trans);
        break;
      end  // --------------------------------------------------------
      // READ address handshake
      // --------------------------------------------------------
      else if ((mon_if.ARVALID === 1'b1) && (mon_if.ARREADY === 1'b1)) begin
        capture_read(trans);
        break;
      end
    end
    // ----------------------------------------------------------
    // Transaction captured
    // ----------------------------------------------------------
    `uvm_info(get_type_name(), $sformatf("Transaction Captured:\n%s", trans.sprint()), UVM_LOW)
  endtask


  // ==========================================================
  // CAPTURE WRITE TRANSACTION
  // ==========================================================
  task automatic axi_monitor::capture_write(ref axi_transaction tr);

    int beat;
    tr.op      = WRITE;
    tr.ARESETn = mon_if.ARESETn;

    // ----------------------------------------------------------
    // Address Phase
    // ----------------------------------------------------------
    tr.AWADDR  = mon_if.AWADDR;
    tr.AWLEN   = mon_if.AWLEN;
    tr.AWSIZE  = mon_if.AWSIZE;
    tr.AWVALID = mon_if.AWVALID;
    tr.AWREADY = mon_if.AWREADY;

    // Allocate WDATA array according to burst length
    tr.WDATA   = new[tr.AWLEN + 1];

    // ----------------------------------------------------------
    // Data Phase
    // ----------------------------------------------------------
    for (beat = 0; beat <= tr.AWLEN; beat++) begin

      // Wait for WVALID && WREADY handshake
      do begin
        @(posedge mon_if.ACLK);
      end while (!((mon_if.WVALID === 1'b1) && (mon_if.WREADY === 1'b1)));

      tr.WDATA[beat] = mon_if.WDATA;
      tr.WVALID      = mon_if.WVALID;
      tr.WLAST       = mon_if.WLAST;
      tr.WREADY      = mon_if.WREADY;

      `uvm_info(
          get_type_name(), $sformatf(
          "Captured WRITE beat %0d: WDATA = 0x%0h, WLAST = %0b", beat, mon_if.WDATA, mon_if.WLAST),
          UVM_LOW)
    end

    // ----------------------------------------------------------
    // Response Phase
    // ----------------------------------------------------------
    do begin
      @(posedge mon_if.ACLK);
    end while (!((mon_if.BVALID === 1'b1) && (mon_if.BREADY === 1'b1)));

    tr.BRESP  = mon_if.BRESP;
    tr.BVALID = mon_if.BVALID;
    tr.BREADY = mon_if.BREADY;

    `uvm_info(get_type_name(), $sformatf("Captured WRITE response: BRESP = 0x%0h", tr.BRESP),
              UVM_LOW)

  endtask

  // ==========================================================
  // CAPTURE READ TRANSACTION
  // ==========================================================
  task automatic axi_monitor::capture_read(ref axi_transaction tr);

    int beat;
    tr.op      = READ;
    tr.ARESETn = mon_if.ARESETn;

    // ----------------------------------------------------------
    // Address Phase
    // ----------------------------------------------------------
    tr.ARADDR  = mon_if.ARADDR;
    tr.ARLEN   = mon_if.ARLEN;
    tr.ARSIZE  = mon_if.ARSIZE;
    tr.ARVALID = mon_if.ARVALID;
    tr.ARREADY = mon_if.ARREADY;

    // Allocate RDATA array according to burst length
    tr.RDATA   = new[tr.ARLEN + 1];

    // ----------------------------------------------------------
    // Data Phase
    // ----------------------------------------------------------
    for (beat = 0; beat <= tr.ARLEN; beat++) begin

      // Wait for RVALID && RREADY handshake
      do begin
        @(posedge mon_if.ACLK);
      end while (!((mon_if.RVALID === 1'b1) && (mon_if.RREADY === 1'b1)));

      tr.RDATA[beat] = mon_if.RDATA;
      tr.RRESP       = mon_if.RRESP;
      tr.RVALID      = mon_if.RVALID;
      tr.RLAST       = mon_if.RLAST;
      tr.RREADY      = mon_if.RREADY;

      `uvm_info(get_type_name(), $sformatf(
                "Captured READ beat %0d: RDATA = 0x%0h, RRESP = 0x%0h, RLAST = %0b",
                beat,
                mon_if.RDATA,
                mon_if.RRESP,
                mon_if.RLAST
                ), UVM_LOW)
    end
  endtask
endpackage
