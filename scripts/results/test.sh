#!/bin/bash
#########
TOPO=$2
N=$3
RATE=$4
PAT=$5
ID=${1}_${2}_${3}_${4}_${5}_d4
##########

if [ "$TOPO" = "BFT0" ]; then
    TOPO_bp=TREE
elif [ "$TOPO" = "BFT1" ]; then
    TOPO_bp=MESH0
elif [ "$TOPO" = "BFT2" ]; then
    TOPO_bp=MESH1
elif [ "$TOPO" = "BFT3" ]; then
    TOPO_bp=XBAR
fi

rm -rf bin/$ID
mkdir -p bin/$ID
cd bin/$ID
cp ../../../../rtl/* ./
cp ../../../../includes/* ./
cp ../../../../tb/* ./

if [ "$PAT" = "local" ]; then
	PARA_PAT=1
	TRACE=SYNTHETIC
elif [ "$PAT" = "random" ]; then
	PARA_PAT=0
	TRACE=SYNTHETIC
else
	PARA_PAT=0
	TRACE=REAL
	cp ../../../../bench/$PAT/$N/* ./
fi
if [ "$PAT" = "local" ]; then
	SIGMA_MAX=$(echo "sqrt($N)" | bc -l)
	SIGMA_MAX=$(echo ${SIGMA_MAX%.*})
	for SIGMA in $( seq 1 $SIGMA_MAX )
	do
		echo "Setting locality = "$SIGMA
		verilator -Wno-WIDTH -Wno-COMBDLY -Wno-WIDTHCONCAT -D$TOPO_bp -D$TRACE -DSIM -GSIGMA=$SIGMA -GWRAP=1 -GN=$N -GRATE=$RATE -GPAT=$PARA_PAT --top-module bft4 --cc bft4.v client_bp.v client_bp_top.v mux.v rr_arbiter.v encoder.v d4u4_switch_top.sv d4u4_switch.sv d4u4_route.sv d4u2_switch_top.sv d4u2_switch.sv d4u2_route.sv d4u1_switch_top.sv d4u1_switch.sv d4u1_route.sv bp.v --exe bft4_tb.c > /dev/null
		make -C obj_dir -j -f Vbft4.mk Vbft4 > /dev/null
		./obj_dir/Vbft4 > test.log
		cat test.log | grep "Sent" | cut -d" " -f 9 | sed "s/packetid=//" | sed "s/,//" | sort -V > sent.log
		cat test.log | grep "Received" | cut -d" " -f 7 | sed "s/data=//" | sed "s/,//" | sort -V > recv.log
		diff sent.log recv.log
		rm -rf obj_dir
		cd ../..
		sh perf.sh $1 $TOPO $N $RATE $PAT $SIGMA
		cd bin/$ID
		rm log.tar.gz
		cp ../../../../rtl/* ./
		cp ../../../../includes/* ./
		cp ../../../../tb/* ./
	done
else
##########
	verilator -Wno-WIDTH -Wno-COMBDLY -Wno-WIDTHCONCAT -D$TOPO_bp -D$TRACE -DSIM -GWRAP=1 -GSIGMA=4 -GN=$N -GRATE=$RATE -GPAT=$PARA_PAT --top-module bft4 --cc bft4.v client_bp.v client_bp_top.v mux.v rr_arbiter.v encoder.v d4u4_switch_top.sv d4u4_switch.sv d4u4_route.sv d4u2_switch_top.sv d4u2_switch.sv d4u2_route.sv d4u1_switch_top.sv d4u1_switch.sv d4u1_route.sv bp.v --exe bft4_tb.c > /dev/null
	make -C obj_dir -j -f Vbft4.mk Vbft4 > /dev/null
	./obj_dir/Vbft4 > test.log
	cat test.log | grep "Sent" | cut -d" " -f 9 | sed "s/packetid=//" | sed "s/,//" | sort -V > sent.log
	cat test.log | grep "Received" | cut -d" " -f 7 | sed "s/data=//" | sed "s/,//" | sort -V > recv.log
	diff sent.log recv.log
	#########
	rm -rf obj_dir
	cd ../..
	sh perf.sh $1 $TOPO $N $RATE $PAT
fi
