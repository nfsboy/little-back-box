#!/bin/bash

# Variables
filename=

[[ $1 ]] || {
  echo "Usage: rsync -P --exclude=exclude-file ... | $0 exclude-file" >&2
  exit 1
}

CONFIG_DIR=$(dirname "$0")
CONFIG="${CONFIG_DIR}/config.cfg"
source "$CONFIG"

storsize=$(df /dev/"$STORAGE_DEV"  -h --output=size | sed '1d' | tr -d ' ')
timestamp=$(date +%s)

while IFS=$'\n' read -r -d $'\r' -a pieces; do

  for piece in "${pieces[@]}"; do
    case $piece in
      "sending incremental file list") continue ;;
      [[:space:]]*)
        read -r size pct rate time <<<"$piece"
        cTimestamp=$(date +%s)
	dif=$(($cTimestamp - $timestamp))
        if [ $dif -gt 0 ]; then
            oled r
            oled +b "Backup progress:"
            oled +c "$pct - $rate"
            oled +d "Storage: $storsize"
            sudo oled s
            timestamp=$(date +%s)
            let "timestamp=timestamp+2"
        fi
        ;;
      *) filename=$piece;  ;;
    esac
  done
done