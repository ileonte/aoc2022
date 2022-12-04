const std = @import("std");

pub const Reader = struct {
    pub const Type = enum {
        File,
        Memory,
    };

    type: Type,
    file_reader: ?std.fs.File.Reader,
    mem_reader: ?std.io.FixedBufferStream([] const u8).Reader,

    const Self = @This();

    pub fn initFile(file: *std.fs.File) Self {
        return .{
            .type = .File,
            .file_reader = file.reader(),
            .mem_reader = null,
        };
    }

    pub fn initMem(mem: *std.io.FixedBufferStream([] const u8)) Self {
        return .{
            .type = .Memory,
            .file_reader = null,
            .mem_reader = mem.reader()
        };
    }

    pub fn readUntilDelimiterOrEof(self: *Self, buf: []u8, delimiter: u8) !?[]u8 {
        return switch (self.type) {
            .File => self.file_reader.?.readUntilDelimiterOrEof(buf, delimiter),
            .Memory => self.mem_reader.?.readUntilDelimiterOrEof(buf, delimiter),
        };
    }
};
