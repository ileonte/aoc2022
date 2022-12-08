const std = @import("std");
const aoc = @import("aoc");

const print = std.debug.print;
const expect = std.testing.expect;

const int = i64;

fn compute(stream: aoc.Stream) !struct{int, int} {
    var buf : [1024]u8 = .{};
    var current : int = 0;
    var result: [3]int = .{0, 0, 0};

    while (stream.readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var data = raw_data orelse {
            if (current > result[0]) {
                result[2] = result[1];
                result[1] = result[0];
                result[0] = current;
            } else if (current > result[1]) {
                result[2] = result[1];
                result[1] = current;
            } else if (current > result[2]) {
                result[2] = current;
            }
            break;
        };
        if (data.len == 0) {
            if (current > result[0]) {
                result[2] = result[1];
                result[1] = result[0];
                result[0] = current;
            } else if (current > result[1]) {
                result[2] = result[1];
                result[1] = current;
            } else if (current > result[2]) {
                result[2] = current;
            }
            current = 0;
        } else {
            current = current + try std.fmt.parseInt(int, data, 0);
        }
    } else |err| {
        return err;
    }

    return .{
        result[0],
        result[0] + result[1] + result[2],
    };
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var ret = try compute(stream);
    print("{}\n{}\n", .{ret[0], ret[1]});
}

test {
    const test_data =
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);
    var ret = try compute(stream);
    try expect(ret[0] == 24000);
    try expect(ret[1] == 45000);
}