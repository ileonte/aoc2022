const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;
const print = std.debug.print;

const Int = u64;

const Operation = union(enum) {
    const SelfSelfOp = struct{};
    const SelfOperandOp = struct { operand: Int };

    self_add: SelfSelfOp,
    self_mul: SelfSelfOp,
    add: SelfOperandOp,
    mul: SelfOperandOp,

    pub fn parse(line: []const u8) !Operation {
        const line_marker = "  Operation: ";
        if (!std.mem.startsWith(u8, line, line_marker)) return error.InvalidInput;

        const op_marker = "new = ";
        var op_s = line[line_marker.len..];
        if (!std.mem.startsWith(u8, op_s, op_marker)) return error.InvalidInput;
        op_s = op_s[op_marker.len..];

        var it = std.mem.tokenize(u8, op_s, " ");
        var v1 = it.next() orelse return error.InvalidInput;
        var op = it.next() orelse return error.InvalidInput;
        var v2 = it.next() orelse return error.InvalidInput;

        v1 = aoc.trim(v1);
        op = aoc.trim(op);
        v2 = aoc.trim(v2);

        if (v1.len == 0 or op.len == 0 or v2.len == 0) return error.InvalidInput;
        if (!std.mem.eql(u8, v1, "old")) return error.InvalidInput;
        if (std.mem.eql(u8, v2, "old")) {
            return switch (op[0]) {
                '*' => Operation{ .self_mul = .{} },
                '+' => Operation{ .self_add = .{} },
                else => error.InvalidInput
            };
        } else {
            var v: Operation.SelfOperandOp = undefined;
            const T = @TypeOf(v.operand);
            v.operand = try std.fmt.parseInt(T, v2, 0);
            return switch (op[0]) {
                '*' => Operation{ .mul = v },
                '+' => Operation{ .add = v },
                else => error.InvalidInput
            };
        }
    }

    pub fn execute(self: Operation, old: Int) Int {
        return switch (self) {
            Operation.self_add => old + old,
            Operation.self_mul => old * old,
            Operation.add => |o| old + o.operand,
            Operation.mul => |o| old * o.operand,
        };
    }
};

const Monkey = struct {
    id: usize,
    op: Operation,
    total_inspected: Int,
    items: std.ArrayList(Int),
    test_operand: Int,
    dest: [2]usize,

    pub fn read(stream: aoc.Stream) !?Monkey {
        const monkey_marker = "Monkey ";
        const items_marker  = "  Starting items: ";
        const test_marker   = "  Test: divisible by ";
        const true_marker   = "    If true: throw to monkey ";
        const false_marker  = "    If false: throw to monkey ";

        var ret: Monkey = undefined;
        var buf: [256]u8 = undefined;

        ret.items = try std.ArrayList(Int).initCapacity(std.heap.page_allocator, 128);
        errdefer ret.items.deinit();

        ret.total_inspected = 0;

        {
            var line = try stream.readUntilDelimiterOrEof(&buf, '\n') orelse return null;
            if (!std.mem.startsWith(u8, line, monkey_marker)) return error.InvalidInput;
            if (!std.mem.endsWith(u8, line, ":")) return error.InvalidInput;
            line = line[monkey_marker.len..line.len - 1];
            ret.id = try std.fmt.parseInt(usize, line, 0);
        }

        {
            var line = try stream.readUntilDelimiterOrEof(&buf, '\n') orelse return error.InvalidInput;
            if (!std.mem.startsWith(u8, line, items_marker)) return error.InvalidInput;
            line = line[items_marker.len..];
            var it = std.mem.tokenize(u8, line, ", ");
            while (it.next()) |part| {
                var v = try std.fmt.parseInt(Int, part, 0);
                try ret.items.append(v);
            }
        }

        {
            var line = try stream.readUntilDelimiterOrEof(&buf, '\n') orelse return error.InvalidInput;
            ret.op = try Operation.parse(line);
        }

        {
            var line = try stream.readUntilDelimiterOrEof(&buf, '\n') orelse return error.InvalidInput;
            if (!std.mem.startsWith(u8, line, test_marker)) return error.InvalidInput;
            line = line[test_marker.len..];
            ret.test_operand = try std.fmt.parseInt(Int, line, 0);
        }

        {
            var line = try stream.readUntilDelimiterOrEof(&buf, '\n') orelse return error.InvalidInput;
            if (!std.mem.startsWith(u8, line, true_marker)) return error.InvalidInput;
            line = line[true_marker.len..];
            ret.dest[1] = try std.fmt.parseInt(usize, line, 0);

            line = try stream.readUntilDelimiterOrEof(&buf, '\n') orelse return error.InvalidInput;
            if (!std.mem.startsWith(u8, line, false_marker)) return error.InvalidInput;
            line = line[false_marker.len..];
            ret.dest[0] = try std.fmt.parseInt(usize, line, 0);
        }

        blk: {
            var line = aoc.trim(try stream.readUntilDelimiterOrEof(&buf, '\n') orelse break :blk);
            if (line.len != 0) return error.InvalidInput;
        }

        return ret;
    }

    pub fn deinit(self: *Monkey) void {
        self.items.deinit();
    }

    pub fn clone(self: Monkey) !Monkey {
        return Monkey {
            .id = self.id,
            .op = self.op,
            .total_inspected = self.total_inspected,
            .items = try self.items.clone(),
            .test_operand = self.test_operand,
            .dest = self.dest,
        };
    }
};

var monkey_storage: [16]Monkey = undefined;
fn readMonkeys(stream: aoc.Stream) ![]Monkey {
    var ret: []Monkey = monkey_storage[0..0];
    while (Monkey.read(stream)) |raw_monkey| {
        if (ret.len == monkey_storage.len) return error.TooManyMonkeys;
        monkey_storage[ret.len] = raw_monkey orelse break;
        ret = monkey_storage[0..ret.len + 1];
    } else |err| {
        return err;
    }
    return ret;
}

fn transformDiv(val: Int, div: Int) Int {
    return val / div;
}

fn transformMod(val: Int, mod: Int) Int {
    return val % mod;
}

const TransformFn = fn(v: Int, o: Int) Int;

fn play(in_monkeys: []Monkey, rounds: usize, comptime drop_worry_levels: bool) !Int {
    comptime var transform: TransformFn = if (drop_worry_levels) transformDiv else transformMod;
    var mod: Int = 1;
    var local_monkeys: [monkey_storage.len]Monkey = undefined;
    for (in_monkeys) |m, idx| {
        var gcd = std.math.gcd(mod, m.test_operand);
        mod = (mod * m.test_operand) / gcd;
        local_monkeys[idx] = try m.clone();
    }
    var monkeys = local_monkeys[0..in_monkeys.len];
    var operand: Int = if (drop_worry_levels) 3 else mod;

    var round: usize = 0;
    while (round < rounds) : (round += 1) {
        for (monkeys) |*m| {
            for (m.items.items) |old| {
                m.total_inspected += 1;
                var new: Int = transform(m.op.execute(old), operand);
                var tval = (new % m.test_operand) == 0;
                try monkeys[m.dest[@boolToInt(tval)]].items.append(new);
            }
            m.items.clearRetainingCapacity();
        }
    }

    var m1: Int = 0;
    var m2: Int = 0;
    for (monkeys) |m| {
        if (m.total_inspected > m1) {
            m2 = m1;
            m1 = m.total_inspected;
        } else if (m.total_inspected > m2) {
            m2 = m.total_inspected;
        }
    }

    return m1 * m2;
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var monkeys = try readMonkeys(stream);
    var part1 = try play(monkeys, 20, true);
    var part2 = try play(monkeys, 10000, false);
    print("{}\n{}\n", .{part1, part2});
}

test {
    const test_data =
        \\Monkey 0:
        \\  Starting items: 79, 98
        \\  Operation: new = old * 19
        \\  Test: divisible by 23
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 3
        \\
        \\Monkey 1:
        \\  Starting items: 54, 65, 75, 74
        \\  Operation: new = old + 6
        \\  Test: divisible by 19
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 0
        \\
        \\Monkey 2:
        \\  Starting items: 79, 60, 97
        \\  Operation: new = old * old
        \\  Test: divisible by 13
        \\    If true: throw to monkey 1
        \\    If false: throw to monkey 3
        \\
        \\Monkey 3:
        \\  Starting items: 74
        \\  Operation: new = old + 3
        \\  Test: divisible by 17
        \\    If true: throw to monkey 0
        \\    If false: throw to monkey 1
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);
    var monkeys = try readMonkeys(stream);
    try expect(try play(monkeys, 20, true) == 10605);
    try expect(try play(monkeys, 10000, false) == 2713310158);
}
