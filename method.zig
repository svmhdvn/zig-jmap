const std = @import("std");
const types = @import("types.zig");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;

pub const method = struct {
    fn toJsonArray(thing: var, allocator: *Allocator) std.json.Array {
        var arr = std.json.Array.initCapacity(allocator, thing.len) catch unreachable;
        for (thing) |el| {
            arr.appendAssumeCapacity(toJson(el, allocator));
        }
        return arr;
    }

    pub fn toJson(thing: var, allocator: *Allocator) Value {
        const T = @TypeOf(thing);
        if (comptime std.meta.trait.hasFn("toJson")(T)) {
            return T.toJson(thing, allocator);
        }

        const type_info = @typeInfo(T);
        return switch (type_info) {
            .Array => Value{ .Array = toJsonArray(thing, allocator) },
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
                .Many, .Slice => Value{ .Array = toJsonArray(thing, allocator) },
                else => Value{ .Null = {} },
            },
            .Struct => |s| blk: {
                // TODO check if the struct in question is already a map
                var map = std.json.ObjectMap.init(allocator);
                // TODO fix this
                map.ensureCapacity(s.fields.len) catch unreachable;
                inline for (s.fields) |field| {
                    const name = field.name;
                    const serialized_field = toJson(@field(thing, name), allocator);
                    _ = map.putAssumeCapacity(name, serialized_field);
                }
                break :blk Value{ .Object = map };
            },
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

pub const GetRequest = struct {
    accountId: types.Id,
    ids: ?[]const types.Id,
    properties: ?[][]u8,
};

pub const GetResponse = struct {
    accountId: types.Id,
    state: []u8,
    // TODO figure out how to encode Foo object
    list: []Foo,
    notFound: []types.Id,
};

pub const ChangesRequest = struct {
    account_id: types.Id,
    since_state: []u8,
    max_changes: ?types.UnsignedInt,
};

pub const ChangesResponse = struct {
    accountId: types.Id,
    oldState: []u8,
    newState: []u8,
    hasMoreChanges: bool,
    created: []types.Id,
    updated: []types.Id,
    destroyed: []types.Id,
};

pub const SetError = struct {
    type: []u8,
    description: ?[]u8,
};

pub const SetRequest = struct {
    accountId: types.Id,
    ifInState: ?[]u8,
    // TODO figure out maps
    create: bool,
    update: bool,
    destroy: ?[]types.Id,
};

pub const SetResponse = struct {
    accountId: types.Id,
    oldState: ?[]u8,
    newState: []u8,
    // TODO figure out maps
    created: bool,
    updated: bool,
    destroyed: ?[]types.Id,
    notCreated: ?std.AutoHashMap(types.Id, SetError),
    notUpdated: ?std.AutoHashMap(types.Id, SetError),
    notDestroyed: ?std.AutoHashMap(types.Id, SetError),
};

pub const CopyRequest = struct {
    fromAccountId: types.Id,
    ifFromInState: ?[]u8,
    accountId: types.Id,
    ifInState: ?[]u8,
    // TODO figure out maps
    create: bool,
    onSuccessDestroyOriginal: bool = false,
    destroyFromIfInState: ?[]u8,
};

pub const CopyResponse = struct {
    fromAccountId: types.Id,
    accountId: types.Id,
    oldState: ?[]u8,
    newState: []u8,
    // TODO figure out maps
    created: bool,
    notCreated: ?std.AutoHashMap(types.Id, SetError),
};

pub const FilterTag = enum {
    FilterOperator,
    FilterCondition,
};

pub const Filter = union(FilterTag) {
    FilterOperator: FilterOperator,
    FilterCondition: FilterCondition,
};

pub const FilterOperator = struct {
    operator: []u8,
    conditions: []Filter,
};

// TODO FilterCondition

pub const Comparator = struct {
    property: []u8,
    isAscending: bool = true,
    collation: []u8,
    position: types.Int = 0,
    anchor: ?types.Id,
    anchorOffset: types.Int = 0,
    limit: ?types.UnsignedInt,
    calculateTotal: bool = false,
};

pub const QueryRequest = struct {
    accountId: types.Id,
    filter: ?Filter,
    sort: ?[]Comparator,
};

pub const QueryResponse = struct {
    accountId: types.Id,
    queryState: []u8,
    canCalculateChanges: bool,
    position: types.UnsignedInt,
    ids: []types.Id,
    total: ?types.UnsignedInt,
    limit: ?types.UnsignedInt,
};

pub const QueryChangesRequest = struct {
    accountId: types.Id,
    filter: ?Filter,
    sort: ?[]Comparator,
    sinceQueryState: []u8,
    maxChanges: ?types.UnsignedInt,
    upToId: ?types.Id,
    calculateTotal: bool = false,
};

pub const AddedItem = struct {
    id: types.Id,
    index: types.UnsignedInt,
};

pub const QueryChangesResponse = struct {
    accountId: types.Id,
    oldQueryState: []u8,
    newQueryState: []u8,
    total: ?types.UnsignedInt,
    removed: []types.Id,
    added: []AddedItem,
};

pub const DownloadRequest = struct {
    accountId: types.Id,
    blobId: types.Id,
    type: []u8,
    name: []u8,
};

pub const UploadResponse = struct {
    accountId: types.Id,
    blobId: types.Id,
    type: []u8,
    size: types.UnsignedInt,
};

pub const BlobCopyRequest = struct {
    fromAccountId: types.Id,
    accountId: types.Id,
    blobIds: []types.Id,
};

pub const BlobCopyResponse = struct {
    fromAccountId: types.Id,
    accountId: types.Id,
    copied: ?std.AutoHashMap(types.Id, types.Id),
    notCopied: ?std.AutoHashMap(types.Id, SetError),
};

// TODO PushSubscription stuff
