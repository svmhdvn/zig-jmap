const std = @import("std");
const types = @import("types.zig");
const m = @import("method.zig");

usingnamespace @import("json.zig");

const CrazyType = m.DataType(types.UnsignedInt).Get.Request;

const TestStruct = struct {
    name: []const u8,
    map_val: JsonStringMap(CrazyType),
    other_thing: types.UnsignedInt,
};

pub fn main() anyerror!void {
    const out = &std.io.getStdOut().outStream().stream;
    var w = std.json.WriteStream(@TypeOf(out).Child, 10).init(out);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const ids1: [3]types.Id = .{"id #1", "id #2", "id #3"};
    const val1 = CrazyType{
        .account_id = "account id #1",
        .ids = ids1[0..],
        .properties = null,
        //.properties: ?[]const []const u8,
    };

    const ids2: [2]types.Id = .{"id #4", "id #5"};
    const val2 = CrazyType{
        .account_id = "account id #2",
        .ids = ids2[0..],
        .properties = null,
        //.properties: ?[]const []const u8,
    };

    var map = std.StringHashMap(CrazyType).init(allocator);
    try map.ensureCapacity(2);
    _ = map.putAssumeCapacity("key#1", val1);
    _ = map.putAssumeCapacity("key#2", val2);

    const final_val = TestStruct{
        .name = "hello moto",
        .map_val = JsonStringMap(CrazyType){ .map = map },
        .other_thing = 48,
    };

    const json_val = try json_serializer.toJson(final_val, allocator);

    try w.emitJson(json_val);
}
