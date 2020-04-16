const std = @import("std");
const types = @import("types.zig");
const c = @cImport({
    @cInclude("sqlite3.h");
});

usingnamespace @import("json.zig");

const Allocator = std.mem.Allocator;

const Test = struct {
    field1: i64,
    field2: []const u8,
};

pub fn main() anyerror!void {
    var db: ?*sqlite3 = undefined;
    var rc: c_int = undefined;

    rc = c.sqlite3_open("./test.db", &db);
    if (rc > 0) {
        std.debug.warn("Can't open database: {}\n", .{c.sqlite3_errmsg(db)});
        return;
    }
    defer sqlite3_close(db);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    
}
