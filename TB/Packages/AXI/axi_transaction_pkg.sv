package axi_transaction_pkg;

  import uvm_pkg::*;
  import parameters_pkg::*;

  `include "uvm_macros.svh"

  class axi_transaction extends uvm_sequence_item;

    //==========================================================
    // Global
    //==========================================================
    rand bit                           ARESETn;

    //==========================================================
    // Write Address Channel
    //==========================================================
    rand logic        [ADDR_WIDTH-1:0] AWADDR;
    rand logic        [           7:0] AWLEN;
    rand logic        [           2:0] AWSIZE;
    // Asserted when address is valid
    logic                              AWVALID;
    // Slave
    logic                              AWREADY;

    //==========================================================
    // Write Data Channel
    //==========================================================
    // Dynamic array to hold beats
    rand logic        [DATA_WIDTH-1:0] WDATA            [];
    // Asserted when data is valid
    logic                              WVALID;
    // Asserted when with the last beat in a burst
    logic                              WLAST;
    // Slave
    logic                              WREADY;

    //==========================================================
    // Write Response Channel
    //==========================================================
    logic             [           1:0] BRESP;  // Slave
    logic                              BVALID;  // Slave
    // Wait on BVALID
    logic                              BREADY;

    //==========================================================
    // Read Address Channel
    //==========================================================
    // Similarly as write channel
    rand logic        [ADDR_WIDTH-1:0] ARADDR;
    rand logic        [           7:0] ARLEN;
    rand logic        [           2:0] ARSIZE;
    logic                              ARVALID;
    logic                              ARREADY;

    //==========================================================
    // Read Data Channel
    //==========================================================
    // Dynamic array to hold beats
    logic             [DATA_WIDTH-1:0] RDATA            [];
    logic             [           1:0] RRESP;
    logic                              RVALID;
    logic                              RLAST;
    logic                              RREADY;

    // Random Delay before asserting ready signals
    rand int unsigned                  bready_delay;
    rand int unsigned                  rready_delay;
    rand int unsigned                  wvalid_delay;

    // Expected respose
    logic             [           1:0] expected_bresp;
    logic             [           1:0] expected_rresp;

    // Operation Write or Read
    rand operation_t                   op;

    // Unique identifier assigned by the monitor when a transaction is
    // captured off the bus. Used by the scoreboard to key its failure log.
    int unsigned                       trans_id;

    // ==========================================================
    // Factory Registration and Field Automation
    // ==========================================================
    `uvm_object_utils_begin(axi_transaction)

    // ==========================================================
    // Global
    // ==========================================================
      `uvm_field_int(ARESETn, UVM_DEFAULT)

    // ==========================================================
    // Write Address Channel
    // ==========================================================
      `uvm_field_int(AWADDR, UVM_DEFAULT)
      `uvm_field_int(AWLEN, UVM_DEFAULT)
      `uvm_field_int(AWSIZE, UVM_DEFAULT)
      `uvm_field_int(AWVALID, UVM_DEFAULT)
      `uvm_field_int(AWREADY, UVM_DEFAULT)

    // ==========================================================
    // Write Data Channel
    // ==========================================================
    //  The array field macro for the dynamic array
      `uvm_field_array_int(WDATA, UVM_DEFAULT)
      `uvm_field_int(WVALID, UVM_DEFAULT)
      `uvm_field_int(WLAST, UVM_DEFAULT)
      `uvm_field_int(WREADY, UVM_DEFAULT)

    // ==========================================================
    // Write Response Channel
    // ==========================================================
      `uvm_field_int(BRESP, UVM_DEFAULT)
      `uvm_field_int(BVALID, UVM_DEFAULT)
      `uvm_field_int(BREADY, UVM_DEFAULT)

    // ==========================================================
    // Read Address Channel
    // ==========================================================
      `uvm_field_int(ARADDR, UVM_DEFAULT)
      `uvm_field_int(ARLEN, UVM_DEFAULT)
      `uvm_field_int(ARSIZE, UVM_DEFAULT)
      `uvm_field_int(ARVALID, UVM_DEFAULT)
      `uvm_field_int(ARREADY, UVM_DEFAULT)

    // ==========================================================
    // Read Data Channel
    // ==========================================================
    //  The array field macro for the dynamic array
      `uvm_field_array_int(RDATA, UVM_DEFAULT)
      `uvm_field_int(RRESP, UVM_DEFAULT)
      `uvm_field_int(RVALID, UVM_DEFAULT)
      `uvm_field_int(RLAST, UVM_DEFAULT)
      `uvm_field_int(RREADY, UVM_DEFAULT)

    // ==========================================================
    // Random Delays
    // ==========================================================
      `uvm_field_int(bready_delay, UVM_DEFAULT)
      `uvm_field_int(rready_delay, UVM_DEFAULT)
      `uvm_field_int(wvalid_delay, UVM_DEFAULT)

    // ==========================================================
    // Expected Responses
    // ==========================================================
      `uvm_field_int(expected_bresp, UVM_DEFAULT)
      `uvm_field_int(expected_rresp, UVM_DEFAULT)

    // ==========================================================
    // Operation Type
    // ==========================================================
    // ENUM field macro for the operation type `uvm_field_enum(type, name, mode)
      `uvm_field_enum(operation_t, op, UVM_DEFAULT)
      `uvm_field_int(trans_id, UVM_DEFAULT)

    `uvm_object_utils_end

    function new(string name = "axi_transaction");
      super.new(name);
      // Initialization
      //----------------------------------------------------------
      // Global
      //----------------------------------------------------------
      ARESETn = 1'b1;

      //----------------------------------------------------------
      // Write Address Channel
      //----------------------------------------------------------
      AWVALID = 1'b0;
      AWREADY = 1'b0;

      //----------------------------------------------------------
      // Write Data Channel
      //----------------------------------------------------------
      WVALID = 1'b0;
      WLAST = 1'b0;
      WREADY = 1'b0;

      WDATA = new[0];

      //----------------------------------------------------------
      // Write Response Channel
      //----------------------------------------------------------
      BRESP = 2'b00;
      BVALID = 1'b0;
      BREADY = 1'b1;

      expected_bresp = 2'b00;

      //----------------------------------------------------------
      // Read Address Channel
      //----------------------------------------------------------
      ARVALID = 1'b0;
      ARREADY = 1'b0;

      //----------------------------------------------------------
      // Read Data Channel
      //----------------------------------------------------------
      RDATA = new[0];

      RRESP = 2'b00;
      RVALID = 1'b0;
      RLAST = 1'b0;
      RREADY = 1'b1;

      expected_rresp = 2'b00;

      //----------------------------------------------------------
      // Delays
      //----------------------------------------------------------
      bready_delay = 0;
      rready_delay = 0;
      wvalid_delay = 0;
    endfunction  // new()

    //==========================================================
    // Constraints
    //==========================================================

    // Reset is asserted rarely
    constraint reset_c {
      ARESETn dist {
        1 :/ 98,
        0 :/ 2
      };
    }
    ;

    // Size of word fixed = 4 bytes, Only 32-bit transfers
    constraint size_c {
      AWSIZE == 3'b010;
      ARSIZE == 3'b010;
    }
    ;
    constraint op_c {
      soft op dist {
        WRITE :/ 60,
        READ  :/ 40
      };
    }
    ;
    // Address should be divisable by four , sO ADD mod 4 = 0 equivalently least 2 significant bits = 0
    // Word aligned addresses
    constraint alignment_c {
      /*
                 AWADDR % 4 == 0;
                 ARADDR % 4 == 0;
                 */

      AWADDR[1:0] == 2'b00;
      ARADDR[1:0] == 2'b00;
    }
    ;

    // Ready or Write comes in a 5 cycle window
    constraint ready_valid_delay_c {
      bready_delay inside {[0 : 5]};
      rready_delay inside {[0 : 5]};
      wvalid_delay dist {
        0 :/ 90,
        [1 : 5] :/ 10
      };
    }
    ;

    // Burst lengths (1-16 beats)
    constraint len_dist_c {
      soft AWLEN dist {
        0 :/ 23,
        [1 : 5] :/ 75,
        [6 : $] :/ 2
      };

      soft ARLEN dist {
        0 :/ 23,
        [1 : 5] :/ 75,
        [6 : $] :/ 2
      };
    }


    // Dynamic array size, One data word per beat
    constraint data_size_c {WDATA.size() == AWLEN + 1;}
    ;
    // check address is within allowed range [0:1023]
    // start add + number of beats (address increments) should be < 1024
    // Legal memory accesses
    constraint memory_range_c {
      (AWADDR >> 2) + AWLEN < MEMORY_DEPTH;
      (ARADDR >> 2) + ARLEN < MEMORY_DEPTH;
    }


    // Prevent crossing a 4KB boundary
    constraint boundary_c {
      // Mask 16'h0FFF to know where am i in the current page ,
      //then add the total number of bytes (#beats * 4) of the burst and check that we do not exceed page (4096 byte)
      ((AWADDR & 16'h0FFF) + ((AWLEN + 1) << AWSIZE)) <= 16'h1000;

      ((ARADDR & 16'h0FFF) + ((ARLEN + 1) << ARSIZE)) <= 16'h1000;
    }


    // Master is usually ready
    constraint ready_c {
      BREADY dist {
        1 :/ 95,
        0 :/ 5
      };
      RREADY dist {
        1 :/ 95,
        0 :/ 5
      };
    }
  endclass  // axi_transaction
endpackage

