#!/usr/bin/env bash
# world-clock: a polybar clock that cycles through time zones on click.
#
# Usage: world-clock.sh [-s FORMAT] [-l FORMAT] [-i SECONDS] ZONE[:LABEL]...
#
#   ZONE     an IANA time zone, e.g. Asia/Taipei, Europe/Paris
#   LABEL    text shown after the time (default: the city part of ZONE)
#   -s FMT   short format, shown by default      (default: "%a %H:%M")
#   -l FMT   long format, toggled by USR2         (default: "%a %d.%m.%Oy %H:%M")
#   -i SEC   refresh interval in seconds          (default: 5)
#
# Signals (wire them to polybar clicks, see README):
#   USR1  next zone
#   USR2  switch between short and long format

short_fmt="%a %H:%M"
long_fmt="%a %d.%m.%Oy %H:%M"
interval=5

usage() {
	sed -n '4,15s/^# \{0,1\}//p' "$0" >&2
	exit 1
}

while getopts "s:l:i:h" opt; do
	case $opt in
		s) short_fmt=$OPTARG ;;
		l) long_fmt=$OPTARG ;;
		i) interval=$OPTARG ;;
		*) usage ;;
	esac
done
shift $((OPTIND - 1))

(( $# > 0 )) || usage

zones=()
labels=()
for arg in "$@"; do
	zone=${arg%%:*}
	label=${arg#*:}
	[[ $arg == *:* ]] || label=${zone##*/}
	# date silently falls back to UTC on unknown zones, so check up front
	if [[ ! -e /usr/share/zoneinfo/$zone ]]; then
		echo "world-clock: unknown zone '$zone'"
		exit 1
	fi
	zones+=("$zone")
	labels+=("${label//_/ }")
done

idx=0
long=0

trap 'idx=$(( (idx + 1) % ${#zones[@]} ))' USR1
trap 'long=$(( !long ))' USR2

while true; do
	if (( long )); then fmt=$long_fmt; else fmt=$short_fmt; fi
	# keep % in labels literal for date
	TZ=${zones[idx]} date +"$fmt ${labels[idx]//%/%%}"
	sleep "$interval" &
	wait $! # returns early on a signal, so clicks show right away
done
