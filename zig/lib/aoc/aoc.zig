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
