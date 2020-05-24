/// Custom JSON (de)serializer functions. List of unsupported data types:
/// - Union: handling generic unions would require backtracking in the parser
/// - Enum: this can be accomodated fairly easily, but it requires iterating
/// through all the possible field names in the enum and string-comparing each one
/// against the value in the JSON object. This is a little cumbersome and
/// unnecessary since we have `{to,from}Json` custom methods to use.
/// - Non-slice pointers: JSON objects have no support for pointing to memory,
/// so we only care about slices so that we can work with JSON arrays.
/// All operations are NON-COPYING. This means that the memory is owned by the
/// original value that is being (de)serialized and that only references are
/// made to the original memory.

// TODO determine if memory copies are required (or optional).

const std = @import("std");
const types = @import("types");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const Array = std.json.Array;
const ObjectMap = std.json.ObjectMap;
const assert = std.debug.assert;

/// Convenience type that wraps a Map of String -> V with automatically
/// generated {from,to}Json functions.
pub fn JsonStringMap(comptime V: type) type {
    return struct {
        map: std.StringHashMap(V),

        const Self = @This();

        /// Caller owns memory of returned Value.
        pub fn toJson(allocator: *Allocator, obj: Self) !Value {
            var map = ObjectMap.init(allocator);
            try map.ensureCapacity(obj.map.count());

            var it = obj.map.iterator();
            while (it.next()) |kv| {
                const json_val = try serialize(allocator, kv.value);
                _ = map.putAssumeCapacity(kv.key, json_val);
            }

            return Value{ .Object = map };
        }

        pub fn fromJson(
            allocator: *Allocator,
            val: Value,
        ) !Self {
            if (val != .Object) return error.CannotDeserialize;
            var map = std.StringHashMap(V).init(allocator);
            try map.ensureCapacity(val.Object.count());

            var it = val.Object.iterator();
            while (it.next()) |kv| {
                const v_obj = try deserialize(allocator, kv.value, V);
                _ = map.putAssumeCapacity(kv.key, v_obj);
            }

            return Value{ .map = map };
        }
    };
}


// TODO ensure that ints and floats fit within 64 bits, otherwise return an
// error.CannotSerialize or something
/// Serializes `obj` into a JSON `Value`.
pub fn serialize(allocator: *Allocator, obj: var) !Value {
    const T = @TypeOf(obj);

    // If the object defines its own custom serialization function, use it as an
    // override. Note that we can't simply check it in the `Struct` case below
    // because we may define `toJson` on enums [RFC 8620 5.5].
    if (comptime std.meta.trait.hasFn("toJson")(T)) {
        return T.toJson(allocator, obj);
    }

    return switch (@typeInfo(T)) {
        .Array => Value{ .Array = try serializeList(allocator, obj) },
        .Bool => Value{ .Bool = obj },
        .Float => Value{ .Float = obj },
        .Int => Value{ .Integer = @intCast(i64, obj) },
        .Optional => if (obj) |val| serialize(allocator, val) else .Null,
        .Pointer => |p| serializePointer(allocator, obj, p),
        .Struct => |s| serializeStruct(allocator, obj, s),
        else => error.CannotSerialize,
    };
}


pub fn deserialize(allocator: *Allocator, val: Value, comptime T: type) !T {
    if (comptime std.meta.trait.hasFn("fromJson")(T))
        return T.fromJson(allocator, val);

    // We will not support unions here because they are inefficient to handle in
    // the generic case. Rather, we handle them through custom `fromJson`
    // methods in the union definition. We also do not support single-item
    // pointers because JSON has no concept of pointing to memory.
    // TODO figure out if I need comptime assertions here
    // TODO do proper integer range checking to convert from i to u
    // TODO clean this up to reduce duplicate "return error" code
    return switch (@typeInfo(T)) {
        .Array => |a| deserializeArray(allocator, val, T, a),
        .Bool => if (val == .Bool) val.Bool else error.CannotDeserialize,
        .Float => if (val == .Float) val.Float else error.CannotDeserialize,
        .Int => if (val == .Integer) val.Integer else error.CannotDeserialize,

        .Optional => if (val == .Null)
            null
        else
            deserialize(allocator, val, T.Child),

        .Pointer => |p| deserializePointer(allocator, val, T, p),
        .Struct => |s| deserializeStruct(allocator, val, T, s),

        else => error.CannotDeserialize,
    };
}

fn serializeStruct(
    allocator: *Allocator,
    obj: var,
    struct_info: std.builtin.TypeInfo.Struct,
) !Value {
    const T = @TypeOf(obj);

    // If `obj` is already a JSON value, we're done.
    if (T == Value) {
        return obj;
    }
    
    // If `obj` is a JSON object, just wrap it up into a JSON value.
    if (T == ObjectMap) {
        return Value{ .Object = obj };
    }

    // We do not handle the `Array` case of `Value` because we expect it
    // to never end up in our code. If it somehow did, why wouldn't we
    // simply use a regular slice?

    var map = ObjectMap.init(allocator);
    try map.ensureCapacity(struct_info.fields.len);
    inline for (struct_info.fields) |field| {
        const name = field.name;
        const camel_cased = comptime blk: {
            var buf: [name.len]u8 = undefined;
            break :blk snakeToCamel(name, buf[0..]);
        };

        const field_json = try serialize(allocator, @field(obj, name));
        _ = map.putAssumeCapacity(camel_cased, field_json);
    }

    return Value{ .Object = map };
}

// TODO figure out if we really should be `serialize`ing a single-item pointer.
// Should we even support single item pointers? Is this maybe related to
// `ResultReferences` in some way?
fn serializePointer(
    allocator: *Allocator,
    ptr: var,
    ptr_info: std.builtin.TypeInfo.Pointer
) !Value {
    return if (ptr_info.size != .Slice)
        error.CannotSerialize
    else if (ptr_info.Child == u8)
        Value{ .String = ptr }
    else
        Value{ .Array = try serializeList(allocator, ptr) };
}

/// Serializes `arr` (either a slice or an array) to a JSON `Array`.
/// This function is named serializedList due to the fact that it accepts any
/// iterable object.
fn serializeList(allocator: *Allocator, list: var) !Array {
    var arr = try Array.initCapacity(allocator, list.len);
    for (list) |el| {
        arr.appendAssumeCapacity(try serialize(allocator, el));
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

// TODO decide what is the correct thing to do when there is a field in the JSON
// object that is not a field in the struct. Do we return an error or just
// silently ignore that value?
fn deserializeStruct(
    allocator: *Allocator,
    obj: ObjectMap,
    comptime T: type,
    struct_info: std.builtin.TypeInfo.Struct,
) !T {
    var result: T = undefined;

    inline for (struct_info.fields) |f| {
        const camel_cased = comptime blk: {
            var buf: [f.name.len]u8 = undefined;
            break :blk snakeToCamel(f.name, buf[0..]);
        };

        if (obj.getValue(camel_cased)) |val| {
            @field(result, f.name) = try deserialize(allocator, val, f.field_type);
        } else if (@typeInfo(f.field_type) == .Optional) {
            @field(result, f.name) = null;
        } else {
            return error.CannotDeserialize;
        }
    }

    return result;
}

// TODO see if it's cleaner code to combine these two functions into one.

// Only supports slices, because as I see it, there's no reason to support any
// other type of pointer.
fn deserializePointer(
    allocator: *Allocator,
    val: Value,
    comptime T: type,
    ptr_info: std.builtin.TypeInfo.Pointer,
) !T {
    if (ptr_info.size != .Slice)
        return error.CannotDeserialize;

    if (ptr_info.Child == u8) {
        return if (val != .String) error.CannotDeserialize else val.String;
    }

    var result = try allocator.alloc(ptr_info.Child, val.Array.len);
    for (val.Array.span()) |item, i| {
        result[i] = try deserialize(allocator, item, ptr_info.Child);
    }
    return result;
}

fn deserializeArray(
    allocator: *Allocator,
    val: Value,
    comptime T: type,
    arr_info: std.builtin.TypeInfo.Array,
) !T {
    var result: T = undefined;

    if (arr_info.Child == u8) {
        if (val != .String or val.String.len != arr_info.len)
            return error.CannotDeserialize;
        std.mem.copy(u8, result, val.String);
        return result;
    }
        
    if (val != .Array or arr_info.len != val.Array.len)
        return error.CannotDeserialize;

    for (val.Array.span()) |item, i| {
        result[i] = try deserialize(allocator, item, arr_info.Child);
    }
    return result;
}
