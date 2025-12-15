#!/usr/bin/env bash

draw() {
    local line=""
    for value in "$@"; do
          line+=$([ "$value" -eq 1 ] && echo "$live" || echo "$dead");
    done
    printf "%b" "${line}"
}

width=$(tput cols)
live="█"
dead=" "
rule=$((RANDOM % 256))
generations=0
delay=0.1

while getopts "d:g:r:w:" flag; do
    case "$flag" in
	'd') delay=$OPTARG;;
	'g') generations=$OPTARG;;
	'r') rule=$OPTARG;;
	'w') width=$OPTARG;;
	*) exit
    esac
done

ruleset=(0 0 0 0 0 0 0 0)
for i in {0..7}; do
    ruleset[i]=$((rule % 2))
    rule=$((rule / 2))
done

for ((i=0;i<=width-1;i++)); do
    state+=($((i == width/2)))
done

draw "${state[@]}"

count=1

while [ "$generations" = 0 ] || [ $count -lt "$generations" ]; do
    sleep "$delay"
    new_state=()

    for ((i=0;i<=width-1;i++)); do
	neighborhood=$((state[i-1]))$((state[i]))$((${state[i+1]:-${state[0]}}))
        new_state+=("${ruleset[$((2#$neighborhood))]}")
    done

    state=("${new_state[@]}")

    printf "\n"
    draw "${state[@]}"

    ((count++))
done
