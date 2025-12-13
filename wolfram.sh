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

for ((i=0;i<=width-1;i++)); do
    state+=($((i == width/2)))
done

draw "${state[@]}"
