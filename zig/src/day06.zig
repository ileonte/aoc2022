const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;
const print = std.debug.print;

const Set = std.StaticBitSet(32);

fn getPacketStart(comptime marker_size: usize, message: [] const u8) !usize {
    try expect(message.len > marker_size);
    try expect(marker_size > 0 and marker_size <= Set.bit_length);

    var set = Set.initEmpty();

    for (message[0..marker_size]) |ch| {
        set.set(ch - 'a');
    }
    if (set.count() == marker_size) return 4;

    var idx: usize = 1;
    while (idx < message.len - marker_size + 1) : (idx += 1) {
        set.unset(message[idx - 1] - 'a');
        for (message[idx..idx + marker_size]) |ch| {
            set.set(ch - 'a');
        }
        if (set.count() == marker_size) return idx + marker_size;
    }

    return 0;
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var buf: [8192]u8 = undefined;

    if (stream.readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var data = raw_data orelse return error.InvalidInput;

        var part1 = try getPacketStart(4, data);
        var part2 = try getPacketStart(14, data);

        print("{}\n{}\n", .{part1, part2});
    } else |err| {
        return err;
    }
}


test {
    const test_data = [_]struct{str: [] const u8, pkt: usize, msg: usize} {
        .{.str = "mjqjpqmgbljsphdztnvjfqwrcgsmlb",    .pkt =  7, .msg = 19},
        .{.str = "bvwbjplbgvbhsrlpgdmjqwftvncz",      .pkt =  5, .msg = 23},
        .{.str = "nppdvjthqldpwncqszvftbrmjlhg",      .pkt =  6, .msg = 23},
        .{.str = "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg", .pkt = 10, .msg = 29},
        .{.str = "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw",  .pkt = 11, .msg = 26},
    };

    for (test_data) |data| {
        var pkt = try getPacketStart(4, data.str);
        var msg = try getPacketStart(14, data.str);
        try expect(pkt == data.pkt);
        try expect(msg == data.msg);
    }
}
