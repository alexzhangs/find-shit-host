#!/bin/bash

usage () {
    printf "Find host in LAN with special IP and/or MAC address.\n"
    printf "Internally using tool: nbtscan, traceroute and ping.\n\n"

    printf "${0##*/}\n"
    printf "\t-c CIDR_BLOCK\n"
    printf "\t[-m MAC_ADDRESS]\n"
    printf "\t[-n NBTSCAN_OPTIONS]\n"
    printf "\t[-t TRACEROUTE_OPTIONS]\n"
    printf "\t[-e EMAIL]\n"
    printf "\t[-h]\n\n"

    printf "OPTIONS\n"
    printf "\t-c CIDR_BLOCK\n\n"
    printf "\tHost IP and range. Format: <IP_ADDRESS>[/BIT].\n"
    printf "\te.g.: 192.168.0.100 or 192.168.0.100/24 or 192.168.0.0/24\n"
    printf "\tIP is used to probe host alive and collect information.\n"
    printf "\tBIT is used to determine IP scan range, default is 24(256 IPs).\n\n"

    printf "\t[-m MAC_ADDRESS]\n\n"
    printf "\tMAC address is used to reversely find host and confirm the host being found.\n\n"

    printf "\t[-n NBTSCAN_OPTIONS]\n\n"
    printf "\tnbtscan options.\n"
    printf "\te.g. '-b 10240' is helpful on slow network.\n\n"

    printf "\t[-t TRACEROUTE_OPTIONS]\n"
    printf "\ttraceroute options.\n"
    printf "\te.g.: '-w 1 -m 8' is used to reduce trace time.\n\n"

    printf "\t[-e EMAIL]\n\n"
    printf "\tEmail address, to send nortification if succesfully found host.\n\n"

    printf "\t[-h]\n\n"
    printf "\tThis help.\n\n"

    exit 255
}

logger () {
    printf "$(date '+%Y-%m-%d %H:%M:%S') [ ${0##*/}:$$ ] - $*\n"
}

get_cidr_ip () {
    echo "${1:?}" | cut -d/ -f1
}

get_cidr_bit () {
    echo "${1:?}" | cut -d/ -f2
}

is_broadcast_ip () {
    local suffix=$(echo "${1:?}" | cut -d. -f4)
    [[ $suffix -eq 0 || $suffix -eq 255 ]]
}

notify () {
    if [[ -n $email ]]; then
        logger "notifying $email\n\n"
        /usr/sbin/sendmail "$email" << EOF
Subject: Shit Found at $(hostname)
Content-Type: text/plain

$out
EOF
    fi
}

probe_host () {
    /bin/ping -t 1 -c 3 "$ip"
    local ret=$?

    local out="$(/usr/sbin/nbtscan -r $nbtscan_options "$ip" 2>&1)"
    echo "$out" | egrep -qw "$found_pattern"
    ret=$((ret && $?))
    echo "$out"

    /bin/traceroute $traceroute_options "$ip"

    return $ret
}

search_host () {
    local out="$(/usr/sbin/nbtscan $nbtscan_options "$ip/$bit" 2>&1)"
    echo "$out" | egrep -qw "$found_pattern"
    local ret=$?
    echo "$out"

    return $ret
}

main () {
    local ret

    if ! is_broadcast_ip "$ip"; then
        logger "probing $ip\n\n"
        probe_host
        ret=$?
    else
        logger "skipped probing broadcase address $ip"
        ret=255
    fi

    if [[ $ret -ne 0 ]]; then
        logger "searching $ip/$bit\n\n"
        search_host
        ret=$?
    else
        :
    fi

    return $ret
}

nbtscan_options=''
traceroute_options=''
while getopts c:m:n:t:e:h opt; do
    case $opt in
        c)
            cidr=$OPTARG
            ;;
        m)
            mac=$OPTARG
            ;;
        n)
            nbtscan_options=$OPTARG
            ;;
        t)
            traceroute_options=$OPTARG
            ;;
        e)
            email=$OPTARG
            ;;
        h|*)
            usage
            ;;
    esac
done

ip=$(get_cidr_ip "$cidr")
bit=$(get_cidr_bit "$cidr")
[[ -z $bit ]] && bit=24

if ! is_broadcast_ip "$ip" && test -n "$mac"; then
    found_pattern="(^$ip|$mac)"
elif ! is_broadcast_ip "$ip" && test -z "$mac"; then
    found_pattern="^$ip"
elif is_broadcast_ip "$ip" && test -n "$mac"; then
    found_pattern="$mac"
else
    usage
fi

logger "started to find host: $ip/$bit, mac: $mac, notify: $email"
logger "nbtscan options: $nbtscan_options"
logger "traceroute options: $traceroute_options"

out="$(main)"
ret=$?
echo "$out"

if [[ $ret -eq 0 ]]; then
    logger '==> SHIT FOUND <=='
    notify
else
    logger '==> NO SHIT FOUND <=='
fi

logger "done"

exit
