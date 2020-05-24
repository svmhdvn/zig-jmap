const std = @import("std");
const json = @import("../json.zig");

const Value = std.json.Value;
const Array = std.json.Array;
const ObjectMap = std.json.ObjectMap;
const StringHashMap = std.StringHashMap;

const expect = std.testing.expect;

// JsonStringMap

fn jsonEqualArrays(expected: Array, actual: Array) bool {
    const sliceExpected = expected.span();
    const sliceActual = actual.span();

    if (sliceActual.len != sliceExpected.len) return false;
    var i: usize = 0;
    return while (i < sliceExpected.len) : (i += 1) {
        if (!jsonEqual(sliceExpected[i], sliceActual[i])) break false;
    } else true;
}

fn jsonEqualObjects(expected: ObjectMap, actual: ObjectMap) bool {
    if (expected.count() != actual.count()) return false;
    var it = expected.iterator();
    return while (it.next()) |kv| {
        const actual_val = actual.getValue(kv.key) orelse break false;
        if (!jsonEqual(kv.value, actual_val)) break false;
    } else true;
}

fn jsonEqual(expected: Value, actual: Value) bool {
    return (@enumToInt(actual) == @enumToInt(expected)) and
        switch (expected) {
            .Null => true,
            .Bool => |b| actual.Bool == b,
            .Integer => |i| actual.Integer == i,
            .Float => |f| actual.Float == f,
            .String => |s| std.mem.eql(u8, s, actual.String),
            .Array => |a| jsonEqualArrays(a, actual.Array),
            .Object => |o| jsonEqualObjects(o, actual.Object),
        };
}

test "JsonStringMap" {
    const Test = struct {
        str_to_bool: json.JsonStringMap(bool),
        something: u64,
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var parser = std.json.Parser.init(allocator, false);

    {
        const s =
            \\{
            \\    "strToBool": {
            \\        "boolOne": true,
            \\        "boolTwo": false,
            \\        "bool3": true
            \\    },
            \\    "something": 42
            \\}
        ;

        var map = StringHashMap(bool).init(allocator);
        try map.ensureCapacity(3);
        _ = map.putAssumeCapacity("boolOne", true);
        _ = map.putAssumeCapacity("boolTwo", false);
        _ = map.putAssumeCapacity("bool3", true);
        const test_val = Test{
            .str_to_bool = json.JsonStringMap(bool){ .map = map },
            .something = 42,
        };
        
        const expected_tree = try parser.parse(s);
        const actual = try json.serialize(allocator, test_val);
        expect(jsonEqual(expected_tree.root, actual));
    }
}
