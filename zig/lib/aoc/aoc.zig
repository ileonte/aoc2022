const std = @import("std");

pub const Stream = union(enum) {
    file: *std.fs.File,
    mem: *std.io.FixedBufferStream([] const u8),

    const Self = @This();

    pub fn initFile(file: *std.fs.File) Self {
        return .{
            .file = file,
        };
    }

    pub fn initMem(mem: *std.io.FixedBufferStream([] const u8)) Self {
        return .{
            .mem = mem,
        };
    }

    pub fn getPos(self: *const Self) !u64 {
        return switch (self.*) {
            Stream.file => |file| file.getPos(),
            Stream.mem  => |memf| memf.getPos(),
        };
    }

    pub fn seekTo(self: *const Self, pos: u64) !void {
        return switch (self.*) {
            Stream.file => |file| file.seekTo(pos),
            Stream.mem  => |memf| memf.seekTo(pos),
        };
    }

    pub fn read(self: *const Self, buffer: []u8) ![]u8 {
        var count = switch (self.*) {
            Stream.file => |file| try file.reader().read(buffer),
            Stream.mem  => |memf| try memf.reader().read(buffer),
        };
        return buffer[0..count];
    }

    pub fn readUntilDelimiterOrEof(self: *const Self, buf: []u8, delimiter: u8) !?[]u8 {
        return switch (self.*) {
            Stream.file => |file| file.reader().readUntilDelimiterOrEof(buf, delimiter),
            Stream.mem  => |memf| memf.reader().readUntilDelimiterOrEof(buf, delimiter),
        };
    }

    pub fn readUntilDelimiterOrEofAlloc(self: *const Self, allocator: std.mem.Allocator, delimiter: u8, max_size: usize) !?[]u8 {
        return switch (self.*) {
            Stream.file => |file| file.reader().readUntilDelimiterOrEofAlloc(allocator, delimiter, max_size),
            Stream.mem  => |memf| memf.reader().readUntilDelimiterOrEofAlloc(allocator, delimiter, max_size),
        };
    }

    pub fn readAll(self: *const Self, buf: []u8) !usize {
        return switch (self.*) {
            Stream.file => |file| file.readAll(buf),
            Stream.mem  => |memf| memf.read(buf),
        };
    }
};

pub fn Stack(comptime max_size: usize, comptime T: type) type {
    comptime try std.testing.expect(max_size > 0);

    return struct {
        const Self = @This();
        const capacity = max_size;
        const item_type = T;

        data: [capacity]item_type,
        view: []item_type,

        pub fn init() Self {
            var ret: Self = undefined;
            ret.view = ret.data[0..0];
            return ret;
        }

        pub fn size(self: *const Self) usize {
            return self.view.len;
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.view.len == 0;
        }

        pub fn push(self: *Self, item: item_type) !void {
            if (self.view.len >= capacity) return error.OutOfSpace;
            self.data[self.view.len] = item;
            self.view = self.data[0..self.view.len + 1];
        }

        pub fn pop(self: *Self) !void {
            if (self.view.len == 0) return error.NoMoreItems;
            self.view = self.data[0..self.view.len - 1];
        }

        pub fn popVal(self: *Self) !item_type {
            if (self.view.len == 0) return error.NoMoreItems;
            self.view = self.data[0..self.view.len - 1];
            return self.data[self.view.len];
        }

        pub fn clone(self: *const Self) Self {
            var ret: Self = undefined;
            ret.data = self.data;
            ret.view = ret.data[0..self.view.len];
            return ret;
        }
    };
}
