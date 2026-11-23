onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Global /axi_top/axi_if/ACLK
add wave -noupdate -expand -group Global /axi_top/axi_if/ARESETn
add wave -noupdate -expand -group DUT -group {Write Address Ch} /axi_top/dut/AWADDR
add wave -noupdate -expand -group DUT -group {Write Address Ch} /axi_top/dut/AWLEN
add wave -noupdate -expand -group DUT -group {Write Address Ch} /axi_top/dut/AWSIZE
add wave -noupdate -expand -group DUT -group {Write Address Ch} /axi_top/dut/AWVALID
add wave -noupdate -expand -group DUT -group {Write Address Ch} /axi_top/dut/AWREADY
add wave -noupdate -expand -group DUT -group {Write Data ch} /axi_top/dut/WDATA
add wave -noupdate -expand -group DUT -group {Write Data ch} /axi_top/dut/WVALID
add wave -noupdate -expand -group DUT -group {Write Data ch} /axi_top/dut/WLAST
add wave -noupdate -expand -group DUT -group {Write Data ch} /axi_top/dut/WREADY
add wave -noupdate -expand -group DUT -group {Write Response ch} /axi_top/dut/BRESP
add wave -noupdate -expand -group DUT -group {Write Response ch} /axi_top/dut/BVALID
add wave -noupdate -expand -group DUT -group {Write Response ch} /axi_top/dut/BREADY
add wave -noupdate -expand -group DUT -group {Read Address ch} /axi_top/dut/ARADDR
add wave -noupdate -expand -group DUT -group {Read Address ch} /axi_top/dut/ARLEN
add wave -noupdate -expand -group DUT -group {Read Address ch} /axi_top/dut/ARSIZE
add wave -noupdate -expand -group DUT -group {Read Address ch} /axi_top/dut/ARVALID
add wave -noupdate -expand -group DUT -group {Read Address ch} /axi_top/dut/ARREADY
add wave -noupdate -expand -group DUT -group {Read Data ch} /axi_top/dut/RDATA
add wave -noupdate -expand -group DUT -group {Read Data ch} /axi_top/dut/RRESP
add wave -noupdate -expand -group DUT -group {Read Data ch} /axi_top/dut/RVALID
add wave -noupdate -expand -group DUT -group {Read Data ch} /axi_top/dut/RLAST
add wave -noupdate -expand -group DUT -group {Read Data ch} /axi_top/dut/RREADY
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/mem_en
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/mem_we
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/mem_addr
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/mem_wdata
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/mem_rdata
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/write_addr
add wave -noupdate -expand -group DUT -group Memory /axi_top/dut/read_addr
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_burst_len
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_burst_len
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_burst_cnt
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_burst_cnt
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_size
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_size
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_addr_incr
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_addr_incr
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_addr_valid_reg
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_boundary_cross_reg
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_addr_valid_reg
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_boundary_cross_reg
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_boundary_cross
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_boundary_cross
add wave -noupdate -expand -group DUT -group control /axi_top/dut/write_addr_valid
add wave -noupdate -expand -group DUT -group control /axi_top/dut/read_addr_valid
add wave -noupdate -expand -group DUT /axi_top/dut/write_state
add wave -noupdate -expand -group DUT /axi_top/dut/read_state
add wave -noupdate -expand -group DUT /axi_top/dut/mem_rdata_reg
add wave -noupdate -group IF /axi_top/axi_if/AWADDR
add wave -noupdate -group IF /axi_top/axi_if/AWLEN
add wave -noupdate -group IF /axi_top/axi_if/AWSIZE
add wave -noupdate -group IF /axi_top/axi_if/AWVALID
add wave -noupdate -group IF /axi_top/axi_if/AWREADY
add wave -noupdate -group IF /axi_top/axi_if/WDATA
add wave -noupdate -group IF /axi_top/axi_if/WVALID
add wave -noupdate -group IF /axi_top/axi_if/WLAST
add wave -noupdate -group IF /axi_top/axi_if/WREADY
add wave -noupdate -group IF /axi_top/axi_if/BRESP
add wave -noupdate -group IF /axi_top/axi_if/BVALID
add wave -noupdate -group IF /axi_top/axi_if/BREADY
add wave -noupdate -group IF /axi_top/axi_if/ARADDR
add wave -noupdate -group IF /axi_top/axi_if/ARLEN
add wave -noupdate -group IF /axi_top/axi_if/ARSIZE
add wave -noupdate -group IF /axi_top/axi_if/ARVALID
add wave -noupdate -group IF /axi_top/axi_if/ARREADY
add wave -noupdate -group IF /axi_top/axi_if/RDATA
add wave -noupdate -group IF /axi_top/axi_if/RRESP
add wave -noupdate -group IF /axi_top/axi_if/RVALID
add wave -noupdate -group IF /axi_top/axi_if/RLAST
add wave -noupdate -group IF /axi_top/axi_if/RREADY
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {60835430 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {55806415 ns} {88574415 ns}
