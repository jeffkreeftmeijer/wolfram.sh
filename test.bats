#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    PATH="$DIR:$PATH"
}

@test "prints the first generation" {
    run wolfram.sh -w 3
    assert_output ' █ '
}
