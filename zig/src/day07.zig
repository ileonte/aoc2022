const std = @import("std");
const aoc = @import("aoc");

const expect = std.testing.expect;
const print = std.debug.print;

const FILESISTEM_SIZE: usize = 70000000;
const REQUIRED_UNUSED: usize = 30000000;

const Cwd = aoc.Stack(128, []const u8);
const Dirs = std.StringHashMap(usize);

fn getCwdName(cwd: Cwd, buf: []u8) []u8 {
    var len: usize = 0;
    var idx: usize = 0;

    while (len < buf.len and idx < cwd.view.len) {
        var part = cwd.view[idx];
        var final_len = len + part.len;
        if (!std.mem.endsWith(u8, part, "/"))
            final_len += 1;
        if (final_len > buf.len) break;

        std.mem.copy(u8, buf[len..], part);
        len += part.len;
        if (!std.mem.endsWith(u8, part, "/")) {
            buf[len] = '/';
            len += 1;
        }
        idx += 1;
    }
    return buf[0..len];
}

fn addFile(dirs: Dirs, cwd: Cwd, file_size: usize) !void {
    var my_cwd = cwd.clone();
    var cwd_buf: [512]u8 = undefined;
    var cwd_str: []u8 = getCwdName(my_cwd, &cwd_buf);

    while (my_cwd.size() > 0) {
        var val_ptr = dirs.getPtr(cwd_str) orelse return error.InvalidInput;
        val_ptr.* += file_size;

        var popped = try my_cwd.popVal();
        cwd_str = cwd_str[0..cwd_str.len - popped.len - @boolToInt(!my_cwd.isEmpty())];
    }
}

pub fn traverse(data: [] const u8) !struct{usize, usize} {
    var cwd = Cwd.init();
    var cwd_buf: [512]u8 = undefined;
    var cwd_str: []u8 = undefined;
    var it = std.mem.tokenize(u8, data, "\n");

    var dirs = Dirs.init(std.heap.page_allocator);
    try dirs.ensureUnusedCapacity(16 * 1024);

    while (it.next()) |raw_line| {
        var line = raw_line;
        if (std.mem.startsWith(u8, line, "$ ")) {
            line = line[2..];
            if (std.mem.startsWith(u8, line, "cd ")) {
                line = line[3..];

                if (std.mem.eql(u8, line, "..")) {
                    try cwd.pop();
                } else {
                    try cwd.push(line);
                }

                cwd_str = getCwdName(cwd, &cwd_buf);
                if (!dirs.contains(cwd_str)) {
                    try dirs.put(cwd_str, 0);
                }
            }
        } else {
            if (line.len > 0 and line[0] >= '0' and line[0] <= '9') {
                var line_it = std.mem.tokenize(u8, line, " ");
                var size_part = line_it.next() orelse return error.InvalidInput;
                var file_size = try std.fmt.parseInt(usize, size_part, 0);
                try addFile(dirs, cwd, file_size);
            }
        }
    }

    var total_size = dirs.get("/") orelse return error.InvalidInput;
    var unused = FILESISTEM_SIZE - total_size;
    var size_to_free = REQUIRED_UNUSED - unused;
    var size_of_selected = FILESISTEM_SIZE;

    var part1: usize = 0;
    var dir_it = dirs.iterator();
    while (dir_it.next()) |kv| {
        var dir_size = kv.value_ptr.*;
        if (dir_size < 100000) part1 += dir_size;
        if (dir_size >= size_to_free) size_of_selected = std.math.min(size_of_selected, dir_size);
    }

    return .{part1, size_of_selected};
}

var memory: [2 * 1024 * 1024]u8 = undefined;

pub fn main() !void {
    var in_stream = std.io.getStdIn();
    var stream = aoc.Stream.initFile(&in_stream);
    var size = try stream.readAll(&memory);
    var data = memory[0..size];

    var ret = try traverse(data);
    print("{}\n{}\n", .{ret[0], ret[1]});
}

test {
    const test_data =
        \\$ cd /
        \\$ ls
        \\dir a
        \\14848514 b.txt
        \\8504156 c.dat
        \\dir d
        \\$ cd a
        \\$ ls
        \\dir e
        \\29116 f
        \\2557 g
        \\62596 h.lst
        \\$ cd e
        \\$ ls
        \\584 i
        \\$ cd ..
        \\$ cd ..
        \\$ cd d
        \\$ ls
        \\4060174 j
        \\8033020 d.log
        \\5626152 d.ext
        \\7214296 k
    ;
    var in_stream = std.io.fixedBufferStream(test_data);
    var stream = aoc.Stream.initMem(&in_stream);
    var size = try stream.readAll(&memory);
    var data = memory[0..size];

    var ret = try traverse(data);
    try expect(ret[0] == 95437);
    try expect(ret[1] == 24933642);
}
