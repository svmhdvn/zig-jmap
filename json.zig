const std = @import("std");
const types = @import("types");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const Array = std.json.Array;
const ObjectMap = std.json.ObjectMap;

const assert = std.debug.assert;

fn toSnakeCase(str: []const u8, buf: []u8) []const u8 {
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

fn toCamelCase(str: []const u8, buf: []u8) []const u8 {
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

pub const json_deserializer = struct {
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
                break :blk toCamelCase(f.name, buf[0..]);
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
};

pub const json_serializer = struct {
    fn toJsonArray(thing: var, allocator: *Allocator) Allocator.Error!Array {
        var arr = try Array.initCapacity(allocator, thing.len);
        for (thing) |el| {
            arr.appendAssumeCapacity(try toJson(el, allocator));
        }
        return arr;
    }

    pub fn toJson(thing: var, allocator: *Allocator) Allocator.Error!Value {
        const T = @TypeOf(thing);
        if (T == Value) {
            return thing;
        }

        if (comptime std.meta.trait.hasFn("toJson")(T)) {
            return T.toJson(thing, allocator);
        }

        const type_info = @typeInfo(T);
        return switch (type_info) {
            .Array => Value{ .Array = try toJsonArray(thing, allocator) },
            .Bool => Value{ .Bool = thing },
            // TODO camelCase enum value string
            .Enum => Value{ .String = @tagName(thing) },
            .Float, .ComptimeFloat => Value{ .Float = thing },
            .Int, .ComptimeInt => Value{ .Integer = @intCast(i64, thing) },
            .Optional => if (thing) |thing_unwrapped|
                toJson(thing_unwrapped, allocator)
            else
                Value{ .Null = {} },
            .Pointer => |p| if (p.child == u8)
                Value{ .String = thing }
            else switch (p.size) {
                .One => toJson(thing.*, allocator),
                .Many, .Slice => Value{ .Array = try toJsonArray(thing, allocator) },
                else => Value{ .Null = {} },
            },
            .Struct => |s| blk: {
                var map = ObjectMap.init(allocator);
                try map.ensureCapacity(s.fields.len);
                inline for (s.fields) |field| {
                    const name = field.name;
                    const camel_cased = comptime blk: {
                        var buf: [name.len]u8 = undefined;
                        break :blk toCamelCase(name, buf[0..]);
                    };

                    const serialized_field = try toJson(@field(thing, name), allocator);
                    _ = map.putAssumeCapacity(camel_cased, serialized_field);
                }
                break :blk Value{ .Object = map };
            },
            // TODO figure out what to do about untagged bare unions
            .Union => |u| blk: {
                const tag_int = @enumToInt(std.meta.activeTag(thing));
                inline for (u.fields) |field| {
                    if (tag_int == field.enum_field.?.value) {
                        break :blk toJson(@field(thing, field.name), allocator);
                    }
                }
                unreachable;
            },
            else => Value.Null,
        };
    }
};

const Invocation = struct {
    const Self = @This();

    /// Name of the method to call or of the response.
    name: []const u8,

    arguments: ObjectMap,

    /// An arbitrary string from the client to be echoed back with the
    /// responses emitted by that method call.
    method_call_id: []const u8,

    pub fn toJson(self: Self, allocator: *Allocator) !Value {
        var arr = try Array.initCapacity(allocator, 3);
        arr.appendAssumeCapacity(Value{ .String = self.name });
        arr.appendAssumeCapacity(Value{ .Object = self.arguments });
        arr.appendAssumeCapacity(Value{ .String = self.method_call_id });
        return Value{ .Array = arr };
    }
};

const Request = struct {
    /// The set of capabilities the client wishes to use.
    using: []const []const u8,

    /// An array of method calls to process on the server.
    method_calls: []const Invocation,

    /// A map of a (client-specified) creation id to the id the server assigned
    /// when a record was successfully created.
    created_ids: ?std.AutoHashMap(types.Id, types.Id),
};

const Response = struct {
    /// An array of responses, in the same format as the "methodCalls" on the
    /// Request object.
    method_responses: []const Invocation,

    /// A map of a (client-specified) creation id to the id the server assigned
    /// when a record was successfully created.
    created_ids: ?std.AutoHashMap(types.Id, types.Id),

    /// The current value of the "state" string on the Session object.
    session_state: []const u8,
};

const ResultReference = struct {
    /// The method call id of a previous method call in the current request.
    result_of: []const u8,

    /// The required name of a response to that method call.
    name: []const u8,

    /// A pointer into the arguments of the response selected via the name and
    /// resultOf properties.
    path: []const u8,
};

// TODO remove hardcoded "using" capability
pub fn sendRequest(allocator: *Allocator, methods: var) !void {
    var method_calls: []Invocation = try allocator.alloc(Invocation, methods.len);
    for (methods) |method, i| {
        // TODO figure out how to generate the name of the method call
        // TODO figure out id generation
        method_calls[i] = Invocation{
            .name = "Core/echo",
            .arguments = method.toJson(allocator),
            .method_call_id = "LOL",
        };
    }

    const request = Request{
        .using = &[_][]const u8{"urn:ietf:params:jmap:core"},
        .method_calls = method_calls,
    };
}
