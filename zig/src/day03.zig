const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const int = u64;

const Group = struct {
    []u8,    []u8,    []u8,
    [256]u8, [256]u8, [256]u8,
};

fn getPrio(v: u8) u8 {
    return switch (v) {
        'a'...'z' => v - 'a' + 1,
        'A'...'Z' => v - 'A' + 27,
        else => 0
    };
}

fn getGroup(reader: anytype, ret: *Group) bool {
    ret.*[0] = (reader.readUntilDelimiterOrEof(&ret.*[3], '\n') catch return false) orelse return false;
    ret.*[1] = (reader.readUntilDelimiterOrEof(&ret.*[4], '\n') catch return false) orelse return false;
    ret.*[2] = (reader.readUntilDelimiterOrEof(&ret.*[5], '\n') catch return false) orelse return false;
    return true;
}

fn computePart1(group: *const Group) int {
    var ret: int = 0;
    var prios: [53]bool = undefined;
    comptime var line_id: usize = 0;

    inline while (line_id < 3) : (line_id += 1) {
        var data = group.*[line_id];
        const compartment_1 = data[0..data.len / 2];
        const compartment_2 = data[data.len / 2..];

        std.mem.set(bool, prios[0..], false);

        for (compartment_1) |id1, idx| {
            prios[getPrio(id1)] = if (std.mem.indexOf(u8, compartment_2, compartment_1[idx..idx+1]) != null) true else false;
        }

        for (prios) |seen, prio| {
            if (seen) ret += prio;
        }
    }

    return ret;
}

fn computePart2(group: *const Group) int {
    var ret: int = 0;
    var prios: [53]bool = undefined;

    std.mem.set(bool, prios[0..], false);
    for (group.*[0]) |id, idx| {
        var f1 = if (std.mem.indexOf(u8, group.*[1], group.*[0][idx..idx+1]) != null) true else false;
        var f2 = if (std.mem.indexOf(u8, group.*[2], group.*[0][idx..idx+1]) != null) true else false;
        prios[getPrio(id)] = f1 and f2;
    }
    for (prios) |seen, prio| {
        if (seen) ret += prio;
    }
    return ret;
}

pub fn main() !void {
    var part1: int = 0;
    var part2: int = 0;
    var reader = std.io.getStdIn().reader();
    var group: Group = undefined;

    while (true) {
        if (!getGroup(reader, &group)) break;
        part1 += computePart1(&group);
        part2 += computePart2(&group);
    }

    print("{}\n{}\n", .{part1, part2});
}

test {
    var test_data =
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
    ;
    var stream = std.io.fixedBufferStream(test_data);
    var reader = stream.reader();
    var group1: Group = undefined;
    var group2: Group = undefined;

    try expect(getGroup(reader, &group1));
    try expect(getGroup(reader, &group2));

    try expect(computePart1(&group1) + computePart1(&group2) == 157);
    try expect(computePart2(&group1) == 18);
    try expect(computePart2(&group2) == 52);
}