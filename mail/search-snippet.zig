const types = @import("types.zig");
usingnamespace @import("method.zig");

const search_snippet = struct {
    pub const Record = struct {
        email_id: types.Id,
        subject: ?[]const u8,
        preview: ?[]const u8,
    };

    pub const Get = Method(GetRequest, GetResponse);

    pub const QueryRequest = struct {
        account_id: types.Id,
        sort: ?[]const Comparator,
        // extra fields
        sort_as_tree: bool = false,
        filter_as_tree: bool = false,
    };

    const GetRequest = struct {
        account_id: types.Id,
        filter: ?custom_filter(FilterCondition).Filter,
        email_ids: []const types.Id,
    };

    const GetResponse = struct {
        account_id: types.Id,
        list: []const Record,
        not_found: ?[]const types.Id,
    };
};
