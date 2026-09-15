#vivado='alias /opt/Xilinx/Vivado/2017.4/bin/vivado'

echo $vivado
rm -rf ../../results/hw_mapping/fc_area_d4u4.txt
rm -rf ../../results/hw_mapping/fc_freq_d4u4.txt
rm -rf ../../results/hw_mapping/fc_power_d4u4.txt
rm -rf ../../vivado
mkdir ../../vivado
cd ../../vivado
mkdir d4u4_synth
cd d4u4_synth
vivado -mode tcl -s ../../scripts/xilinx/d4u4_synth.tcl