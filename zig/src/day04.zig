const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;
const aoc = @import("aoc");

const int = i64;

const Range = struct {
    min: int,
    max: int,
};

fn getRanges(stream: aoc.Stream) ?struct{Range, Range} {
    var buf: [256]u8 = undefined;
    if (stream.readUntilDelimiterOrEof(&buf, '\n')) |raw_line| {
        var line = raw_line orelse return null;
        var i: usize = 0;
        var pieces: [4][] const u8 = undefined;
        var iter = std.mem.tokenize(u8, line, ",-");
        while (iter.next()) |token| {
            if (i > 3) return null;
            pieces[i] = token;
            i += 1;
        }

        var r1: Range = undefined;
        var r2: Range = undefined;

        r1.min = std.fmt.parseInt(int, pieces[0], 0) catch return null;
        r1.max = std.fmt.parseInt(int, pieces[1], 0) catch return null;

        r2.min = std.fmt.parseInt(int, pieces[2], 0) catch return null;
        r2.max = std.fmt.parseInt(int, pieces[3], 0) catch return null;

        return .{r1, r2};
    } else |_| {
        return null;
    }
}

fn computePart1(r1: Range, r2: Range) int {
    return if (((r1.min >= r2.min) and (r1.max <= r2.max)) or ((r2.min >= r1.min) and (r2.max <= r1.max))) 1 else 0;
}

fn computePart2(r1: Range, r2: Range) int {
    return if (((r1.max < r2.min) or (r1.min > r2.max)) or ((r2.max < r1.min) or (r2.min > r1.max))) 0 else 1;
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);

    var part1: int = 0;
    var part2: int = 0;
    while (getRanges(stream)) |ranges| {
        part1 += computePart1(ranges[0], ranges[1]);
        part2 += computePart2(ranges[0], ranges[1]);
    }

    print("{}\n{}\n", .{part1, part2});
}

test {
    const test_data =
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
    ;
    var mem_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&mem_stream);

    var part1: int = 0;
    var part2: int = 0;
    while (getRanges(stream)) |ranges| {
        part1 += computePart1(ranges[0], ranges[1]);
        part2 += computePart2(ranges[0], ranges[1]);
    }

    try expect(part1 == 2);
    try expect(part2 == 4);
}
