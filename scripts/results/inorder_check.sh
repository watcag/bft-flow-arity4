#!/bin/bash

set -u

CLIENTS=$1
N=$((CLIENTS - 1))

rm -f sent_* recv_* trecv_*

for source in $(seq 0 "$N"); do
  for destination in $(seq 0 "$N"); do
    if [ "$source" -eq "$destination" ]; then
      continue
    fi

    grep "Sent packet from PE($source) to PE($destination)" test.log \
      | awk '{print $10}' \
      | sed 's/data=//' > "sent_${source}${destination}.log"

    while read -r line; do
      grep "Received packet at PE($destination) with data=${line}$" test.log \
        | awk '{print $1, $7}' \
        | sed 's/Time//' \
        | sed 's/:data=/ /' >> "recv_${source}${destination}.log"
    done < "sent_${source}${destination}.log"

    sort -k 1 -n "recv_${source}${destination}.log" \
      | awk '{print $2}' > "trecv_${source}${destination}.log"
    mv "trecv_${source}${destination}.log" "recv_${source}${destination}.log"

    if cmp -s "sent_${source}${destination}.log" "recv_${source}${destination}.log"; then
      echo "Packets from $source to $destination are IN-ORDER"
      rm -f "sent_${source}${destination}.log" "recv_${source}${destination}.log"
    else
      echo "ERROR: Packets from $source to $destination are NOT IN-ORDER"
    fi
  done
done
