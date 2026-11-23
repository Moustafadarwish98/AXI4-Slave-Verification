package axi_coverage_pkg;

  import axi_transaction_pkg::*;
  import parameters_pkg::*;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class axi_coverage extends uvm_component;
    `uvm_component_utils(axi_coverage)

    // ==========================================================
    // ANALYSIS EXPORT
    // ==========================================================
    uvm_analysis_export #(axi_transaction) analysis_export;

    // ==========================================================
    // ANALYSIS FIFO
    // ==========================================================
    uvm_tlm_analysis_fifo #(axi_transaction) cov_fifo;

    axi_transaction trans;

    covergroup axi_cvg;
      option.per_instance = 1;
      //=========================
      // Operation
      //=========================
      cp_operation: coverpoint trans.op {
        bins write = {WRITE}; bins read = {READ};
      }

      //=========================
      // Burst Length
      //=========================
      cp_awlen: coverpoint trans.AWLEN {
        bins single = {0};
        bins short = {[1 : 3]};
        bins medium_len = {[4 : 7]};
        bins long = {[8 : 15]};
      }

      cp_arlen: coverpoint trans.ARLEN {
        bins single = {0};
        bins short = {[1 : 3]};
        bins medium_len = {[4 : 7]};
        bins long = {[8 : 15]};
      }

      //=========================
      // Transfer Size
      //=========================
      cp_awsize: coverpoint trans.AWSIZE {
        bins word = {3'b010};
      }

      cp_arsize: coverpoint trans.ARSIZE {bins word = {3'b010};}

      //=========================
      // Address Alignment
      //=========================
      cp_awalign: coverpoint trans.AWADDR[1:0] {
        bins aligned = {2'b00};
      }

      cp_aralign: coverpoint trans.ARADDR[1:0] {bins aligned = {2'b00};}

      //=========================
      // Responses
      //=========================
      cp_bresp: coverpoint trans.BRESP {
        bins okay = {2'b00}; bins slverr = {2'b10};
      }

      cp_rresp: coverpoint trans.RRESP {bins okay = {2'b00}; bins slverr = {2'b10};}

      //=========================
      // Last Beat
      //=========================
      cp_rlast: coverpoint trans.RLAST {
        bins last = {1}; bins not_last = {0};
      }

      //=========================
      // Cross Coverage
      //=========================

      // Operation × Write Burst Length
      cross_op_write : cross cp_operation, cp_awlen{
        // READ transactions never have a meaningful AWLEN
        ignore_bins read_bins = binsof (cp_operation) intersect {
          READ
        };
      }

      // Operation × Read Burst Length
      cross_op_read : cross cp_operation, cp_arlen{
        // WRITE transactions never have a meaningful ARLEN
        ignore_bins write_bins = binsof (cp_operation) intersect {
          WRITE
        };
      }

      // Burst Length × Write Response
      cross_write_resp : cross cp_awlen, cp_bresp;

      // Burst Length × Read Response
      cross_read_resp : cross cp_arlen, cp_rresp;
    endgroup

    function new(string name = "axi_coverage", uvm_component parent);
      super.new(name, parent);
      axi_cvg = new();
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      analysis_export = new("analysis_export", this);
      cov_fifo = new("cov_fifo", this);
    endfunction

    // ==========================================================
    // CONNECT PHASE
    // =========================================================
    function void connect_phase(uvm_phase phase);
      // Call parent implementation.
      super.connect_phase(phase);
      // --------------------------------------------------------
      // Export → FIFO
      // --------------------------------------------------------
      analysis_export.connect(cov_fifo.analysis_export);
    endfunction

    // ==========================================================
    // RUN PHASE
    // ==========================================================
    task run_phase(uvm_phase phase);
      // Call parent implementation.
      super.run_phase(phase);
      forever begin
        // ------------------------------------------------------
        // Get transaction from FIFO
        // ------------------------------------------------------
        // fifo.get(tr) blocks until a transaction is available.
        cov_fifo.get(trans);
        // ------------------------------------------------------
        // Sample covergroup
        // ------------------------------------------------------
        axi_cvg.sample();
      end
    endtask
  endclass
endpackage
