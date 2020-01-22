const types = @import("types.zig");
usingnamespace @import("method.zig");

const vacation_response = struct {
    const Record = struct {
        id: types.Id,
        is_enabled: bool,
        from_date: ?types.UTCDate,
        to_date: ?types.UTCDate,
        subject: ?[]const u8,
        text_body: ?[]const u8,
        html_body: ?[]const u8,
    };

    pub const Get = Method(standard.GetRequest, standard.GetResponse);
    pub const Set = Method(standard.SetRequest, standard.SetResponse);
};
