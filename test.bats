#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    PATH="$DIR:$PATH"
}

@test "prints the first generation" {
    run wolfram.sh -w 3 -g 1 -d 0
    assert_output ' █ '
}

@test "prints multiple generations" {
    run wolfram.sh -w 5 -g 3 -r 30 -d 0
    assert_output $'  █  \n ███ \n██  █'
}
