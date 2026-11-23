module axi4_slave_sva #(
    parameter int ADDR_WIDTH   = 16,
    parameter int DATA_WIDTH   = 32,
    parameter int MEMORY_DEPTH = 1024
) (
    input logic ACLK,
    input logic ARESETn,

    // Write Address Channel
    input logic [ADDR_WIDTH-1:0] AWADDR,
    input logic [           7:0] AWLEN,
    input logic [           2:0] AWSIZE,
    input logic                  AWVALID,
    input logic                  AWREADY,

    // Write Data Channel
    input logic [DATA_WIDTH-1:0] WDATA,
    input logic                  WVALID,
    input logic                  WLAST,
    input logic                  WREADY,

    // Write Response Channel
    input logic [1:0] BRESP,
    input logic       BVALID,
    input logic       BREADY,

    // Read Address Channel
    input logic [ADDR_WIDTH-1:0] ARADDR,
    input logic [           7:0] ARLEN,
    input logic [           2:0] ARSIZE,
    input logic                  ARVALID,
    input logic                  ARREADY,

    // Read Data Channel
    input logic [DATA_WIDTH-1:0] RDATA,
    input logic [           1:0] RRESP,
    input logic                  RVALID,
    input logic                  RLAST,
    input logic                  RREADY
);

  localparam int unsigned MEM_BYTES = MEMORY_DEPTH * 4;  // e.g. 4096 = 0x1000

  default clocking cb @(posedge ACLK);
  endclocking
  default disable iff (!ARESETn);

  // ===========================================================================
  // RESET
  // ===========================================================================

  // Outputs must be reset while the slave is held in reset.
  property p_reset_outputs;
    @(posedge ACLK) (!ARESETn) |-> (!BVALID && !RVALID);
  endproperty
  a_reset_outputs :
  assert property (p_reset_outputs)
  else $error("[SVA][RESET] BVALID/RVALID asserted while ARESETn is low");

  // ===========================================================================
  // GLOBAL X-CHECKS
  // ===========================================================================

  property p_no_x_on_handshake_signals;
    !$isunknown(
        {AWVALID, WVALID, ARVALID, BVALID, RVALID, AWREADY, WREADY, ARREADY, BREADY, RREADY}
    );
  endproperty
  a_no_x_on_handshake_signals :
  assert property (p_no_x_on_handshake_signals)
  else $error("[SVA][X-CHECK] Unknown value on a VALID/READY signal");

  // ===========================================================================
  // WRITE ADDRESS CHANNEL (AW)
  // ===========================================================================

  // once VALID is asserted it must stay high until READY.
  property p_awvalid_stable;
    (AWVALID && !AWREADY) |=> AWVALID;
  endproperty
  a_awvalid_stable :
  assert property (p_awvalid_stable)
  else $error("[SVA][AW] AWVALID dropped before AWREADY handshake");

  // Data and burst configuration must not change while VALID is high and READY is low.
  property p_awaddr_stable;
    (AWVALID && !AWREADY) |=> ($stable(
        AWADDR
    ) && $stable(
        AWLEN
    ) && $stable(
        AWSIZE
    ));
  endproperty
  a_awaddr_stable :
  assert property (p_awaddr_stable)
  else $error("[SVA][AW] AWADDR/AWLEN/AWSIZE changed while AWVALID held with AWREADY low");

  //  word-aligned addresses only, violated some times for negative testing when constraint is disabled
  property p_aw_aligned;
    AWVALID |-> (AWADDR[1:0] == 2'b00);  // divisable by 4
  endproperty
  a_aw_aligned :
  assert property (p_aw_aligned)
  else $error("[SVA][AW] AWADDR is not word-aligned");

  // fixed 32-bit transfers.
  property p_aw_size_fixed;
    AWVALID |-> (AWSIZE == 3'b010);
  endproperty
  a_aw_size_fixed :
  assert property (p_aw_size_fixed)
  else $error("[SVA][AW] AWSIZE is not 3'b010 (32-bit)");

  // ===========================================================================
  //  WRITE DATA CHANNEL (W)
  // ===========================================================================

  property p_wvalid_stable;
    (WVALID && !WREADY) |=> WVALID;
  endproperty
  a_wvalid_stable :
  assert property (p_wvalid_stable)
  else $error("[SVA][W] WVALID dropped before WREADY handshake");

  property p_wdata_stable;
    (WVALID && !WREADY) |=> ($stable(
        WDATA
    ) && $stable(
        WLAST
    ));
  endproperty
  a_wdata_stable :
  assert property (p_wdata_stable)
  else $error("[SVA][W] WDATA/WLAST changed while WVALID held with WREADY low");

  //  Beat counter used to check WLAST placement 
  logic [7:0] w_beat_cnt;
  logic [7:0] w_awlen_q;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      w_beat_cnt <= '0;
      w_awlen_q  <= '0;
    end else begin
      if (AWVALID && AWREADY) w_awlen_q <= AWLEN;  // capture burst length at address phase
      if (WVALID && WREADY) begin
        if (WLAST) w_beat_cnt <= '0;  // burst complete, reset for next one
        else w_beat_cnt <= w_beat_cnt + 8'd1;
      end
    end
  end

  // WLAST must be high exactly on the beat where the counter reaches AWLEN.
  property p_wlast_correct;
    (WVALID && WREADY) |-> (WLAST == (w_beat_cnt == w_awlen_q));
  endproperty
  a_wlast_correct :
  assert property (p_wlast_correct)
  else $error("[SVA][W] WLAST asserted on the wrong beat of the write burst");

  // ===========================================================================
  // WRITE RESPONSE CHANNEL (B)
  // ===========================================================================

  property p_bvalid_stable;
    (BVALID && !BREADY) |=> BVALID;
  endproperty
  a_bvalid_stable :
  assert property (p_bvalid_stable)
  else $error("[SVA][B] BVALID dropped before BREADY handshake");

  property p_bresp_legal;
    BVALID |-> (BRESP == 2'b00 || BRESP == 2'b10);  // OKAY or SLVERR only
  endproperty
  a_bresp_legal :
  assert property (p_bresp_legal)
  else $error("[SVA][B] BRESP is neither OKAY nor SLVERR");
  // =============================================
  // BVALID must not appear before the write burst's last data beat
  // has actually been accepted.
  logic b_pending;
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) b_pending <= 1'b0;
    else if (WVALID && WREADY && WLAST) b_pending <= 1'b1;
    else if (BVALID && BREADY) b_pending <= 1'b0;
  end

  property p_bvalid_ordering;
    BVALID |-> b_pending;
  endproperty
  a_bvalid_ordering :
  assert property (p_bvalid_ordering)
  else $error("[SVA][B] BVALID asserted before the write burst's WLAST beat completed");

  // ===========================================================================
  //  READ ADDRESS CHANNEL (AR) -- Similar to the the AW checks
  // ===========================================================================

  property p_arvalid_stable;
    (ARVALID && !ARREADY) |=> ARVALID;
  endproperty
  a_arvalid_stable :
  assert property (p_arvalid_stable)
  else $error("[SVA][AR] ARVALID dropped before ARREADY handshake");

  property p_araddr_stable;
    (ARVALID && !ARREADY) |=> ($stable(
        ARADDR
    ) && $stable(
        ARLEN
    ) && $stable(
        ARSIZE
    ));
  endproperty
  a_araddr_stable :
  assert property (p_araddr_stable)
  else $error("[SVA][AR] ARADDR/ARLEN/ARSIZE changed while ARVALID held with ARREADY low");

  property p_ar_aligned;
    ARVALID |-> (ARADDR[1:0] == 2'b00);
  endproperty
  a_ar_aligned :
  assert property (p_ar_aligned)
  else $error("[SVA][AR] ARADDR is not word-aligned");

  property p_ar_size_fixed;
    ARVALID |-> (ARSIZE == 3'b010);
  endproperty
  a_ar_size_fixed :
  assert property (p_ar_size_fixed)
  else $error("[SVA][AR] ARSIZE is not 3'b010 (32-bit)");

  // ===========================================================================
  //  READ DATA CHANNEL (R)
  // ===========================================================================

  property p_rvalid_stable;
    (RVALID && !RREADY) |=> RVALID;
  endproperty
  a_rvalid_stable :
  assert property (p_rvalid_stable)
  else $error("[SVA][R] RVALID dropped before RREADY handshake");

  property p_rdata_stable;
    (RVALID && !RREADY) |=> ($stable(
        RDATA
    ) && $stable(
        RRESP
    ) && $stable(
        RLAST
    ));
  endproperty
  a_rdata_stable :
  assert property (p_rdata_stable)
  else $error("[SVA][R] RDATA/RRESP/RLAST changed while RVALID held with RREADY low");

  property p_rresp_legal;
    RVALID |-> (RRESP == 2'b00 || RRESP == 2'b10);
  endproperty
  a_rresp_legal :
  assert property (p_rresp_legal)
  else $error("[SVA][R] RRESP is neither OKAY nor SLVERR");

  // Beat counter for RLAST 
  logic [7:0] r_beat_cnt;
  logic [7:0] r_arlen_q;

  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      r_beat_cnt <= '0;
      r_arlen_q  <= '0;
    end else begin
      if (ARVALID && ARREADY) r_arlen_q <= ARLEN;
      if (RVALID && RREADY) begin
        if (RLAST) r_beat_cnt <= '0;
        else r_beat_cnt <= r_beat_cnt + 8'd1;
      end
    end
  end

  property p_rlast_correct;
    (RVALID && RREADY) |-> (RLAST == (r_beat_cnt == r_arlen_q));
  endproperty
  a_rlast_correct :
  assert property (p_rlast_correct)
  else $error("[SVA][R] RLAST asserted on the wrong beat of the read burst");

  // Ordering: no read data before the address phase has been accepted.
  logic r_pending;
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) r_pending <= 1'b0;
    else if (ARVALID && ARREADY) r_pending <= 1'b1;
    else if (RVALID && RREADY && RLAST) r_pending <= 1'b0;
  end

  property p_rvalid_ordering;
    RVALID |-> r_pending;
  endproperty
  a_rvalid_ordering :
  assert property (p_rvalid_ordering)
  else $error("[SVA][R] RVALID asserted before the read address phase completed");

  // Illegal reads must return zero data on every beat.
  property p_rdata_zero_on_slverr;
    (RVALID && (RRESP == 2'b10)) |-> (RDATA == '0);
  endproperty
  a_rdata_zero_on_slverr :
  assert property (p_rdata_zero_on_slverr)
  else $error("[SVA][R] RDATA is non-zero on an SLVERR read beat");

endmodule
