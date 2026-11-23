package mem_scoreboard_pkg;

  import uvm_pkg::*;
  import parameters_pkg::*;
  import mem_transaction_pkg::*;

  `include "uvm_macros.svh"

  class mem_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mem_scoreboard)

    // Analysis port to receive transactions from the monitor port
    // uvm_analysis_imp #(transaction type, scoreboard type) analysis_export;
    uvm_analysis_imp #(mem_transaction, mem_scoreboard) analysis_export;

    // Golden reference memory
    bit [DATA_WIDTH-1:0] golden_memory[0:MEMORY_DEPTH-1];

    int unsigned pass_count;
    int unsigned fail_count;

    function new(string name = "mem_scoreboard", uvm_component parent);
      super.new(name, parent);
      analysis_export = new("analysis_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      foreach (golden_memory[i]) golden_memory[i] = '0;
      pass_count = 0;
      fail_count = 0;
    endfunction

    // implementation of the analysis_export write method, which is called by the monitor port
    // when a transaction is received.
    function void write(mem_transaction tr);
      if (tr.mem_we) begin
        golden_memory[tr.mem_addr] = tr.mem_wdata;
        `uvm_info(get_type_name(), $sformatf("[PASS] WRITE addr=0x%0h data=0x%0h", tr.mem_addr,
                                             tr.mem_wdata), UVM_HIGH)
        pass_count++;
      end else begin
        if (tr.mem_rdata !== golden_memory[tr.mem_addr]) begin
          `uvm_error(get_type_name(),
                     $sformatf("[FAIL] READ mismatch addr=0x%0h expected=0x%0h got=0x%0h",
                               tr.mem_addr, golden_memory[tr.mem_addr], tr.mem_rdata))
          fail_count++;
        end else begin
          `uvm_info(get_type_name(), $sformatf(
                    "[PASS] READ addr=0x%0h data=0x%0h", tr.mem_addr, tr.mem_rdata), UVM_HIGH)
          pass_count++;
        end
      end
    endfunction

    function void extract_phase(uvm_phase phase);
      super.extract_phase(phase);
      `uvm_info(get_type_name(), $sformatf(
                "MEM SCOREBOARD REPORT: PASS=%0d FAIL=%0d", pass_count, fail_count), UVM_LOW)
    endfunction

  endclass

endpackage
