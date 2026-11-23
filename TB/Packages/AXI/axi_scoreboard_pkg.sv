package axi_scoreboard_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi_transaction_pkg::*;
  import parameters_pkg::*;

  class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    // ==========================================================
    // ANALYSIS EXPORT / FIFO
    // ==========================================================
    uvm_analysis_export #(axi_transaction) analysis_export;
    uvm_tlm_analysis_fifo #(axi_transaction) scb_fifo;

    // ==========================================================
    // GOLDEN MEMORY MODEL
    // ==========================================================
    logic [DATA_WIDTH-1:0] expected_memory[0:MEMORY_DEPTH-1];

    // ==========================================================
    // STATISTICS
    // ==========================================================
    int pass_count, error_count;

    int total_transactions, passed_transactions, failed_transactions;
    int total_checks, passed_checks, failed_checks;

    int data_checks, data_passes, data_failures;
    int response_checks, response_passes, response_failures;
    int rlast_checks, rlast_passes, rlast_failures;

    // Failed-transaction record, keyed by an internal running id
    axi_transaction failed_trans[int];
    string fail_reason[int];
    int trans_num;

    function new(string name = "axi_scoreboard", uvm_component parent);
      super.new(name, parent);

      pass_count = 0;
      error_count = 0;

      total_transactions = 0;
      passed_transactions = 0;
      failed_transactions = 0;

      total_checks = 0;
      passed_checks = 0;
      failed_checks = 0;

      data_checks = 0;
      data_passes = 0;
      data_failures = 0;

      response_checks = 0;
      response_passes = 0;
      response_failures = 0;

      rlast_checks = 0;
      rlast_passes = 0;
      rlast_failures = 0;

      trans_num = 0;

      foreach (expected_memory[i]) expected_memory[i] = '0;

      analysis_export = new("analysis_export", this);
      scb_fifo        = new("scb_fifo", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info(get_type_name(), "axi scoreboard build phase", UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
      analysis_export.connect(scb_fifo.analysis_export);
    endfunction

    // ==========================================================
    // RUN PHASE
    // ==========================================================
    task run_phase(uvm_phase phase);
      axi_transaction trans;

      forever begin
        scb_fifo.get(trans);

        // Ignore reset transactions pushed through by the monitor
        if (!trans.ARESETn) continue;

        trans_num++;
        compute_expected(trans);
        golden_checker(trans);
      end
    endtask

    // ==========================================================
    // Golden MODEL — mirrors the DUT's range + 4KB boundary check
    // ==========================================================
    function void compute_expected(axi_transaction tr);
      bit range_ok, boundary_ok;

      if (tr.op == WRITE) begin
        range_ok    = ((tr.AWADDR >> 2) + tr.AWLEN) < MEMORY_DEPTH;
        boundary_ok = ((tr.AWADDR & 16'h0FFF) + ((tr.AWLEN + 1) << tr.AWSIZE)) <= 16'h1000;
        tr.expected_bresp = (range_ok && boundary_ok) ? 2'b00 : 2'b10;
      end else begin
        range_ok    = ((tr.ARADDR >> 2) + tr.ARLEN) < MEMORY_DEPTH;
        boundary_ok = ((tr.ARADDR & 16'h0FFF) + ((tr.ARLEN + 1) << tr.ARSIZE)) <= 16'h1000;
        tr.expected_rresp = (range_ok && boundary_ok) ? 2'b00 : 2'b10;
      end
    endfunction

    // ==========================================================
    // GOLDEN CHECKER
    // ==========================================================
    task golden_checker(axi_transaction trans);
      bit transaction_pass;

      transaction_pass = 1'b1;
      total_transactions++;

      case (trans.op)
        WRITE: check_write(trans, transaction_pass);
        READ:  check_read(trans, transaction_pass);
        default: begin
          transaction_pass = 0;
          total_checks++;
          failed_checks++;
          error_count++;
          record_failure(trans, "UNKNOWN OPERATION");
          `uvm_error(get_type_name(), "UNKNOWN OPERATION")
        end
      endcase

      if (transaction_pass) begin
        passed_transactions++;
      end else begin
        failed_transactions++;
      end
    endtask

    // ==========================================================
    // WRITE CHECK
    // ==========================================================
    task check_write(axi_transaction trans, ref bit transaction_pass);
      int beat, index;

      // ---- BRESP check ----
      total_checks++;
      response_checks++;

      if (trans.BRESP == trans.expected_bresp) begin
        pass_count++;
        passed_checks++;
        response_passes++;
        `uvm_info(get_type_name(), $sformatf("[PASS] WRITE RESPONSE (id=%0d)", trans_num), UVM_LOW)
      end else begin
        transaction_pass = 0;
        error_count++;
        failed_checks++;
        response_failures++;
        record_failure(trans, "WRITE RESPONSE");
        `uvm_error(get_type_name(), $sformatf(
                   "WRITE RESPONSE mismatch (id=%0d): expected=%0b actual=%0b",
                   trans_num,
                   trans.expected_bresp,
                   trans.BRESP
                   ))
      end

      // ---- Update golden memory only on a legal (OKAY) write ----
      if (trans.BRESP == 2'b00) begin
        for (beat = 0; beat <= trans.AWLEN; beat++) begin
          index = (trans.AWADDR >> 2) + beat;
          if (index < MEMORY_DEPTH) begin
            expected_memory[index] = trans.WDATA[beat];
          end
        end
      end
    endtask

    // ==========================================================
    // READ CHECK
    // ==========================================================
    task check_read(axi_transaction trans, ref bit transaction_pass);
      int beat, index;
      logic [DATA_WIDTH-1:0] expected;

      // ---- DATA check ----
      if (trans.expected_rresp == 2'b00) begin
        // Legal read
        for (beat = 0; beat <= trans.ARLEN; beat++) begin
          index = (trans.ARADDR >> 2) + beat;
          if (index >= MEMORY_DEPTH) continue;

          expected = expected_memory[index];
          total_checks++;
          data_checks++;

          if (trans.RDATA[beat] == expected) begin
            pass_count++;
            passed_checks++;
            data_passes++;
          end else begin
            transaction_pass = 0;
            error_count++;
            failed_checks++;
            data_failures++;
            record_failure(trans, "READ DATA");
            `uvm_error(get_type_name(), $sformatf(
                       "READ DATA mismatch (id=%0d) addr=0x%0h expected=%08h actual=%08h",
                       trans_num,
                       trans.ARADDR + beat * 4,
                       expected,
                       trans.RDATA[beat]
                       ))
          end
        end
      end else begin
        // Illegal read — RDATA must be zero
        for (beat = 0; beat <= trans.ARLEN; beat++) begin
          total_checks++;
          data_checks++;

          if (trans.RDATA[beat] == '0) begin
            pass_count++;
            passed_checks++;
            data_passes++;
          end else begin
            transaction_pass = 0;
            error_count++;
            failed_checks++;
            data_failures++;
            record_failure(trans, "ILLEGAL READ DATA");
            `uvm_error(
                get_type_name(), $sformatf(
                "ILLEGAL READ DATA mismatch (id=%0d) actual=%08h", trans_num, trans.RDATA[beat]))
          end
        end
      end

      // ---- RRESP check ----
      total_checks++;
      response_checks++;

      if (trans.RRESP == trans.expected_rresp) begin
        pass_count++;
        passed_checks++;
        response_passes++;
      end else begin
        transaction_pass = 0;
        error_count++;
        failed_checks++;
        response_failures++;
        record_failure(trans, "READ RESPONSE");
        `uvm_error(get_type_name(), $sformatf(
                   "READ RESPONSE mismatch (id=%0d): expected=%0b actual=%0b",
                   trans_num,
                   trans.expected_rresp,
                   trans.RRESP
                   ))
      end

      // ---- RLAST check ----
      total_checks++;
      rlast_checks++;

      if (trans.RLAST) begin
        passed_checks++;
        rlast_passes++;
      end else begin
        transaction_pass = 0;
        error_count++;
        failed_checks++;
        rlast_failures++;
        record_failure(trans, "RLAST");
        `uvm_error(get_type_name(), $sformatf("RLAST not asserted (id=%0d)", trans_num))
      end
    endtask

    // ==========================================================
    // RECORD FAILURE
    // ==========================================================
    task automatic record_failure(axi_transaction trans, string reason);
      if (!failed_trans.exists(trans_num)) begin
        $cast(failed_trans[trans_num], trans.clone());
        fail_reason[trans_num] = reason;
      end
    endtask

    // ==========================================================
    // EXTRACT PHASE — final report
    // ==========================================================
    function void extract_phase(uvm_phase phase);
      `uvm_info("ERROR_COUNT", $sformatf("error count = %0d", error_count), UVM_LOW)
      `uvm_info("PASS_COUNT", $sformatf("pass count = %0d", pass_count), UVM_LOW)
      print_report();
    endfunction

    function void print_report();
      $display("\n==========================================================");
      $display("              SCOREBOARD FINAL REPORT");
      $display("==========================================================");
      $display("\nTransaction Statistics");
      $display("Total : %0d  Passed : %0d  Failed : %0d", total_transactions, passed_transactions,
               failed_transactions);
      $display("\nOverall Checks");
      $display("Total : %0d  Passed : %0d  Failed : %0d", total_checks, passed_checks,
               failed_checks);
      $display("\nData Checks    -> Total: %0d Passed: %0d Failed: %0d", data_checks, data_passes,
               data_failures);
      $display("Response Checks -> Total: %0d Passed: %0d Failed: %0d", response_checks,
               response_passes, response_failures);
      $display("RLAST Checks    -> Total: %0d Passed: %0d Failed: %0d", rlast_checks, rlast_passes,
               rlast_failures);

      if (failed_trans.num() == 0) begin
        $display("\nAll transactions PASSED.");
      end else begin
        int id;
        $display("\nFailed Transactions");
        $display("%-10s %-30s", "ID", "Reason");
        if (failed_trans.first(id)) begin
          do $display("%-10d %s", id, fail_reason[id]); while (failed_trans.next(id));
        end
      end
      $display("==========================================================\n");
    endfunction

  endclass
endpackage
