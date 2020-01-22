const types = @import("types.zig");
usingnamespace @import("method.zig");

const thread = struct {
    const Record = struct {
        id: types.Id,
        email_ids: []const types.Id,
    };

    pub const Get = Method(standard.GetRequest, standard.GetResponse);
    pub const Changes = Method(standard.ChangesRequest, standard.ChangesResponse);
};
