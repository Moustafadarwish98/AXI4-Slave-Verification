interface axi_if #(
    parameter int DATA_WIDTH   = 32,
    parameter int ADDR_WIDTH   = 16,
    parameter int MEMORY_DEPTH = 1024
);

  //==================================================
  // Global Signals
  //==================================================
  logic                  ACLK;
  logic                  ARESETn;

  //==================================================
  // Write Address Channel
  //==================================================
  logic [ADDR_WIDTH-1:0] AWADDR;
  logic [           7:0] AWLEN;
  logic [           2:0] AWSIZE;
  logic                  AWVALID;
  logic                  AWREADY;

  //==================================================
  // Write Data Channel
  //==================================================
  logic [DATA_WIDTH-1:0] WDATA;
  logic                  WVALID;
  logic                  WLAST;
  logic                  WREADY;

  //==================================================
  // Write Response Channel
  //==================================================
  logic [           1:0] BRESP;
  logic                  BVALID;
  logic                  BREADY;

  //==================================================
  // Read Address Channel
  //==================================================
  logic [ADDR_WIDTH-1:0] ARADDR;
  logic [           7:0] ARLEN;
  logic [           2:0] ARSIZE;
  logic                  ARVALID;
  logic                  ARREADY;

  //==================================================
  // Read Data Channel
  //==================================================
  logic [DATA_WIDTH-1:0] RDATA;
  logic [           1:0] RRESP;
  logic                  RVALID;
  logic                  RLAST;
  logic                  RREADY;

  //==================================================
  // DUT Modport
  //==================================================
  modport DUT(
      input ACLK,
      input ARESETn,

      input AWADDR,
      input AWLEN,
      input AWSIZE,
      input AWVALID,
      output AWREADY,

      input WDATA,
      input WVALID,
      input WLAST,
      output WREADY,

      output BRESP,
      output BVALID,
      input BREADY,

      input ARADDR,
      input ARLEN,
      input ARSIZE,
      input ARVALID,
      output ARREADY,

      output RDATA,
      output RRESP,
      output RVALID,
      output RLAST,
      input RREADY
  );

  //==================================================
  // Testbench Driver Modport
  //==================================================
  modport TB(
      input ACLK,

      output ARESETn,

      output AWADDR,
      output AWLEN,
      output AWSIZE,
      output AWVALID,
      input AWREADY,

      output WDATA,
      output WVALID,
      output WLAST,
      input WREADY,

      input BRESP,
      input BVALID,
      output BREADY,

      output ARADDR,
      output ARLEN,
      output ARSIZE,
      output ARVALID,
      input ARREADY,

      input RDATA,
      input RRESP,
      input RVALID,
      input RLAST,
      output RREADY
  );

  //==================================================
  // Monitor Modport
  //==================================================
  modport MON(
      input ACLK,
      input ARESETn,

      input AWADDR,
      input AWLEN,
      input AWSIZE,
      input AWVALID,
      input AWREADY,

      input WDATA,
      input WVALID,
      input WLAST,
      input WREADY,

      input BRESP,
      input BVALID,
      input BREADY,

      input ARADDR,
      input ARLEN,
      input ARSIZE,
      input ARVALID,
      input ARREADY,

      input RDATA,
      input RRESP,
      input RVALID,
      input RLAST,
      input RREADY
  );

endinterface
