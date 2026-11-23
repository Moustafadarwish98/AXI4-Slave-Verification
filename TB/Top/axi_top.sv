import uvm_pkg::*;
`include "uvm_macros.svh"

import axi_env_pkg::*;
import axi_test_pkg::*;
import parameters_pkg::*;
import axi_driver_delay_pkg::*;

module axi_top;

  // ==========================================================
  // INTERFACE
  // ==========================================================
  axi_if axi_if ();
  mem_if mem_if ();

  // ==========================================================
  // CLOCK GENERATION
  // ==========================================================
  initial begin
    axi_if.ACLK = 0;
    forever #5 axi_if.ACLK = ~axi_if.ACLK;
  end

  //----------------------------------------------------------
  // DUT Instantiation
  //----------------------------------------------------------
  axi4_fixed #(
      .DATA_WIDTH  (DATA_WIDTH),
      .ADDR_WIDTH  (ADDR_WIDTH),
      .MEMORY_DEPTH(MEMORY_DEPTH)
  ) dut (

      .ACLK   (axi_if.ACLK),
      .ARESETn(axi_if.ARESETn),

      // Write Address Channel
      .AWADDR (axi_if.AWADDR),
      .AWLEN  (axi_if.AWLEN),
      .AWSIZE (axi_if.AWSIZE),
      .AWVALID(axi_if.AWVALID),
      .AWREADY(axi_if.AWREADY),

      // Write Data Channel
      .WDATA (axi_if.WDATA),
      .WVALID(axi_if.WVALID),
      .WLAST (axi_if.WLAST),
      .WREADY(axi_if.WREADY),

      // Write Response Channel
      .BRESP (axi_if.BRESP),
      .BVALID(axi_if.BVALID),
      .BREADY(axi_if.BREADY),

      // Read Address Channel
      .ARADDR (axi_if.ARADDR),
      .ARLEN  (axi_if.ARLEN),
      .ARSIZE (axi_if.ARSIZE),
      .ARVALID(axi_if.ARVALID),
      .ARREADY(axi_if.ARREADY),

      // Read Data Channel
      .RDATA (axi_if.RDATA),
      .RRESP (axi_if.RRESP),
      .RVALID(axi_if.RVALID),
      .RLAST (axi_if.RLAST),
      .RREADY(axi_if.RREADY)
  );
  // ----------------------------------------------------------
  // Passive memory tap: drive mem_if from the DUT's own
  // internal mem_en/mem_we/mem_addr/mem_wdata/mem_rdata
  // as the passive agent has to see the real DUT-internal memory activity
  // ----------------------------------------------------------
  assign mem_if.clk       = axi_if.ACLK;
  assign mem_if.rst_n     = axi_if.ARESETn;
  assign mem_if.mem_en    = dut.mem_en;
  assign mem_if.mem_we    = dut.mem_we;
  assign mem_if.mem_addr  = dut.mem_addr;
  assign mem_if.mem_wdata = dut.mem_wdata;
  assign mem_if.mem_rdata = dut.mem_rdata;
  //----------------------------------------------------------
  // Assertions
  //----------------------------------------------------------
  axi4_slave_sva #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .DATA_WIDTH  (DATA_WIDTH),
      .MEMORY_DEPTH(MEMORY_DEPTH)
  ) u_axi4_sva (
      .ACLK   (axi_if.ACLK),
      .ARESETn(axi_if.ARESETn),
      .AWADDR (axi_if.AWADDR),
      .AWLEN  (axi_if.AWLEN),
      .AWSIZE (axi_if.AWSIZE),
      .AWVALID(axi_if.AWVALID),
      .AWREADY(axi_if.AWREADY),
      .WDATA  (axi_if.WDATA),
      .WVALID (axi_if.WVALID),
      .WLAST  (axi_if.WLAST),
      .WREADY (axi_if.WREADY),
      .BRESP  (axi_if.BRESP),
      .BVALID (axi_if.BVALID),
      .BREADY (axi_if.BREADY),
      .ARADDR (axi_if.ARADDR),
      .ARLEN  (axi_if.ARLEN),
      .ARSIZE (axi_if.ARSIZE),
      .ARVALID(axi_if.ARVALID),
      .ARREADY(axi_if.ARREADY),
      .RDATA  (axi_if.RDATA),
      .RRESP  (axi_if.RRESP),
      .RVALID (axi_if.RVALID),
      .RLAST  (axi_if.RLAST),
      .RREADY (axi_if.RREADY)
  );

  // ==========================================================
  // UVM CONFIGURATION + TEST
  // ==========================================================
  initial begin
    // --------------------------------------------------------
    // Configure AXI agent as ACTIVE
    // --------------------------------------------------------
    uvm_config_db#(uvm_active_passive_enum)::set(null, "uvm_test_top.env.agt", "is_active",
                                                 UVM_ACTIVE);
    // --------------------------------------------------------
    // Configure MEM agent as ACTIVE
    // --------------------------------------------------------
    uvm_config_db#(uvm_active_passive_enum)::set(null, "uvm_test_top.env.agt2", "is_active",
                                                 UVM_PASSIVE);

    // --------------------------------------------------------
    // Pass virtual interface to the agents
    // --------------------------------------------------------
    uvm_config_db#(virtual axi_if.TB)::set(null, "uvm_test_top.env.agt.*", "drv_if", axi_if.TB);
    uvm_config_db#(virtual axi_if.MON)::set(null, "uvm_test_top.env.agt.*", "mon_if", axi_if.MON);

    uvm_config_db#(virtual mem_if.MON)::set(null, "uvm_test_top.env.agt2.*", "mon_if", mem_if.MON);

    // --------------------------------------------------------
    // Start UVM test (Controlled by +UVM_TESTNAME=axi_test) in do file
    // --------------------------------------------------------
    run_test("axi_test");
  end

  // ==========================================================
  // VCD DUMP
  // ==========================================================
  initial begin

    $dumpfile("dump.vcd");
    $dumpvars;

  end
endmodule
