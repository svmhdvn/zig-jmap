const std = @import("std");
const types = @import("types.zig");
usingnamespace @import("json.zig");

const Allocator = std.mem.Allocator;

const Test = struct {
    field1: i64,
    field2: []const []const u8,
    field3: ?i64,
};

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const str_json = "{\"field1\": 42, \"field2\": [\"hi\", \"yo\", \"sup\"], \"field3\": null}";
    std.debug.warn("orig: {}\n", .{str_json});

    var parser = std.json.Parser.init(allocator, false);
    const tree = try parser.parse(str_json);

    const deserialized = try json_deserializer.fromJson(Test, allocator, tree.root);
    for (deserialized.field2) |str| {
        std.debug.warn("deserialized: {}\n", .{str});
    }
}
