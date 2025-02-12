#!/usr/bin/env bash

declare target
declare command
declare sub_command

if (( $# == 1 )) && [[ $1 == "clean" ]]; then
    target=$1
elif (( $# >= 2 )); then
    target=$1
    command=$2
    if (( $# >= 3 )); then
        sub_command=$3
    fi
else
    echo "Usage: $0 <target_langauge> <command> [sub_command]" >&2
    exit 1
fi

root=/home/mohitjangra/learning/performance_aware_programming/instruction_decoding_8086

if [[ $target == "zig" ]]; then
    if [[ $command == "test" ]]; then
        zig test $root/zig/disassembler_8086.zig $4
    elif [[ $command == "build" ]]; then
        zig build-exe -OReleaseFast $root/zig/disassembler_8086.zig -femit-bin=$root/zig/disassembler_8086
        if [[ $sub_command == "run" ]]; then
            "$root/zig/disassembler_8086" $4
        fi
    elif [[ $command == "debug" ]]; then
        zig build-exe -ODebug -fno-strip -fvalgrind zig/disassembler_8086.zig -femit-bin=$root/zig/disassembler_8086
        if [[ $sub_command == "run" ]]; then
            "$root/zig/disassembler_8086" $4
        fi
    fi
elif [[ $target == "c" ]]; then
    if [[ $command == "build" ]]; then
        clang -O3 -Wall -Wextra -o $root/c/disassembler_8086 $root/c/disassembler_8086.c
        if [[ $sub_command == "run" ]]; then
            "$root/c/disassembler_8086" $4
        fi
    elif [[ $command == "debug" ]]; then
        clang -Wall -Wextra -o $root/c/disassembler_8086 $root/c/disassembler_8086.c
        if [[ $sub_command == "run" ]]; then
            "$root/c/disassembler_8086" $4
        fi
    fi
elif [[ $target == "clean" ]]; then
	rm -f disassembler_8086
	rm -f zig/disassembler_8086 zig/disassembler_8086.o
	rm -f c/disassembler_8086 c/disassembler_8086.o
fi
