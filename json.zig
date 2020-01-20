const std = @import("std");
const types = @import("types");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;

const Invocation = struct {
    const Self = @This();

    /// Name of the method to call or of the response.
    name: []const u8,

    arguments: std.json.ObjectMap,

    /// An arbitrary string from the client to be echoed back with the
    /// responses emitted by that method call.
    method_call_id: []u8,

    pub fn toJson(self: Self, allocator: *Allocator) !Value {
        var arr = try std.json.Array.initCapacity(allocator, 3);
        arr.appendAssumeCapacity(Value{ .String = self.name });
        arr.appendAssumeCapacity(Value{ .Object = self.arguments });
        arr.appendAssumeCapacity(Value{ .String = self.method_call_id });
        return Value{ .Array = arr };
    }
};

const Request = struct {
    /// The set of capabilities the client wishes to use.
    using: [][]u8,

    /// An array of method calls to process on the server.
    method_calls: []Invocation,

    /// A map of a (client-specified) creation id to the id the server assigned
    /// when a record was successfully created.
    created_ids: ?std.AutoHashMap(types.Id, types.Id),
};

const Response = struct {
    /// An array of responses, in the same format as the "methodCalls" on the
    /// Request object.
    method_responses: []Invocation,

    /// A map of a (client-specified) creation id to the id the server assigned
    /// when a record was successfully created.
    created_ids: ?std.AutoHashMap(types.Id, types.Id),

    /// The current value of the "state" string on the Session object.
    session_state: []u8,
};

const ResultReference = struct {
    /// The method call id of a previous method call in the current request.
    result_of: []u8,

    /// The required name of a response to that method call.
    name: []u8,

    /// A pointer into the arguments of the response selected via the name and
    /// resultOf properties.
    path: []u8,
};

// TODO remove hardcoded "using" capability
pub fn sendRequest(allocator: *Allocator, methods: var) !void {
    const method_calls = blk: {
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
        break :blk method_calls;
    };

    const request = Request{
        .using = .{"urn:ietf:params:jmap:core"},
        .method_calls = method_calls,
    };
}
