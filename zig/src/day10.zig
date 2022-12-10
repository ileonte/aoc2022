const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;
const print = std.debug.print;

const Instruction = union(enum) {
    const s_NOOP = struct { const cost: i8 = 1; };
    const s_ADDX = struct { const cost: i8 = 2; value: i64 };

    NOOP: s_NOOP,
    ADDX: s_ADDX,

    pub fn parse(line: []const u8) !Instruction {
        var trimmed = aoc.trim(line);

        if (std.mem.eql(u8, trimmed, "noop"))
            return Instruction { .NOOP = .{} };

        if (std.mem.startsWith(u8, trimmed, "addx ")) {
            trimmed = aoc.trim(trimmed[5..]);
            var val = s_ADDX{ .value = 0 };
            val.value = try std.fmt.parseInt(@TypeOf(val.value), trimmed, 0);
            return Instruction { .ADDX = val };
        }

        return error.InvalidInput;
    }
};

var CRT: [240]u8 = undefined;
var CRT_s: [246]u8 = undefined;

fn compute(stream: aoc.Stream) !i64 {
    var part1: i64 = 0;

    std.mem.set(u8, &CRT, '.');

    var buf: [64]u8 = undefined;
    var cycle: i64 = 1;
    var regX: i64 = 1;
    while (stream.readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var data = raw_data orelse break;
        var instr = try Instruction.parse(data);
        var cycle_count: i64 = 0;
        var increment: i64 = 0;

        switch (instr) {
            Instruction.NOOP => |noop| {
                cycle_count = @TypeOf(noop).cost;
                increment = 0;
            },
            Instruction.ADDX => |addx| {
                cycle_count = @TypeOf(addx).cost;
                increment = addx.value;
            },
        }

        var next_cycle = cycle + cycle_count;
        while (cycle < next_cycle) : (cycle += 1) {
            part1 += switch (cycle) {
                20, 60, 100, 140, 180, 220 => cycle * regX,
                else => 0,
            };

            var screen_abs_pos: i64 = cycle - 1;
            var screen_pos: i64 = @mod(screen_abs_pos, 40);
            if (screen_pos >= regX - 1 and screen_pos <= regX + 1) {
                var idx = @intCast(usize, screen_abs_pos);
                CRT[idx] = '#';
            }
        }
        regX += increment;
    } else |err| {
        return err;
    }

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        std.mem.copy(u8, CRT_s[i * 41..], CRT[i * 40..(i + 1) * 40]);
        CRT_s[i * 41 + 40] = '\n';
    }

    return part1;
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var ret = try compute(stream);
    print("{}\n", .{ret});
    print("{s}", .{&CRT_s});
}

test {
    const test_program =
        \\addx 15
        \\addx -11
        \\addx 6
        \\addx -3
        \\addx 5
        \\addx -1
        \\addx -8
        \\addx 13
        \\addx 4
        \\noop
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx 5
        \\addx -1
        \\addx -35
        \\addx 1
        \\addx 24
        \\addx -19
        \\addx 1
        \\addx 16
        \\addx -11
        \\noop
        \\noop
        \\addx 21
        \\addx -15
        \\noop
        \\noop
        \\addx -3
        \\addx 9
        \\addx 1
        \\addx -3
        \\addx 8
        \\addx 1
        \\addx 5
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx -36
        \\noop
        \\addx 1
        \\addx 7
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\addx 6
        \\noop
        \\noop
        \\noop
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx 7
        \\addx 1
        \\noop
        \\addx -13
        \\addx 13
        \\addx 7
        \\noop
        \\addx 1
        \\addx -33
        \\noop
        \\noop
        \\noop
        \\addx 2
        \\noop
        \\noop
        \\noop
        \\addx 8
        \\noop
        \\addx -1
        \\addx 2
        \\addx 1
        \\noop
        \\addx 17
        \\addx -9
        \\addx 1
        \\addx 1
        \\addx -3
        \\addx 11
        \\noop
        \\noop
        \\addx 1
        \\noop
        \\addx 1
        \\noop
        \\noop
        \\addx -13
        \\addx -19
        \\addx 1
        \\addx 3
        \\addx 26
        \\addx -30
        \\addx 12
        \\addx -1
        \\addx 3
        \\addx 1
        \\noop
        \\noop
        \\noop
        \\addx -9
        \\addx 18
        \\addx 1
        \\addx 2
        \\noop
        \\noop
        \\addx 9
        \\noop
        \\noop
        \\noop
        \\addx -1
        \\addx 2
        \\addx -37
        \\addx 1
        \\addx 3
        \\noop
        \\addx 15
        \\addx -21
        \\addx 22
        \\addx -6
        \\addx 1
        \\noop
        \\addx 2
        \\addx 1
        \\noop
        \\addx -10
        \\noop
        \\noop
        \\addx 20
        \\addx 1
        \\addx 2
        \\addx 2
        \\addx -6
        \\addx -11
        \\noop
        \\noop
        \\noop
    ;
    const test_crt =
        \\##..##..##..##..##..##..##..##..##..##..
        \\###...###...###...###...###...###...###.
        \\####....####....####....####....####....
        \\#####.....#####.....#####.....#####.....
        \\######......######......######......####
        \\#######.......#######.......#######.....
        \\
    ;
    var in_stream = std.io.fixedBufferStream(test_program);
    var stream = aoc.Stream.initMem(&in_stream);
    var ret = try compute(stream);
    try expect(ret == 13140);
    try std.testing.expectEqualSlices(u8, &CRT_s, test_crt[0..]);
}
