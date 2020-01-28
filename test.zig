const std = @import("std");

pub fn main() void {
    defer std.debug.warn("I got cancelled!");
    var i: i64 = 32;
    while (true) {
        i *= -1;
    }
}
