const std = @import("std");
const types = @import("types.zig");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;

pub fn JsonStringMap(comptime V: type) type {
    return struct {
        const Self = @This();

        map: std.StringHashMap(V),

        pub fn toJson(self: Self, allocator: *Allocator) Allocator.Error!Value {}
    };
}

pub fn Method(comptime RequestType: type, comptime ResponseType: type) type {
    return struct {
        pub const Request = RequestType;
        pub const Response = ResponseType;
    };
}

pub fn DataType(comptime T: type) type {
    return struct {
        const GetRequest = struct {
            account_id: types.Id,
            ids: ?[]const types.Id,
            properties: ?[]const []const u8,
        };

        const GetResponse = struct {
            account_id: types.Id,
            state: []const u8,
            list: []const T,
            not_found: []const types.Id,
        };

        const ChangesRequest = struct {
            account_id: types.Id,
            since_state: []const u8,
            max_changes: ?types.UnsignedInt,
        };

        const ChangesResponse = struct {
            account_id: types.Id,
            old_state: []const u8,
            new_state: []const u8,
            has_more_changes: bool,
            created: []const types.Id,
            updated: []const types.Id,
            destroyed: []const types.Id,
        };

        const SetError = struct {
            type: []const u8,
            description: ?[]const u8,
        };

        const SetRequest = struct {
            account_id: types.Id,
            if_in_state: ?[]const u8,
            // TODO figure out maps
            create: bool,
            update: bool,
            destroy: ?[]const types.Id,
        };

        const SetResponse = struct {
            account_id: types.Id,
            old_state: ?[]const u8,
            new_state: []const u8,
            // TODO figure out maps
            created: bool,
            updated: bool,
            destroyed: ?[]const types.Id,
            not_created: ?std.AutoHashMap(types.Id, SetError),
            not_updated: ?std.AutoHashMap(types.Id, SetError),
            not_destroyed: ?std.AutoHashMap(types.Id, SetError),
        };

        const CopyRequest = struct {
            from_account_id: types.Id,
            ifFromInState: ?[]const u8,
            account_id: types.Id,
            if_in_state: ?[]const u8,
            // TODO figure out maps
            create: bool,
            on_success_destroy_original: bool = false,
            destroy_from_if_in_state: ?[]const u8,
        };

        const CopyResponse = struct {
            from_account_id: types.Id,
            account_id: types.Id,
            old_state: ?[]const u8,
            new_state: []const u8,
            // TODO figure out maps
            created: bool,
            not_created: ?std.AutoHashMap(types.Id, SetError),
        };

        const Filter = union(enum) {
            filter_operator: FilterOperator,
            filter_condition: FilterCondition,
        };

        const FilterOperator = struct {
            operator: []const u8,
            conditions: []const Filter,
        };

        // TODO FilterCondition

        const Comparator = struct {
            property: []const u8,
            is_ascending: bool = true,
            collation: []const u8,
            position: types.Int = 0,
            anchor: ?types.Id,
            anchor_offset: types.Int = 0,
            limit: ?types.UnsignedInt,
            calculate_total: bool = false,
        };

        const QueryRequest = struct {
            account_id: types.Id,
            filter: ?Filter,
            sort: ?[]const Comparator,
        };

        const QueryResponse = struct {
            account_id: types.Id,
            query_state: []const u8,
            can_calculate_changes: bool,
            position: types.UnsignedInt,
            ids: []const types.Id,
            total: ?types.UnsignedInt,
            limit: ?types.UnsignedInt,
        };

        const QueryChangesRequest = struct {
            account_id: types.Id,
            filter: ?Filter,
            sort: ?[]const Comparator,
            since_query_state: []const u8,
            max_changes: ?types.UnsignedInt,
            up_to_id: ?types.Id,
            calculate_total: bool = false,
        };

        const AddedItem = struct {
            id: types.Id,
            index: types.UnsignedInt,
        };

        const QueryChangesResponse = struct {
            account_id: types.Id,
            old_query_state: []const u8,
            new_query_state: []const u8,
            total: ?types.UnsignedInt,
            removed: []const types.Id,
            added: []const AddedItem,
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

        pub const Get = Method(GetRequest, GetResponse);
        pub const Changes = Method(ChangesRequest, ChangesResponse);
        pub const Set = Method(SetRequest, SetResponse);
        pub const Copy = Method(CopyRequest, CopyResponse);
        pub const Query = Method(QueryRequest, QueryResponse);
        pub const QueryChanges = Method(QueryChangesRequest, QueryChangesResponse);
    };
}

// TODO PushSubscription stuff
