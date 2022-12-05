const std = @import("std");
const aoc = @import("aoc");
const print = std.debug.print;

const Stacks = struct {
    const StackType = [256]u8;
    const ViewType = []u8;
    const DataType = std.ArrayList(StackType);
    const ViewsType = std.ArrayList(ViewType);
    const Self = @This();

    data: DataType,
    views: ViewsType,

    pub fn clone(self: *Self) !Self {
        var data = try self.data.clone();
        errdefer data.deinit();
        var views = try Self.ViewsType.initCapacity(std.heap.page_allocator, data.items.len);
        for (data.items) |*stack, idx| {
            var view = try views.addOne();
            view.* = stack.*[0..self.views.items[idx].len];
        }
        return Self {
            .data = data,
            .views = views,
        };
    }

    pub fn deinit(self: Self) void {
        self.data.deinit();
        self.views.deinit();
    }
};

fn readStacks(stream: aoc.Stream) !Stacks {
    var current_pos = try stream.getPos();
    var buffer: [4096]u8 = undefined;
    var data = try stream.read(&buffer);
    var split_pos = std.mem.indexOf(u8, data, "\n\n") orelse {
        try stream.seekTo(current_pos);
        return error.InvalidInput;
    };
    try stream.seekTo(split_pos + 2);

    data = data[0..split_pos];

    var stack_lines: [256][] const u8 = undefined;
    var stack_view: [][] const u8 = stack_lines[0..0];
    var stack_count: usize = 0;

    var line_it = std.mem.tokenize(u8, data, "\n");
    while (line_it.next()) |line| {
        if (std.mem.indexOf(u8, line, "[") != null) {
            stack_lines[stack_view.len] = line;
            stack_view = stack_lines[0..stack_view.len + 1];
        } else {
            var it = std.mem.tokenize(u8, line, " ");
            while (it.next()) |_| stack_count += 1;
        }
    }

    var stacks = try Stacks.DataType.initCapacity(std.heap.page_allocator, stack_count);
    errdefer stacks.deinit();
    var views = try Stacks.ViewsType.initCapacity(std.heap.page_allocator, stack_count);
    errdefer views.deinit();

    var i: usize = 0;
    while (i < stack_count) : (i += 1) {
        var stack = try stacks.addOne();
        var view = try views.addOne();
        view.* = stack[0..0];
    }

    i = stack_view.len;
    while (i > 0) : (i -= 1) {
        var line = stack_view[i - 1];
        var ch_idx: usize = 1;
        var stack_idx: usize = 0;

        while (ch_idx < line.len) : (ch_idx += 4) {
            if (line[ch_idx] == ' ') {
                 stack_idx += 1;
                continue;
            }

            var stack = &stacks.items[stack_idx];
            var view  = &views.items[stack_idx];
            stack[view.len] = line[ch_idx];
            view.* = stack[0..view.len + 1];

             stack_idx += 1;
        }
    }

    return Stacks {
        .data = stacks,
        .views = views,
    };
}

const Move = struct {
    from: usize,
    to: usize,
    count: usize,
};

fn readMoves(stream: aoc.Stream) !std.ArrayList(Move) {
    var ret = try std.ArrayList(Move).initCapacity(std.heap.page_allocator, 1024);
    var buf: [256]u8 = undefined;
    while (stream.readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var move: Move = undefined;
        var data = raw_data orelse return ret;

        var it = std.mem.tokenize(u8, data, " ");
        try std.testing.expectEqualSlices(u8, it.next().?, "move");
        move.count = try std.fmt.parseInt(usize, it.next().?, 0);
        try std.testing.expectEqualSlices(u8, it.next().?, "from");
        move.from = try std.fmt.parseInt(usize, it.next().?, 0);
        try std.testing.expectEqualSlices(u8, it.next().?, "to");
        move.to = try std.fmt.parseInt(usize, it.next().?, 0);

        try ret.append(move);
    } else |err| {
        return err;
    }
    return ret;
}

const MoveType = enum {
    Sequential,
    Bulk,
};

fn executeMoves(move_type: MoveType, in_stacks: *Stacks, moves: std.ArrayList(Move), buf: []u8) ![]u8 {
    var stacks = try in_stacks.clone();
    defer stacks.deinit();

    try std.testing.expect(stacks.data.items.len == stacks.views.items.len);
    try std.testing.expect(stacks.data.items.len <= buf.len);

    for (moves.items) |move| {
        try std.testing.expect(move.from >= 1 and move.from <= stacks.data.items.len);
        try std.testing.expect(move.to >= 1 and move.to <= stacks.data.items.len);

        var src_stack = &stacks.data.items[move.from - 1];
        var dst_stack = &stacks.data.items[move.to - 1];
        var src_view  = &stacks.views.items[move.from - 1];
        var dst_view  = &stacks.views.items[move.to - 1];

        switch (move_type) {
            .Sequential => {
                var i: usize = 0;
                while (i < move.count) : (i += 1) {
                    dst_stack.*[dst_view.len] = src_stack.*[src_view.len - 1];
                    dst_view.* = dst_stack[0..dst_view.len + 1];
                    src_view.* = src_stack[0..src_view.len - 1];
                }
            },
            .Bulk => {
                std.mem.copy(u8, dst_stack.*[dst_view.len..], src_stack.*[src_view.len - move.count..src_view.len]);
                dst_view.* = dst_stack[0..dst_view.len + move.count];
                src_view.* = src_stack[0..src_view.len - move.count];
            },
        }
    }

    for (stacks.views.items) |view, idx| {
        buf[idx] = view[view.len - 1];
    }
    return buf[0..stacks.data.items.len];
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);

    var stacks = try readStacks(stream);
    var moves = try readMoves(stream);

    var ret_buf: [64]u8 = undefined;
    var ret = try executeMoves(.Sequential, &stacks, moves, &ret_buf);
    print("{s}\n", .{ret});

    ret = try executeMoves(.Bulk, &stacks, moves, &ret_buf);
    print("{s}\n", .{ret});
}

test {
    const test_data =
        \\    [D]
        \\[N] [C]
        \\[Z] [M] [P]
        \\ 1   2   3
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);

    var stacks = try readStacks(stream);
    var moves = try readMoves(stream);

    var ret_buf: [64]u8 = undefined;
    var ret = try executeMoves(.Sequential, &stacks, moves, &ret_buf);
    try std.testing.expectEqualSlices(u8, ret, "CMZ");

    ret = try executeMoves(.Bulk, &stacks, moves, &ret_buf);
    try std.testing.expectEqualSlices(u8, ret, "MCD");
}
