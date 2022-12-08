const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;
const print = std.debug.print;

const Allocator = std.mem.Allocator;

const Grid = struct {
    const LineIterator = struct {
        grid: *Grid,
        next_line: usize,

        pub fn next(self: *LineIterator) ?[]u8 {
            if (self.next_line >= self.grid.*.height) return null;
            var ret = self.grid.getLine(self.next_line) catch return null;
            self.next_line += 1;
            return ret[1..self.grid.*.width + 1];
        }
    };

    data: []u8,
    width: usize,
    height: usize,
    stride: usize,

    allocator: Allocator,

    const Self = @This();

    pub fn fromStream(stream: aoc.Stream, allocator: Allocator) !Self {
        var ret: Self = undefined;
        var w: usize = 0;
        var h: usize = 0;
        var s: usize = 0;

        var line = try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024) orelse return error.InvalidInput;
        w = line.len;
        h = line.len;
        s = w + 2;
        allocator.free(line);

        ret.data = try allocator.alloc(u8, s * s);
        errdefer allocator.free(ret.data);

        @memset(ret.data.ptr, ' ', ret.data.len);

        try stream.seekTo(0);
        var idx: usize = 1;
        outer: while (idx <= h) : (idx += 1) {
            line = try stream.read(ret.data[idx * s + 1..idx * s + w + 1]);
            try expect(line.len == w);

            var b: [1]u8 = undefined;
            var eol = try stream.read(&b);
            if (eol.len == 0) break;
            switch (eol[0]) {
                '\r' => {
                    eol = try stream.read(&b);
                    if (eol.len == 0) break :outer;
                    try expect(eol[0] == '\n');
                },
                '\n' => {},
                else => return error.InvalidInput,
            }
        }

        ret.width = w;
        ret.height = h;
        ret.stride = s;
        ret.allocator = allocator;
        return ret;
    }

    pub fn destroy(self: *Self) void {
        self.allocator.free(self.data);
        self.data = undefined;
        self.width = 0;
        self.height = 0;
        self.stride = 0;
        self.allocator = undefined;
    }

    pub fn lineIterator(self: *Self) LineIterator {
        return LineIterator {
            .grid = self,
            .next_line = 1,
        };
    }

    pub fn getLine(self: Self, y: usize) ![]u8 {
        try expect(y < self.stride);
        return self.data[y * self.stride..(y + 1) * self.stride];
    }

    pub fn checkVisibility(self: Self, x: usize, y: usize) !struct{usize, usize} {
        try expect(x >= 2 and x < self.width);
        try expect(y >= 2 and y < self.height);

        var line = try self.getLine(y);
        var v = line[x];
        var vis_left: usize = 1;
        var vis_right: usize = 1;
        var score_left: usize = 0;
        var score_right: usize = 0;
        var dx = x - 1;
        while (dx > 0) : (dx -= 1) {
            score_left += 1;
            if (line[dx] >= v) {
                vis_left = 0;
                break;
            }
        }
        dx = x + 1;
        while (dx <= self.width) : (dx += 1) {
            score_right += 1;
            if (line[dx] >= v) {
                vis_right = 0;
                break;
            }
        }

        var vis_top: usize = 1;
        var vis_bot: usize = 1;
        var score_top: usize = 0;
        var score_bot: usize = 0;
        var dy = y - 1;
        while (dy > 0) : (dy -= 1) {
            score_top += 1;
            line = try self.getLine(dy);
            if (line[x] >= v) {
                vis_top = 0;
                break;
            }
        }
        dy = y + 1;
        while (dy <= self.height) : (dy += 1) {
            score_bot += 1;
            line = try self.getLine(dy);
            if (line[x] >= v) {
                vis_bot = 0;
                break;
            }
        }

        return .{
            std.math.min(vis_top + vis_right + vis_bot + vis_left, 1),
            score_top * score_right * score_bot * score_left,
        };
    }
};

fn countVisibleTrees(grid: Grid) !struct{usize, usize} {
    var base: usize = 2 * grid.width + 2 * (grid.height - 2);
    var count: usize = 0;
    var score: usize = 0;

    var y: usize = 2;
    while (y <= grid.height - 1) : (y += 1) {
        var x: usize = 2;
        while (x <= grid.width - 1) : (x += 1) {
            var visibility = try grid.checkVisibility(x, y);
            count += visibility[0];
            score = std.math.max(score, visibility[1]);
        }
    }

    return .{base + count, score};
}

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var grid = try Grid.fromStream(stream, std.heap.page_allocator);
    var ret = try countVisibleTrees(grid);
    print("{}\n{}\n", .{ret[0], ret[1]});
}

test {
    const test_data =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);
    var grid = try Grid.fromStream(stream, std.heap.page_allocator);
    var ret = try countVisibleTrees(grid);
    try expect(ret[0] == 21);
    try expect(ret[1] == 8);
}
