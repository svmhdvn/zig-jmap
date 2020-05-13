const std = @import("std");
const types = @import("types.zig");
const json = @import("json.zig");

const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const js = json.json_serializer;
const jd = json.json_deserializer;

pub fn Method(comptime RequestType: type, comptime ResponseType: type) type {
    return struct {
        pub const Request = RequestType;
        pub const Response = ResponseType;
    };
}

pub const core = struct {
    const capability_name = "urn:ietf:params:jmap:core";
    const Capabilities = struct {
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

        /// A list of identifiers for algorithms registered in the collation
        /// registry, as defined in RFC 4790, that the server supports for
        /// sorting when querying records.
        collation_algorithms: []const []const u8,
    };

    pub const Get = Method(GetRequest, GetResponse);
    pub const Changes = Method(ChangesRequest, ChangesResponse);
    pub const Set = Method(SetRequest, SetResponse);
    pub const Copy = Method(CopyRequest, CopyResponse);
    pub const Query = Method(QueryRequest, QueryResponse);
    pub const QueryChanges = Method(QueryChangesRequest, QueryChangesResponse);

    pub const GetRequest = struct {
        account_id: types.Id,
        ids: ?[]const types.Id,
        properties: ?[]const []const u8,
    };

    pub fn GetResponse(comptime R: type) type {
        return struct {
            account_id: types.Id,
            state: []const u8,
            list: []const R,
            not_found: []const types.Id,
        };
    }

    pub const ChangesRequest = struct {
        account_id: types.Id,
        since_state: []const u8,
        max_changes: ?types.UnsignedInt,
    };

    pub const ChangesResponse = struct {
        account_id: types.Id,
        old_state: []const u8,
        new_state: []const u8,
        has_more_changes: bool,
        created: []const types.Id,
        updated: []const types.Id,
        destroyed: []const types.Id,
    };

    pub const SetError = struct {
        type: []const u8,
        description: ?[]const u8,
        properties: ?[]const []const u8,
    };

    pub fn SetRequest(comptime R: type) type {
        return struct {
            const Self = @This();

            account_id: types.Id,
            if_in_state: ?[]const u8,
            create: ?JsonStringMap(R),
            // update is a mapping from Id to PatchObject, which is an arbitrary object based
            // on the properties of the type it represents.
            // TODO is this the best way to do this?
            update: ?std.json.ObjectMap,
            destroy: ?[]const types.Id,

            pub fn fromJson(allocator: *Allocator, obj: Value) !Self {
                if (std.meta.activeTag(obj) != .Object) {
                    return error.CannotDeserialize;
                }

                var r: Self = undefined;

                const account_id = obj.getValue("accountId") orelse return error.CannotDeserialize;
                r.account_id = try jd.toJson(@TypeOf(r.account_id), allocator, account_id);

                const if_in_state = obj.getValue("ifInState") orelse return error.CannotDeserialize;
                r.if_in_state = try jd.toJson(@TypeOf(r.if_in_state), allocator, if_in_state);

                return result;
            }

            pub fn toJson(self: Self, allocator: *Allocator) !Value {
                var map = ObjectMap.init(allocator);
                try map.ensureCapacity(5);
                _ = map.putAssumeCapacity("accountId", js.toJson(self.account_id, allocator));
                _ = map.putAssumeCapacity("ifInState", js.toJson(self.if_in_state, allocator));
                _ = map.putAssumeCapacity("create", js.toJson(self.create, allocator));
                _ = map.putAssumeCapacity("destroy", js.toJson(self.destroy, allocator));

                const update = if (self.update) |unwrapped|
                    Value{ .Object = unwrapped }
                else
                    Value{ .Null = {} };
                _ = map.putAssumeCapacity("update", update);

                return Value{ .Object = map };
            }
        };
    }

    pub fn SetResponse(comptime R: type) type {
        return struct {
            account_id: types.Id,
            old_state: ?[]const u8,
            new_state: []const u8,
            created: ?JsonStringMap(R),
            updated: ?JsonStringMap(?R),
            destroyed: ?[]const types.Id,
            not_created: ?JsonStringMap(SetError),
            not_updated: ?JsonStringMap(SetError),
            not_destroyed: ?JsonStringMap(SetError),
        };
    }

    pub fn CopyRequest(comptime R: type) type {
        return struct {
            from_account_id: types.Id,
            ifFromInState: ?[]const u8,
            account_id: types.Id,
            if_in_state: ?[]const u8,
            create: JsonStringMap(R),
            on_success_destroy_original: bool = false,
            destroy_from_if_in_state: ?[]const u8,
        };
    }

    pub fn CopyResponse(comptime R: type) type {
        return struct {
            from_account_id: types.Id,
            account_id: types.Id,
            old_state: ?[]const u8,
            new_state: []const u8,
            created: ?JsonStringMap(R),
            not_created: ?JsonStringMap(SetError),
        };
    }

    pub fn custom_filter(comptime C: type) type {
        return struct {
            pub const FilterOperator = struct {
                operator: []const u8,
                conditions: []const Filter,
            };

            pub const Filter = union(enum) {
                filter_operator: FilterOperator,
                filter_condition: C,
            };
        };
    }

    // TODO add "keyword" field for email objects
    pub const Comparator = struct {
        property: []const u8,
        is_ascending: bool = true,
        collation: []const u8,
        position: types.Int = 0,
        anchor: ?types.Id,
        anchor_offset: types.Int = 0,
        limit: ?types.UnsignedInt,
        calculate_total: bool = false,
    };

    pub const QueryRequest = struct {
        account_id: types.Id,
        filter: ?Filter,
        sort: ?[]const Comparator,
    };

    pub const QueryResponse = struct {
        account_id: types.Id,
        query_state: []const u8,
        can_calculate_changes: bool,
        position: types.UnsignedInt,
        ids: []const types.Id,
        total: ?types.UnsignedInt,
        limit: ?types.UnsignedInt,
    };

    pub const QueryChangesRequest = struct {
        account_id: types.Id,
        filter: ?Filter,
        sort: ?[]const Comparator,
        since_query_state: []const u8,
        max_changes: ?types.UnsignedInt,
        up_to_id: ?types.Id,
        calculate_total: bool = false,
    };

    pub const AddedItem = struct {
        id: types.Id,
        index: types.UnsignedInt,
    };

    pub const QueryChangesResponse = struct {
        account_id: types.Id,
        old_query_state: []const u8,
        new_query_state: []const u8,
        total: ?types.UnsignedInt,
        removed: []const types.Id,
        added: []const AddedItem,
    };
};

const DownloadRequest = struct {
    account_id: types.Id,
    blobId: types.Id,
    type: []const u8,
    name: []const u8,
};

const UploadResponse = struct {
    account_id: types.Id,
    blob_id: types.Id,
    type: []const u8,
    size: types.UnsignedInt,
};

const BlobCopyRequest = struct {
    from_account_id: types.Id,
    account_id: types.Id,
    blob_ids: []const types.Id,
};

const BlobCopyResponse = struct {
    from_account_id: types.Id,
    account_id: types.Id,
    copied: ?std.AutoHashMap(types.Id, types.Id),
    not_copied: ?std.AutoHashMap(types.Id, SetError),
};

// TODO PushSubscription stuff
