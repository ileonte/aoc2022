const std = @import("std");

pub const Stream = struct {
    pub const Type = enum {
        File,
        Memory,
    };

    type: Type,
    file: ?*std.fs.File,
    mem: ?*std.io.FixedBufferStream([] const u8),

    const Self = @This();

    pub fn initFile(file: *std.fs.File) Self {
        return .{
            .type = .File,
            .file = file,
            .mem = null,
        };
    }

    pub fn initMem(mem: *std.io.FixedBufferStream([] const u8)) Self {
        return .{
            .type = .Memory,
            .file = null,
            .mem = mem,
        };
    }

    pub fn getPos(self: *const Self) !u64 {
        return switch (self.type) {
            .File   => self.file.?.getPos(),
            .Memory => self.mem.?.getPos(),
        };
    }

    pub fn seekTo(self: *const Self, pos: u64) !void {
        return switch (self.type) {
            .File   => self.file.?.seekTo(pos),
            .Memory => self.mem.?.seekTo(pos),
        };
    }

    pub fn read(self: *const Self, buffer: []u8) ![]u8 {
        var count = switch (self.type) {
            .File   => try self.file.?.reader().read(buffer),
            .Memory => try self.mem.?.reader().read(buffer),
        };
        return buffer[0..count];
    }

    pub fn readUntilDelimiterOrEof(self: *const Self, buf: []u8, delimiter: u8) !?[]u8 {
        return switch (self.type) {
            .File   => self.file.?.reader().readUntilDelimiterOrEof(buf, delimiter),
            .Memory => self.mem.?.reader().readUntilDelimiterOrEof(buf, delimiter),
        };
    }

    pub fn readUntilDelimiterOrEofAlloc(self: *const Self, allocator: std.mem.Allocator, delimiter: u8, max_size: usize) !?[]u8 {
        return switch (self.type) {
            .File   => self.file.?.reader().readUntilDelimiterOrEofAlloc(allocator, delimiter, max_size),
            .Memory => self.mem.?.reader().readUntilDelimiterOrEofAlloc(allocator, delimiter, max_size),
        };
    }

    pub fn readAll(self: *const Self, buf: []u8) !usize {
        return switch (self.type) {
            .File   => self.file.?.readAll(buf),
            .Memory => self.mem.?.read(buf),
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
