
#############
TOPO=$2
N=$3
RATE=$4
PAT=$5

ID=${1}_${2}_${3}_${4}_${5}_d4
cd bin/$ID
cp ../../result_skel.sh .

d4u1_switches_cnt=0
d4u2_switches_cnt=0
d4u4_switches_cnt=0

if [ "$TOPO" = "BFT0" -a "$N" = "4" ]; then #TREE
	d4u1_switches_cnt=1
	d4u2_switches_cnt=0
	d4u4_switches_cnt=0
elif [ "$TOPO" = "BFT0" -a "$N" = "16" ]; then #TREE
	d4u1_switches_cnt=5
	d4u2_switches_cnt=0
	d4u4_switches_cnt=0
elif [ "$TOPO" = "BFT0" -a "$N" = "64" ]; then #TREE
	d4u1_switches_cnt=21
	d4u2_switches_cnt=0
	d4u4_switches_cnt=0

elif [ "$TOPO" = "BFT1" -a "$N" = "4" ]; then  #MESH 0
	d4u1_switches_cnt=0
	d4u2_switches_cnt=1
	d4u4_switches_cnt=0
elif [ "$TOPO" = "BFT1" -a "$N" = "16" ]; then #MESH 0
	d4u1_switches_cnt=0
	d4u2_switches_cnt=6
	d4u4_switches_cnt=0
elif [ "$TOPO" = "BFT1" -a "$N" = "64" ]; then #MESH 0
	d4u1_switches_cnt=0
	d4u2_switches_cnt=28
	d4u4_switches_cnt=0

elif [ "$TOPO" = "BFT2" -a "$N" = "4" ]; then  #MESH1
	d4u1_switches_cnt=0
	d4u2_switches_cnt=0
	d4u4_switches_cnt=1
elif [ "$TOPO" = "BFT2" -a "$N" = "16" ]; then #MESH1
	d4u1_switches_cnt=0
	d4u2_switches_cnt=4
	d4u4_switches_cnt=4
elif [ "$TOPO" = "BFT2" -a "$N" = "64" ]; then #MESH1
	d4u1_switches_cnt=0
	d4u2_switches_cnt=24
	d4u4_switches_cnt=16

elif [ "$TOPO" = "BFT3" -a "$N" = "4" ]; then  #XBAR
	d4u1_switches_cnt=0
	d4u2_switches_cnt=0
	d4u4_switches_cnt=1
elif [ "$TOPO" = "BFT3" -a "$N" = "16" ]; then #XBAR
	d4u1_switches_cnt=0
	d4u2_switches_cnt=0
	d4u4_switches_cnt=8
elif [ "$TOPO" = "BFT3" -a "$N" = "64" ]; then #XBAR
	d4u1_switches_cnt=0
	d4u2_switches_cnt=0
	d4u4_switches_cnt=48
fi

d4u1_switches_ports=$(echo "$d4u1_switches_cnt*5" | bc)
d4u2_switches_ports=$(echo "$d4u2_switches_cnt*6" | bc)
d4u4_switches_ports=$(echo "$d4u4_switches_cnt*8" | bc)

switching=`grep -nr "switching" test.log | wc -l`
time_taken=`cat test.log | grep -v "are done" | tail -n 2 | head -n 1 | sed "s/Time\(.*\):.*/\1/"`
sa=$(echo "${switching}/(${time_taken}*(${d4u1_switches_ports}+${d4u2_switches_ports}+${d4u4_switches_ports}))" | bc -l)

echo " ************************************************"
echo " Topology=$TOPO, PE=$N, RATE=$RATE, TRACE=$PAT"
echo " ************************************************"
echo " Switching Activity=$sa" 
echo "sem --id 0 echo fc4_$TOPO,$N,$RATE,$PAT,\$packets_sent,\$packets_recv,\$time_taken,\$irtxt,\$ortxt,\$if_worst_latency,\$queue_worst_latency,\$sum_queueing,\$worst_total_latency >> ../../../../results/perf/perf_sweep.csv" >> result_skel.sh

#chmod +x result_skel.sh
sh result_skel.sh
tar -zcf log.tar.gz *.log
find . ! -name 'log.tar.gz' -type f -exec rm -f {} +
rm -rf *
