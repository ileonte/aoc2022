const std = @import("std");

const int = i64;

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const gpa = general_purpose_allocator.allocator();

    var vals = try std.ArrayList(int).initCapacity(gpa, 512);
    defer vals.deinit();

    var buf : [1024]u8 = .{};
    var current : int = 0;

    while (std.io.getStdIn().reader().readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var data = raw_data orelse break;
        if (data.len > 0 and data[data.len - 1] == 13)
            data = data[0..data.len - 1];
        if (data.len == 0) {
            try vals.append(current);
            current = 0;
        } else {
            var v = try std.fmt.parseInt(int, data, 0);
            current = current + v;
        }
    } else |err| {
        return err;
    }

    const items = vals.items;
    if (items.len >= 3) {
        std.sort.sort(int, vals.items, {}, std.sort.asc(int));
        const result = items[items.len - 3 .. items.len];
        std.debug.print("{?}\n{?}\n", .{
            result[2],
            result[0] + result[1] + result[2]
        });
    }
}
