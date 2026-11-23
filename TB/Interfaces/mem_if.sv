interface mem_if #(
    parameter int DATA_WIDTH = 32,
    parameter int MEM_ADDR_WIDTH = 10,
    parameter int DEPTH = 1024
);
  bit rst_n;
  bit clk;
  logic [MEM_ADDR_WIDTH-1:0] mem_addr;
  logic [DATA_WIDTH-1:0] mem_wdata;
  logic [DATA_WIDTH-1:0] mem_rdata;
  bit mem_we;
  bit mem_en;

  modport DUT(
      input clk,
      input rst_n,
      input mem_addr,
      input mem_wdata,
      output mem_rdata,
      input mem_we,
      input mem_en
  );
  modport TB(
      input clk,
      output rst_n,
      output mem_addr,
      output mem_wdata,
      input mem_rdata,
      output mem_we,
      output mem_en
  );
  modport MON(
      input clk,
      input rst_n,
      input mem_addr,
      input mem_wdata,
      input mem_rdata,
      input mem_we,
      input mem_en
  );

endinterface  //mem_interface
