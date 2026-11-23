package axi_sequence_pkg;

  import uvm_pkg::*;

  import axi_transaction_pkg::*;
  import parameters_pkg::*;

  `include "uvm_macros.svh"

  class axi_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
      super.new(name);
      `uvm_info(get_type_name(), "Inside new sequence class", UVM_LOW)
    endfunction

    // called when test does seq.start(sequencer)
    // it is a task as it can consume simulation time , for example the UVM transaction synchronization mechanisim
    // start_item and finish_item
    task body();
      // Define the tansaction handle
      axi_transaction trans;

      // Sequences generated loop
      repeat (20000) begin
        // Create the transaction
        trans = axi_transaction::type_id::create("trans");

        // Start the sequence this tells the sequencer that the sequence is going to start a sequence item,
        // it coordinates the path between the sequencer and the driver
        start_item(trans);

        if ($urandom_range(0, 99) < 10) begin
          // -----------------------------------------------
          // 10% illegal transactions
          // -----------------------------------------------
          trans.memory_range_c.constraint_mode(0);
          trans.boundary_c.constraint_mode(0);

          case ($urandom_range(
              0, 3
          ))
            0: begin  // illegal WRITE, medium/long
              assert (trans.randomize() with {
                op == WRITE;
                AWLEN inside {[4 : 15]};
                AWADDR inside {[16'h0FF0 : 16'h1000]};
              })
              else `uvm_fatal("SEQ", "Illegal WRITE (long) randomization failed")
            end
            1: begin  // illegal READ, medium/long
              assert (trans.randomize() with {
                op == READ;
                ARLEN inside {[4 : 15]};
                ARADDR inside {[16'h0FF0 : 16'h1000]};
              })
              else `uvm_fatal("SEQ", "Illegal READ (long) randomization failed")
            end
            2: begin  // illegal WRITE, single/short
              assert (trans.randomize() with {
                op == WRITE;
                AWLEN inside {[0 : 3]};
                AWADDR inside {[16'h1000 : 16'hFFFC]};  // outside memory -> always illegal
              })
              else `uvm_fatal("SEQ", "Illegal WRITE (short) randomization failed")
            end
            3: begin  // illegal READ, single/short
              assert (trans.randomize() with {
                op == READ;
                ARLEN inside {[0 : 3]};
                ARADDR inside {[16'h1000 : 16'hFFFC]};
              })
              else `uvm_fatal("SEQ", "Illegal READ (short) randomization failed")
            end
            default: begin
              `uvm_fatal("SEQ", "Illegal transaction randomization failed")
            end
          endcase
          trans.memory_range_c.constraint_mode(1);
          trans.boundary_c.constraint_mode(1);
        end else begin
          // -----------------------------------------------
          // 90% legal transactions
          // -----------------------------------------------
          assert (trans.randomize())
          else `uvm_fatal("SEQ", "Randomization failed")
        end
        finish_item(trans);
        // ======================================================
        // DIRECTED DATA-EXTREME INJECTION
        // Closes mem_cg gaps: cp_wdata::zero/ones and cp_rdata::ones.
        // WDATA is unconstrained per-beat, so hitting exactly 0x0 or
        // 0xFFFFFFFF by chance is effectively never going to happen
        // under pure randomization -- these three items force it.
        // ======================================================

        // Directed WRITE: WDATA all-zero
        trans = axi_transaction::type_id::create("trans_wdata_zero");
        start_item(trans);
        assert (trans.randomize() with {
          op == WRITE;
          AWLEN == 0;
          AWADDR == 16'h0020;
          WDATA[0] == 32'h0000_0000;
        })
        else `uvm_fatal("SEQ", "Directed WDATA=0 WRITE randomization failed")
        finish_item(trans);

        // Directed WRITE: WDATA all-ones
        trans = axi_transaction::type_id::create("trans_wdata_ones");
        start_item(trans);
        assert (trans.randomize() with {
          op == WRITE;
          AWLEN == 0;
          AWADDR == 16'h0024;
          WDATA[0] == 32'hFFFF_FFFF;
        })
        else `uvm_fatal("SEQ", "Directed WDATA=1s WRITE randomization failed")
        finish_item(trans);

        // Directed READ-back of the all-ones address -- closes cp_rdata::bin ones.
        // Must target the exact address just written above
        trans = axi_transaction::type_id::create("trans_rdata_ones_readback");
        start_item(trans);
        assert (trans.randomize() with {
          op == READ;
          ARLEN == 0;
          ARADDR == 16'h0024;
        })
        else `uvm_fatal("SEQ", "Directed read-back randomization failed")
        finish_item(trans);
      end

      // ======================================================
      // OTHER STYLES
      // ======================================================
      //
      // UVM provides macros that can simplify the
      // start_item/randomize/finish_item process.
      //
      // `uvm_do(trans);
      //
      // is a shorthand-style mechanism for creating and
      // sending a sequence item.
      //
      // `uvm_do_with(trans, {a == 'd10})
      //
      // allows additional inline constraints to be applied
      // when generating the transaction.
      //
      // ======================================================

      /*
        // OTHER STYLES
        `uvm_do(trans);
        //`uvm_do_with(trans, {a == 'd10})
        `uvm_info(get_type_name(), "DATA Randomized", UVM_LOW)
        */

    endtask
  endclass
endpackage

