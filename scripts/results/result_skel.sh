#!/bin/zsh
set -e

# GNU Parallel provides `sem`, but a single functional-demo run does not need
# inter-process serialization. Keep the demo usable when GNU Parallel is not
# installed while preserving `sem` for concurrent sweep jobs when available.
if ! command -v sem >/dev/null 2>&1; then
	sem() {
		if [ "$1" = "--id" ]; then
			shift 2
		fi
		"$@"
	}
fi

# count metrics for bandwidth
packets_sent=`awk 'END {print NR}' sent.log`
packets_recv=`awk 'END {print NR}' recv.log`
time_taken=`cat test.log | grep -v "are done" | tail -n 2 | head -n 1 | sed "s/Time\(.*\):.*/\1/"`
ir=`cat test.log | grep "RATE=" | sed "s/RATE=\(.*\),.*/\1/"`
n=`cat test.log | grep "N=" | sed "s/.*N=//"`

# count metrics for latency
cat test.log | grep "Attempted" | cut -d" " -f1,3 | sed "s/Time//" | sed "s/://" | sed "s/packetid=//" | sort -t" " -k2 -V | sed "s/ /,/" > attempt.log
cat test.log | grep "Sent" | cut -d" " -f1,9 | sed "s/Time//" | sed "s/://" | sed "s/\(.*\),/\1/" | sed "s/packetid=//" | sort -t" " -k2 -V | sed "s/ /,/" > sentq.log
cat test.log | grep "Received" | cut -d" " -f1,7 | sed "s/Time//" | sed "s/://" | sed "s/\(.*\),/\1/" | sed "s/data=//" | sort -t" " -k2 -V | sed "s/ /,/" > recvq.log
paste -d"," attempt.log sentq.log recvq.log > latency.log

awk -F"," '{print $5-$1","$5-$3","$3-$1}' latency.log > latency-fixed.log
total_latency=`awk -F"," '{sum += $1} END {print sum + 0}' latency-fixed.log`
queue_worst_latency=`awk -F"," '$3 > max {max = $3} END {print max + 0}' latency-fixed.log`
if_worst_latency=`awk -F"," '$2 > max {max = $2} END {print max + 0}' latency-fixed.log`
sum_queueing=`awk -F"," '{sum += $3} END {print sum + 0}' latency-fixed.log`
worst_total_latency=`awk -F"," '$1 > max {max = $1} END {print max + 0}' latency-fixed.log`
average_latency=$(echo $total_latency/$packets_sent | bc -l)
irtxt=`echo "scale=3; $ir/100" | bc -l`
ortxt=`echo "scale=3; $packets_sent/($time_taken*$n)" | bc -l`
echo " "
echo " Packets Sent = ${packets_sent}, Packets Received = ${packets_recv}"
echo " "
echo " Cycles = ${time_taken},  NoC sustained Rate = ${ortxt}"
echo " "
echo " Worst Inflight Latency = ${if_worst_latency}, Worst Total Latency = ${worst_total_latency}"
