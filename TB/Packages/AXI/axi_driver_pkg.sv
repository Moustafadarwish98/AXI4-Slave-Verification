package axi_driver_pkg;

  import axi_transaction_pkg::*;
  import common_config_pkg::*;
  import parameters_pkg::*;
  import uvm_pkg::*;

  `include "uvm_macros.svh"

  class axi_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_driver)

    virtual axi_if.TB drv_if;
    common_config m_cfg;

    // ==========================================================
    // CONSTRUCTOR
    // ==========================================================
    function new(string name = "axi_driver", uvm_component parent);
      super.new(name, parent);
      `uvm_info(get_type_name(), "Inside new driver class", UVM_LOW)
    endfunction


    // ==========================================================
    // BUILD PHASE
    // ==========================================================
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      // --------------------------------------------------------
      // Get virtual interface
      // --------------------------------------------------------
      if (!uvm_config_db#(virtual axi_if.TB)::get(this, "", "drv_if", drv_if)) begin
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
        // Transaction received from sequencer
        axi_transaction trans;

        // ------------------------------------------------------
        // Get next transaction from sequencer
        // ------------------------------------------------------
        seq_item_port.get_next_item(trans);
        `uvm_info(get_type_name(), "Received transaction from sequencer", UVM_LOW)

        // ------------------------------------------------------
        // Convert transaction-level information to DUT signals
        // ------------------------------------------------------
        drive(trans);

        // ------------------------------------------------------
        // Tell sequencer that transaction is completed
        // ------------------------------------------------------
        seq_item_port.item_done();
      end
    endtask

    // Virtual to be able to excersize the factory and override in the test class
    extern virtual task drive(axi_transaction trans);
    extern task axi_write(axi_transaction tr);
    extern task axi_read(axi_transaction tr);
    extern task do_reset(axi_transaction tr);

  endclass

  // ==========================================================
  // DRIVE
  // ==========================================================
  task axi_driver::drive(axi_transaction trans);
    if (!trans.ARESETn) begin
      do_reset(trans);
    end else begin
      case (trans.op)
        WRITE:   axi_write(trans);
        READ:    axi_read(trans);
        default: `uvm_fatal(get_type_name(), "Unknown Transaction Type")
      endcase
    end
    //->m_cfg.drv_stimulus_sent;
  endtask

  task automatic axi_driver::do_reset(axi_transaction tr);
    `uvm_info(get_type_name(), "Driving RESET", UVM_LOW)

    @(negedge drv_if.ACLK);
    drv_if.ARESETn <= 1'b0;
    drv_if.AWVALID <= 1'b0;
    drv_if.WVALID  <= 1'b0;
    drv_if.WLAST   <= 1'b0;
    drv_if.BREADY  <= 1'b0;
    drv_if.ARVALID <= 1'b0;
    drv_if.RREADY  <= 1'b0;

    repeat (2) @(negedge drv_if.ACLK);

    drv_if.ARESETn <= 1'b1;
    @(negedge drv_if.ACLK);

    `uvm_info(get_type_name(), "RESET complete", UVM_LOW)
  endtask


  // ==========================================================
  // AXI WRITE
  // ==========================================================
  task automatic axi_driver::axi_write(axi_transaction tr);

    int beat;
    `uvm_info(get_type_name(), "AXI WRITE START", UVM_LOW)
    // ----------------------------------------------------------
    // WRITE ADDRESS CHANNEL
    // ----------------------------------------------------------
    @(negedge drv_if.ACLK);
    drv_if.AWADDR  <= tr.AWADDR;
    drv_if.AWLEN   <= tr.AWLEN;
    drv_if.AWSIZE  <= tr.AWSIZE;
    drv_if.AWVALID <= 1;

    `uvm_info(get_type_name(), $sformatf(
                                   "Driving AW Channel: AWADDR = 0x%0h, AWLEN = %0d, AWSIZE = %0d",
                                   tr.AWADDR, tr.AWLEN, tr.AWSIZE), UVM_LOW)

    // Wait until slave is ready
    do @(posedge drv_if.ACLK); while (!drv_if.AWREADY);

    // Address handshake completed
    drv_if.AWVALID <= 0;

    `uvm_info(get_type_name(), "AW Channel handshake completed", UVM_LOW)
    // ----------------------------------------------------------
    // WRITE DATA CHANNEL
    // ----------------------------------------------------------
    for (beat = 0; beat <= tr.AWLEN; beat++) begin
      @(negedge drv_if.ACLK);
      drv_if.WDATA <= tr.WDATA[beat];

      repeat (tr.wvalid_delay) begin
        @(posedge drv_if.ACLK);
      end

      drv_if.WVALID <= 1;

      // Assert WLAST for final beat
      drv_if.WLAST  <= (beat == tr.AWLEN);

      `uvm_info(get_type_name(), $sformatf(
                "Driving WDATA: beat = %0d, WDATA = 0x%0h, WLAST = %0b",
                beat,
                tr.WDATA[beat],
                (beat == tr.AWLEN)
                ), UVM_LOW)

      // Wait until slave is ready
      do @(posedge drv_if.ACLK); while (!drv_if.WREADY);

      // Data handshake completed
      drv_if.WVALID <= 0;
      drv_if.WLAST  <= 0;
    end
    // ----------------------------------------------------------
    // WRITE RESPONSE CHANNEL
    // ----------------------------------------------------------

    // Wait until slave response is valid
    do @(posedge drv_if.ACLK); while (!drv_if.BVALID);

    `uvm_info(get_type_name(), $sformatf("BVALID asserted, BRESP = 0x%0h", drv_if.BRESP), UVM_LOW)

    // Wait before asserting BREADY
    repeat (tr.bready_delay) @(posedge drv_if.ACLK);

    // Assert BREADY for one cycle
    drv_if.BREADY <= 1;
    @(posedge drv_if.ACLK);
    drv_if.BREADY <= 0;

    `uvm_info(get_type_name(), "AXI WRITE DONE", UVM_LOW)
  endtask

  // ==========================================================
  // AXI READ
  // ==========================================================
  task automatic axi_driver::axi_read(axi_transaction tr);

    int beat;
    `uvm_info(get_type_name(), "AXI READ START", UVM_LOW)

    // ----------------------------------------------------------
    // READ ADDRESS CHANNEL
    // ----------------------------------------------------------
    @(negedge drv_if.ACLK);
    drv_if.ARADDR  <= tr.ARADDR;
    drv_if.ARLEN   <= tr.ARLEN;
    drv_if.ARSIZE  <= tr.ARSIZE;
    drv_if.ARVALID <= 1;

    `uvm_info(get_type_name(), $sformatf(
                                   "Driving AR Channel: ARADDR = 0x%0h, ARLEN = %0d, ARSIZE = %0d",
                                   tr.ARADDR, tr.ARLEN, tr.ARSIZE), UVM_LOW)

    // Wait until slave is ready
    do @(posedge drv_if.ACLK); while (!drv_if.ARREADY);

    // Address handshake completed
    drv_if.ARVALID <= 0;

    `uvm_info(get_type_name(), "AR Channel handshake completed", UVM_LOW)

    // ----------------------------------------------------------
    // READ DATA CHANNEL
    // ----------------------------------------------------------
    for (beat = 0; beat <= tr.ARLEN; beat++) begin

      // Wait until slave sends valid data
      do @(posedge drv_if.ACLK); while (!drv_if.RVALID);

      // Wait before asserting RREADY
      repeat (tr.rready_delay) @(posedge drv_if.ACLK);

      drv_if.RREADY <= 1;

      `uvm_info(get_type_name(), $sformatf(
                "Accepting RDATA: beat = %0d, RDATA = 0x%0h, RRESP = 0x%0h, RLAST = %0b",
                beat,
                drv_if.RDATA,
                drv_if.RRESP,
                drv_if.RLAST
                ), UVM_LOW)

      @(posedge drv_if.ACLK);
      drv_if.RREADY <= 0;
    end

    `uvm_info(get_type_name(), "AXI READ DONE", UVM_LOW)
  endtask
endpackage
