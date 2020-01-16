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

const QueryRequest = struct {
    accountId: types.Id,
    filter: ?Filter,
};
