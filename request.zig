const std = @import("std");
const types = @import("types");

const Invocation = struct {
    /// Name of the method to call or of the response.
    name: []u8,

    // TODO proper map
    arguments: bool,

    /// An arbitrary string from the client to be echoed back with the
    /// responses emitted by that method call.
    methodCallId: []u8,
};

const Request = struct {
    /// The set of capabilities the client wishes to use.
    using: [][]u8,

    /// An array of method calls to process on the server.
    methodCalls: []Invocation,

    /// A map of a (client-specified) creation id to the id the server assigned
    /// when a record was successfully created.
    createdIds: ?std.AutoHashMap(types.Id, types.Id),
};

const Response = struct {
    /// An array of responses, in the same format as the "methodCalls" on the
    /// Request object.
    methodResponses: []Invocation,

    /// A map of a (client-specified) creation id to the id the server assigned
    /// when a record was successfully created.
    createdIds: ?std.AutoHashMap(types.Id, types.Id),

    /// The current value of the "state" string on the Session object.
    sessionState: []u8,
};

const ResultReference = struct {
    /// The method call id of a previous method call in the current request.
    resultOf: []u8,

    /// The required name of a response to that method call.
    name: []u8,

    /// A pointer into the arguments of the response selected via the name and
    /// resultOf properties.
    path: []u8,
};
