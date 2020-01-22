const types = @import("types.zig");
usingnamespace @import("method.zig");

const identity = struct {
    const Record = struct {
        id: types.Id,
        name: []const u8 = "",
        email: []const u8,
        reply_to: ?[]const EmailAddress,
        bcc: ?[]const EmailAddress,
        text_signature: []const u8 = "",
        html_signature: []const u8 = "",
        may_delete: bool,
    };

    pub const Get = Method(standard.GetRequest, standard.GetResponse);
    pub const Changes = Method(standard.ChangesRequest, standard.ChangesResponse);
    pub const Set = Method(standard.SetRequest, standard.SetResponse);
};
