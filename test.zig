const std = @import("std");
const m = @import("method.zig");
const types = @import("types.zig");

usingnamespace @import("json.zig");

pub fn main() anyerror!void {
    const out = &std.io.getStdOut().outStream().stream;
    var w = std.json.WriteStream(@TypeOf(out).Child, 10).init(out);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const ids: [3]types.Id = .{"id #1", "id #2", "id #3"};
    const val = m.DataType(types.UnsignedInt).Get.Request{
        .account_id = "account id #1",
        .ids = ids[0..],
        .properties = null,
        //.properties: ?[]const []const u8,
    };
    const json_val = try json_serializer.toJson(val, allocator);

    try w.emitJson(json_val);
}
