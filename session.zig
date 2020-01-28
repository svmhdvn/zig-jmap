const types = @import("types");

// TODO Change field default values to more sane things. Currently, they're set
// to the "suggested minimum" from the RFC.
const CoreCapabilities = struct {
    /// The maximum file size, in octets, that the server will accept for a
    /// single file upload (for any purpose).
    max_size_upload: types.UnsignedInt = 50000000,

    /// The maximum number of concurrent requests the server will accept to the
    /// upload endpoint.
    max_concurrent_upload: types.UnsignedInt = 4,

    /// The maximum size, in octets, that the server will accept for a single
    /// request to the API endpoint.
    max_size_request: types.UnsignedInt = 10000000,

    /// The maximum number of concurrent requests the server will accept to the
    /// API endpoint.
    max_concurrent_requests: types.UnsignedInt = 4,

    /// The maximum number of method calls the server will accept in a single
    /// request to the API endpoint.
    max_calls_in_request: types.UnsignedInt = 16,

    /// The maximum number of objects that the client may request in a single
    /// /get type method call.
    max_objects_in_get: types.UnsignedInt = 500,

    /// The maximum number of objects the client may send to create, update,
    /// or destroy in a single /set type method call.
    max_objects_in_set: types.UnsignedInt = 500,

    // TODO figure this one out

    /// A list of identifiers for algorithms registered in the collation
    /// registry, as defined in RFC 4790, that the server supports for
    /// sorting when querying records.
    collation_algorithms: []const u8,
};
