#!/bin/sh
# A polybar clock that cycles through time zones on click.
# https://github.com/tipharez-allmighty/polybar-world-clock

prog=${0##*/}

usage() {
	cat >&2 <<EOF
Usage: $prog [-s FORMAT] [-l FORMAT] [-i SECONDS] ZONE[:LABEL]...

  ZONE     an IANA time zone (Europe/Paris) or a POSIX TZ string (UTC-0)
  LABEL    text shown after the time (default: the city part of ZONE)
  -s FMT   short format, shown by default      (default: "%a %H:%M")
  -l FMT   long format, toggled by USR2         (default: "%a %d.%m.%y %H:%M")
  -i SEC   refresh interval in seconds          (default: 5)

Signals:
  USR1  next zone
  USR2  switch between short and long format
EOF
	exit 1
}

short_fmt="%a %H:%M"
long_fmt="%a %d.%m.%y %H:%M"
interval=5

while getopts "s:l:i:h" opt; do
	case $opt in
		s) short_fmt=$OPTARG ;;
		l) long_fmt=$OPTARG ;;
		i) interval=$OPTARG ;;
		*) usage ;;
	esac
done
shift $((OPTIND - 1))

[ $# -gt 0 ] || usage

# date silently falls back to UTC on unknown zones, so check up front.
# Valid: a file in the zoneinfo database (Europe/Paris, UTC, EST5EDT),
# or a POSIX TZ string without a slash (UTC-0, CET-1CEST, <+08>-8).
zoneinfo=${TZDIR:-/usr/share/zoneinfo}
valid_zone() {
	[ -f "$zoneinfo/$1" ] && return 0
	case $1 in
		*/*) return 1 ;;
		"<"*">"*) rest=${1#*>} ;;
		*)
			name=${1%%[!A-Za-z]*}
			[ ${#name} -ge 3 ] || return 1
			rest=${1#"$name"}
			;;
	esac
	case $rest in
		[0-9]* | [+-][0-9]*) return 0 ;;
		*) return 1 ;;
	esac
}

for arg in "$@"; do
	if ! valid_zone "${arg%%:*}"; then
		echo "${prog%.sh}: unknown zone '${arg%%:*}'"
		exit 1
	fi
done

idx=1
long=0

trap 'idx=$((idx % $# + 1))' USR1
trap 'long=$((1 - long))' USR2

while true; do
	eval "arg=\${$idx}"
	zone=${arg%%:*}
	case $arg in
		*:*) label=${arg#*:} ;;
		*) label=$(printf '%s' "${zone##*/}" | tr '_' ' ') ;;
	esac
	if [ "$long" -eq 1 ]; then fmt=$long_fmt; else fmt=$short_fmt; fi
	printf '%s %s\n' "$(TZ=$zone date +"$fmt")" "$label"
	sleep "$interval" &
	wait $! # returns early on a signal, so clicks show right away
done
