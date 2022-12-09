const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;
const print = std.debug.print;

const Position = struct {
    x: i16 = 0,
    y: i16 = 0,

    pub fn toStorage(pos: Position) u32 {
        return (@bitCast(u32, @intCast(i32, pos.x)) << 16) | (@bitCast(u32, @intCast(i32, pos.y)) & 0x0000ffff);
    }

    pub fn fromStorage(pos: *Position, storage: u32) void {
        pos.x = @truncate(i16, @bitCast(i32, storage));
        pos.y = @truncate(i16, @bitCast(i32, (storage >> 16) & 0x0000ffff));
    }

    pub fn distanceTo(self: Position, other: Position) u16 {
        return std.math.max(
            std.math.absCast(self.x - other.x),
            std.math.absCast(self.y - other.y)
        );
    }

    pub fn eql(self: Position, other: Position) bool {
        return self.x == other.x and self.y == other.y;
    }

    const MoveIterator = struct {
        current: Position,
        desired: Position,

        pub fn next(it: *MoveIterator) ?Position {
            if (it.current.eql(it.desired)) return null;
            it.*.current.x += std.math.sign(it.desired.x - it.current.x);
            it.*.current.y += std.math.sign(it.desired.y - it.current.y);
            return it.current;
        }
    };
    pub fn moveTo(self: Position, move: [] const u8) !MoveIterator {
        try expect(move.len >= 3);
        try expect(move[1] == ' ');
        var count = try std.fmt.parseInt(i16, move[2..], 0);

        var desired: Position = self;
        switch (move[0]) {
            'U' => desired.y += count,
            'D' => desired.y -= count,
            'R' => desired.x += count,
            'L' => desired.x -= count,
            else => return error.InvalidInput,
        }

        return MoveIterator {
            .current = self,
            .desired = desired,
        };
    }

    const DistanceMoveIterator = struct {
        current: Position,
        desired: Position,
        distance: u16,

        pub fn next(it: *DistanceMoveIterator) ?Position {
            if (it.current.distanceTo(it.desired) <= it.distance) return null;
            it.*.current.x += std.math.sign(it.desired.x - it.current.x);
            it.*.current.y += std.math.sign(it.desired.y - it.current.y);
            return it.current;
        }
    };
    pub fn moveTowards(self: Position, target: Position, min_distance: u16) DistanceMoveIterator {
        return DistanceMoveIterator {
            .current = self,
            .desired = target,
            .distance = min_distance,
        };
    }
};

const IntSet = std.AutoHashMap(u32, void);
const Rope = []Position;

fn simulateRope(comptime initial: bool, head: Position, rope: Rope, set1: *IntSet, set2: *IntSet) !void {
    if (rope.len == 0) return;
    var tail_it = rope[0].moveTowards(head, 1);
    while (tail_it.next()) |tpos| {
        if (initial) try set1.put(tpos.toStorage(), void{});
        if (rope.len == 1) try set2.put(tpos.toStorage(), void{});
    }
    rope[0] = tail_it.current;
    try simulateRope(false, rope[0], rope[1..], set1, set2);
}

fn compute(stream: aoc.Stream) !struct{u64, u64} {
    var buf: [64]u8 = undefined;

    var head = Position{};
    var rope = [9]Position{.{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{}};

    var set1 = IntSet.init(std.heap.page_allocator);
    try set1.ensureUnusedCapacity(4096);
    var set2 = IntSet.init(std.heap.page_allocator);
    try set2.ensureUnusedCapacity(4096);

    try set1.put(head.toStorage(), void{});
    try set2.put(head.toStorage(), void{});

    while (stream.readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var data = raw_data orelse break;
        var head_it = try head.moveTo(data);
        while (head_it.next()) |hpos| {
            try simulateRope(true, hpos, &rope, &set1, &set2);
        }
        head = head_it.current;
    } else |err| {
        return err;
    }

    return .{set1.count(), set2.count()};
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var ret = try compute(stream);
    print("{}\n{}\n", .{ret[0], ret[1]});
}

test "simple" {
    var test_data =
        \\R 4
        \\U 4
        \\L 3
        \\D 1
        \\R 4
        \\D 1
        \\L 5
        \\R 2
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);
    var ret = try compute(stream);
    try expect(ret[0] == 13);
}

test "complex" {
    var test_data =
        \\R 5
        \\U 8
        \\L 8
        \\D 3
        \\R 17
        \\D 10
        \\L 25
        \\U 20
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);
    var ret = try compute(stream);
    try expect(ret[1] == 36);
}
