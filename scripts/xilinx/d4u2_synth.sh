#vivado='alias /opt/Xilinx/Vivado/2017.4/bin/vivado'

echo $vivado
rm -rf ../../results/hw_mapping/fc_area_d4u2.txt
rm -rf ../../results/hw_mapping/fc_freq_d4u2.txt
rm -rf ../../results/hw_mapping/fc_power_d4u2.txt
rm -rf ../../vivado
mkdir ../../vivado
cd ../../vivado
mkdir d4u2_synth
cd d4u2_synth
vivado -mode tcl -s ../../scripts/xilinx/d4u2_synth.tcl