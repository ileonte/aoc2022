#!/bin/sh

BASE=$(dirname "$0")

runTests() {
    ${BASE}/zig-out/bin/day01 < ${BASE}/../inputs/day01.txt
    ${BASE}/zig-out/bin/day02 < ${BASE}/../inputs/day02.txt
    ${BASE}/zig-out/bin/day03 < ${BASE}/../inputs/day03.txt
    ${BASE}/zig-out/bin/day04 < ${BASE}/../inputs/day04.txt
    ${BASE}/zig-out/bin/day05 < ${BASE}/../inputs/day05.txt
    ${BASE}/zig-out/bin/day06 < ${BASE}/../inputs/day06.txt
    ${BASE}/zig-out/bin/day07 < ${BASE}/../inputs/day07.txt
    ${BASE}/zig-out/bin/day08 < ${BASE}/../inputs/day08.txt
    ${BASE}/zig-out/bin/day09 < ${BASE}/../inputs/day09.txt
}

time runTests
