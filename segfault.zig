const std = @import("std");

fn toCamelCase(str: []const u8, buf: []u8) []const u8 {
    var i: usize = 0;
    var off: usize = 0;
    while (i + off < str.len) : (i += 1) {
        if (str[i + off] == '_') {
            off += 1;
            buf[i] = std.ascii.toUpper(str[i + off]);
        } else {
            buf[i] = str[i + off];
        }
    }
    return buf[0..str.len - off];
}

pub fn main() void {
    const camelCased = comptime blk: {
        const name = "snake_case";
        var buf: [name.len]u8 = undefined;
        break :blk toCamelCase(name, buf[0..]);
    };

    std.debug.warn("{}\n", .{camelCased});
}
