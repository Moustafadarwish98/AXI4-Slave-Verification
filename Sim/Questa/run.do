transcript file simulation_transcript.txt

vlog -f files.txt +cover -covercells

vsim -voptargs=+acc -sv_seed random work.axi_top +UVM_TESTNAME=axi_test -cover
#vsim -voptargs=+acc -sv_seed random work.axi_top +UVM_TESTNAME=axi_test_driver_delay -cover

coverage save -onexit cov.ucdb

#do wave.do

run -all

quit -sim

vcover report -details -cvg cov.ucdb > functional_coverage.txt
vcover report -details -instance /axi_top/dut -codeAll cov.ucdb > dut_code_coverage.txt
vcover report -details -instance /axi_top/dut/mem_inst -codeAll cov.ucdb > mem_code_coverage.txt

coverage open cov.ucdb

quit