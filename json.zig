const std = @import("std");
const types = @import("types");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const Array = std.json.Array;
const ObjectMap = std.json.ObjectMap;
const assert = std.debug.assert;

// TODO determine whether memory copies are needed here. For now, assume that
// they are unnecessary.
/// Serializes `obj` into a JSON `Value`.
pub fn serialize(allocator: *Allocator, obj: var) Allocator.Error!Value {
    const T = @TypeOf(obj);

    // If the object defines its own custom serialization function, use it as an
    // override. Note that we can't simply check it in the `Struct` case below
    // because we may define `toJson` on enums [RFC 8620 5.5].
    if (comptime std.meta.trait.hasFn("toJson")(T)) {
        return T.toJson(allocator, obj);
    }

    const type_info = @typeInfo(T);
    return switch (type_info) {
        .Array => .{ .Array = try serializeArray(allocator, obj) },
        .Bool => .{ .Bool = obj },
        // TODO camelCase enum value string
        .Enum => .{ .String = @tagName(obj) },
        .Float, .ComptimeFloat => .{ .Float = obj },
        .Int, .ComptimeInt => .{ .Integer = @intCast(i64, obj) },

        .Optional => if (obj) |val| serialize(allocator, val) else .Null,

        .Pointer => |p| if (p.child == u8)
            .{ .String = obj }
        else switch (p.size) {
            .One => serialize(allocator, thing.*),
            .Many, .Slice => .{ .Array = try serializeArray(allocator, thing) },
            else => .Null
        },

        .Struct => .{ .Object = try serializeStruct(allocator, obj) },

        // We have no reason to be using bare unions, so we don't handle that
        // case here.
        .Union => |u| blk: {
            //const tag_int = @enumToInt(std.meta.activeTag(thing));
            //inline for (u.fields) |field| {
            //    if (tag_int == field.enum_field.?.value) {
            //        break :blk toJson(@field(thing, field.name), allocator);
            //    }
            //}
            //unreachable;
            break :blk serialize(allocator, @field(obj, @tagName(obj)));
        },
        // TODO figure out if we should rather return an error here.
        else => .Null,
    };
}



// TODO I don't think we need this data type? Can't we just copy the given
// object map directly?
pub fn JsonStringMap(comptime V: type) type {
    return struct {
        const Self = @This();

        map: std.StringHashMap(V),

        pub fn toJson(self: Self, allocator: *Allocator) Allocator.Error!Value {
            var map = ObjectMap.init(allocator);
            try map.ensureCapacity(self.map.count());

            var it = self.map.iterator();
            while (it.next()) |kv| {
                const json_val = try json_serializer.toJson(kv.value, allocator);
                _ = map.putAssumeCapacity(kv.key, json_val);
            }

            return Value{ .Object = map };
        }
    };
}

fn fromJsonArray(comptime T: type, allocator: *Allocator, arr: Array) !T {
    const type_info = @typeInfo(T);

    switch (@typeId(T)) {
        .Pointer => {
            // TODO figure out if this assumption is correct
            if (type_info.Pointer.Size != .Slice) {
                return error.CannotDeserialize;
            }

            const Child = type_info.Pointer.child;
            const result = try allocator.alloc(Child, arr.len);
            for (result) |*ptr, i| {
                const arr_val = arr.at(i);
                ptr.* = try fromJson(Child, allocator, arr_val);
            }
            return result;
        },

        .Array => {
            const Child = type_info.Array.child;
            if (arr.len != type_info.Array.len) {
                return error.CannotDeserialize;
            }
            var result: T = undefined;
            for (result) |*ptr, i| {
                const arr_val = arr.at(i);
                ptr.* = try fromJson(Child, allocator, arr_val);
            }
            return result;
        },

        else => error.CannotDeserialize,
    }
}

fn fromJsonObject(comptime T: type, allocator: *Allocator, obj: ObjectMap) !T {
    const type_info = @typeInfo(T);
    var result: T = undefined;

    inline for (type_info.Struct.fields) |f| {
        const camel_cased = comptime blk: {
            var buf: [f.name.len]u8 = undefined;
            break :blk snakeToCamel(f.name, buf[0..]);
        };

        if (obj.getValue(camel_cased)) |val| {
            @field(result, f.name) = try fromJson(f.field_type, allocator, val);
        } else if (@typeId(f.field_type) == .Optional) {
            @field(result, f.name) = null;
        } else {
            return error.CannotDeserialize;
        }
    }

    return result;
}

fn verifyAndReturn(comptime T: type, comptime tag: @TagType(Value), obj: Value) !T {
    return if (obj == tag)
        @field(obj, @tagName(tag))
    else
        error.CannotDeserialize;
}

pub fn fromJson(comptime T: type, allocator: *Allocator, val: Value) !T {
    if (T == []const u8) {
        if (val != .String) return error.CannotDeserialize;
        return std.mem.dupe(allocator, u8, val.String);
    }

    // TODO figure out if I need comptime assertions here
    // TODO do proper integer range checking to convert from i to u
    // TODO clean this up to reduce duplicate "return error" code
    return switch (@typeInfo(T)) {
        .Bool => verifyAndReturn(T, .Bool, val),
        .Int => verifyAndReturn(T, .Integer, val),
        .Float => verifyAndReturn(T, .Float, val),

        .Pointer, .Array => if (val != .Array)
            error.CannotDeserialize
        else
            fromJsonArray(T, allocator, val.Array),

        .Optional => if (val == .Null)
            null
        else
            try fromJson(T.Child, allocator, val),

        .Struct => if (val != .Object)
            error.CannotDeserialize;
        else if (comptime std.meta.trait.hasFn("fromJson")(T))
            T.fromJson(allocator, obj.Object)
        else
            fromJsonObject(T, allocator, obj.Object),

        else => error.CannotDeserialize,
    };
}

fn serializeStruct(allocator: *Allocator, obj: var) Allocator.Error!ObjectMap {
    const T = @Type(obj);
    // If `obj` is already a JSON value, we're done.
    if (T == Value) {
        return obj;
    }
    
    // If `obj` is a JSON object, just wrap it up into a JSON value.
    if (T == ObjectMap) {
        return .{ .Object = obj };
    }

    // We do not handle the `Array` case of `Value` because we expect it
    // to never end up in our code. If it somehow did, why wouldn't we
    // simply use a regular slice?

    var map = ObjectMap.init(allocator);
    try map.ensureCapacity(s.fields.len);
    inline for (s.fields) |field| {
        const name = field.name;
        const camel_cased = comptime blk: {
            var buf: [name.len]u8 = undefined;
            break :blk snakeToCamel(name, buf[0..]);
        };

        const field_json = try serialize(allocator, @field(obj, name));
        _ = map.putAssumeCapacity(camel_cased, field_json);
    }

}

fn serializeArray(thing: var, allocator: *Allocator) Allocator.Error!Array {
    var arr = try Array.initCapacity(allocator, thing.len);
    for (thing) |el| {
        arr.appendAssumeCapacity(try toJson(el, allocator));
    }
    return arr;
}

// TODO write tests for snake case and camel case
/// Converts `str` from camel
fn camelToSnake(str: []const u8, buf: []u8) []const u8 {
    var i: usize = 0;
    var off: usize = 0;
    while (i < str.len) : (i += 1) {
        if (std.ascii.isUpper(str[i])) {
            buf[i + off] = '_';
            buf[i + off + 1] = std.ascii.toLower(str[i]);
            off += 1;
        } else {
            buf[i + off] = str[i];
        }
    }
    return buf[0 .. str.len + off];
}

fn snakeToCamel(str: []const u8, buf: []u8) []const u8 {
    var i: usize = 0;
    var off: usize = 0;
    while (i + off < str.len) : (i += 1) {
        if (str[i + off] == '_') {
            buf[i] = std.ascii.toUpper(str[i + off + 1]);
            off += 1;
        } else {
            buf[i] = str[i + off];
        }
    }
    return buf[0 .. str.len - off];
}

