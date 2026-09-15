#!/bin/zsh

TOPO=$2
CLIENTS=$3
DW=$4
#vivado='alias /opt/Xilinx/Vivado/2017.4/bin/vivado'
if [ "$TOPO" = "BFT0" ]; then
    TOPO_bp=TREE
elif [ "$TOPO" = "BFT1" ]; then
    TOPO_bp=MESH0
elif [ "$TOPO" = "BFT2" ]; then
    TOPO_bp=MESH1
elif [ "$TOPO" = "BFT3" ]; then
    TOPO_bp=XBAR
fi
echo "create_clock -period 1.000 -name clk -waveform {0.000 0.5} [get_ports clk]" > top.xdc

rm -rf ../../results/hw_mapping/fc4_bft4_area.*
rm -rf ../../results/hw_mapping/fc4_bft4_freq.*
rm -rf ../../results/hw_mapping/fc4_bft4_power.*

rm -rf ../../vivado
mkdir ../../vivado
cd ../../vivado
mkdir bft4
cd bft4
rm -rf *		
sed -i "6s?.*?parameter\ D_W=${DW},?" ../../rtl/bft4_synth.sv
echo "create_project TOP -part xcvu9p-flga2104-3-e" > test.tcl
echo "add_files -norecurse {../../rtl/bft4_synth.sv ../../rtl/mux.v ../../rtl/rr_arbiter.v ../../rtl/encoder.v ../../rtl/bp.v }" >> test.tcl
echo "add_files -norecurse { ../../includes/commands.h ../../includes/mux.h ../../includes/system.h}" >> test.tcl
echo "add_files -norecurse { ../../rtl/d4u4_switch_top.sv ../../rtl/d4u4_route.sv ../../rtl/d4u4_switch.sv}" >> test.tcl
echo "add_files -norecurse { ../../rtl/d4u2_switch_top.sv ../../rtl/d4u2_route.sv ../../rtl/d4u2_switch.sv}" >> test.tcl
echo "add_files -norecurse { ../../rtl/d4u1_switch_top.sv ../../rtl/d4u1_route.sv ../../rtl/d4u1_switch.sv}" >> test.tcl
echo "add_files -fileset constrs_1 -norecurse ../../scripts/xilinx/top.xdc" >> test.tcl
echo "set_property verilog_define $TOPO_bp [current_fileset]" >> test.tcl
echo "update_compile_order -fileset sources_1" >> test.tcl
echo "update_compile_order -fileset sim_1" >> test.tcl
echo "set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-generic N=$CLIENTS D_W=$DW} -objects [get_runs synth_1]" >> test.tcl
echo "synth_design -generic N=$CLIENTS -generic D_W=$DW -mode out_of_context" >> test.tcl
echo "opt_design" >> test.tcl
echo "place_design" >> test.tcl
echo "route_design" >> test.tcl
echo "report_utilization -file ../../results/hw_mapping/fc4_${TOPO}_area_$CLIENTS.txt" >> test.tcl
echo "report_timing_summary -file ../../results/hw_mapping/fc4_${TOPO}_freq_$CLIENTS.txt" >> test.tcl
for SA in 10 20 30 40 50 100
do
	echo "set_switching_activity -static_probability 0.5 -toggle_rate $SA [get_nets *]" >> test.tcl
	echo "report_power -file ../../results/hw_mapping/fc4_${TOPO}_power_${CLIENTS}_sa_${SA}.txt" >> test.tcl
done
echo "exit" >> test.tcl 
/opt/Xilinx/Vivado/2019.1/bin/vivado -mode tcl -s test.tcl #> /dev/null
cd ../../results/hw_mapping/
slack=$(awk '/Design\ Timing\ Summary/{getline; getline; getline;getline;getline;getline;print;exit}' fc4_${TOPO}_freq_$CLIENTS.txt |awk '{print $1}') #'{print N=$CLIENTS,TOPO=$TOPO,SLACK=$1}'
luts=$(awk '/CLB\ LUTs/{print;exit}' fc4_${TOPO}_area_$CLIENTS.txt | cut -d"|" -f 3 | awk '{print $1}')
ffs=$(awk '/Register\ as\ Flip\ Flop/{print;exit}' fc4_${TOPO}_area_$CLIENTS.txt | cut -d"|" -f 3 | awk '{print $1}')
mux7=$(awk '/F7\ Muxes/{print;exit}' fc4_${TOPO}_area_$CLIENTS.txt | cut -d"|" -f 3 | awk '{print $1}')
mux8=$(awk '/F8\ Muxes/{print;exit}' fc4_${TOPO}_area_$CLIENTS.txt | cut -d"|" -f 3 | awk '{print $1}')

slack=$(echo $slack - 1 | bc)
cp=$(echo 1000/"(-1*${slack})" | bc)
#rm fc4_${TOPO}_freq_${CLIENTS}.txt
echo "N=$CLIENTS,TOPO=$TOPO,dw=$DW,slack=$slack" >> fc4_bft4_freq.txt
echo "fc4_$TOPO,$CLIENTS,$DW,$slack" >> freq_sweep.csv
#rm fc4_${TOPO}_area_${CLIENTS}.txt
echo "N=$CLIENTS,TOPO=$TOPO,dw=$DW,luts=$luts,ffs=$ffs" >> fc4_bft4_area.txt
echo "fc4_$TOPO,$CLIENTS,$DW,$luts,$ffs" >> area_sweep.csv
echo "*****************************"
echo "Topology=$TOPO, PE=$CLIENTS, DW=$DW"
echo "*****************************"
echo "Achievable Frequency (MHz) = $cp"
echo "FPGA LUTs Consumed = $luts"
echo "FPGA Flip Flops Consumed = $ffs"
echo "Mux 7 = $mux7"
echo "Mux 8 = $mux8"
for SA in 10 20 30 40 50 100
do
	total=$(awk '/Total\ On-Chip\ Power/{print;exit}' fc4_${TOPO}_power_${CLIENTS}_sa_${SA}.txt | cut -d "|" -f 3 | awk '{print $1}')
	dynamic=$(awk '/Dynamic\ \(W\)/{print;exit}' fc4_${TOPO}_power_${CLIENTS}_sa_${SA}.txt | cut -d "|" -f 3 | awk '{print $1}')
	#rm fc4_${TOPO}_power_${CLIENTS}_sa_${SA}.txt
	echo "N=$CLIENTS,TOPO=fc4_$TOPO,dw=$DW,SA=$SA,DYNAMIC=$dynamic,TOTAL=$total" >> fc4_bft4_power.txt
	echo "$CLIENTS,fc4_$TOPO,$DW,$SA,$dynamic,$total" >> power_sweep.csv
	echo "Total Power (W) = $total Dynamic Power (W) = $dynamic (rate=$SA)"
done
