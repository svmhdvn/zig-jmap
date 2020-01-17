const types = @import("types");

const GetRequest = struct {
    accountId: types.Id,
    ids: ?[]types.Id,
    properties: ?[][]u8,
};

const GetResponse = struct {
    accountId: types.Id,
    state: []u8,
    // TODO figure out how to encode Foo object
    list: []Foo,
    notFound: []types.Id,
};

const ChangesRequest = struct {
    accountId: types.Id,
    sinceState: []u8,
    maxChanges: ?types.UnsignedInt,
};

const ChangesResponse = struct {
    accountId: types.Id,
    oldState: []u8,
    newState: []u8,
    hasMoreChanges: bool,
    created: []types.Id,
    updated: []types.Id,
    destroyed: []types.Id,
};

const SetError = struct {
    type: []u8,
    description: ?[]u8,
};

const SetRequest = struct {
    accountId: types.Id,
    ifInState: ?[]u8,
    // TODO figure out maps
    create: bool,
    update: bool,
    destroy: ?[]types.Id,
};

const SetResponse = struct {
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

const CopyRequest = struct {
    fromAccountId: types.Id,
    ifFromInState: ?[]u8,
    accountId: types.Id,
    ifInState: ?[]u8,
    // TODO figure out maps
    create: bool,
    onSuccessDestroyOriginal: bool = false,
    destroyFromIfInState: ?[]u8,
};

const CopyResponse = struct {
    fromAccountId: types.Id,
    accountId: types.Id,
    oldState: ?[]u8,
    newState: []u8,
    // TODO figure out maps
    created: bool,
    notCreated: ?std.AutoHashMap(types.Id, SetError),
};

const FilterTag = enum {
    FilterOperator,
    FilterCondition,
};

const Filter = union(FilterTag) {
    FilterOperator: FilterOperator,
    FilterCondition: FilterCondition,
};

const FilterOperator = struct {
    operator: []u8,
    conditions: []Filter,
};

// TODO FilterCondition

const Comparator = struct {
    property: []u8,
    isAscending: bool = true,
    collation: []u8,
    position: types.Int = 0,
    anchor: ?types.Id,
    anchorOffset: types.Int = 0,
    limit: ?types.UnsignedInt,
    calculateTotal: bool = false,
};

const QueryRequest = struct {
    accountId: types.Id,
    filter: ?Filter,
    sort: ?[]Comparator,
};

const QueryResponse = struct {
    accountId: types.Id,
    queryState: []u8,
    canCalculateChanges: bool,
    position: types.UnsignedInt,
    ids: []types.Id,
    total: ?types.UnsignedInt,
    limit: ?types.UnsignedInt,
};

const QueryChangesRequest = struct {
    accountId: types.Id,
    filter: ?Filter,
    sort: ?[]Comparator,
    sinceQueryState: []u8,
    maxChanges: ?types.UnsignedInt,
    upToId: ?types.Id,
    calculateTotal: bool = false,
};

const AddedItem = struct {
    id: types.Id,
    indes: types.UnsignedInt,
};

const QueryChangesResponse = struct {
    accountId: types.Id,
    oldQueryState: []u8,
    newQueryState: []u8,
    total: ?types.UnsignedInt,
    removed: []types.Id,
    added: []AddedItem,
};

const DownloadRequest = struct {
    accountId: types.Id,
    blobId: types.Id,
    type: []u8,
    name: []u8,
};

const UploadResponse = struct {
    accountId: types.Id,
    blobId: types.Id,
    type: []u8,
    size: types.UnsignedInt,
};

const BlobCopyRequest = struct {
    fromAccountId: types.Id,
    accountId: types.Id,
    blobIds: []types.Id,
};

const BlobCopyResponse = struct {
    fromAccountId: types.Id,
    accountId: types.Id,
    copied: ?std.AutoHashMap(types.Id, types.Id),
    notCopied: ?std.AutoHashMap(types.Id, SetError),
};

// TODO PushSubscription stuff
