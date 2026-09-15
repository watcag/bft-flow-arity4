run_func_demo:
	@cd scripts/results && \
	sh test.sh 1 ${TOPO} ${PE} ${RATE} ${TRACE} 

run_hw_mapping:
	@cd scripts/xilinx && \
	sh bft_synth.sh 1 ${TOPO} ${PE} ${DW} 
