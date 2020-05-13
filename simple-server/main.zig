const std = @import("std");
usingnamespace @import("../json.zig");

const Allocator = std.mem.Allocator;
const Parser = std.json.Parser;
const ObjectMap = std.json.ObjectMap;
const assert = std.debug.assert;

const StoS = std.StringHashMap([]const u8);

const SessionGetRequest = struct {
    username: []const u8,
    password: []const u8,

    // TODO handle errors here
    pub fn handle(req: SessionGetRequest) !Session {
        const user_pw = cred_db.getValue(req.username)
            orelse return error.UserNotFound;

        if (!std.mem.eql(u8, pw, req.password)) {
            return error.WrongPassword;
        }

        std.debug.warn("Successfully authenticated session GET request!\n", .{});
        const accounts = getAccounts(req.username);
        const primary_accounts = getPrimaryAccounts(req.username, accounts);
        // TODO no idea how this will work, I'm just going to stub it for now
        const state = getSessionState(req);
        return Session{
            .capabilities = config.capabilities,
            .accounts = accounts,
            .primary_accounts = primary_accounts,
            .username = req.username,
            .api_url = config.api_url,
            .download_url = config.download_url,
            .upload_url = config.upload_url,
            .event_source_url = config.event_source_url,
            .state = state,
        };
    }

    // TODO add the allocator here
    fn initSession(req: SessionGetRequest) Session {
    }
};

var cred_db: StoS = undefined;

// TODO this should probably be done at compile time, just waiting on the
// availability of a comptime allocator. If there's a better way, go ahead and
// change this code. IMPLEMENT THIS.
//fn generateRoutes(allocator: *Allocator) std.StringHashMap(fn ...) {
//    ...
//}

fn handleJson(allocator: *Allocator, msg: []const u8, parser: *Parser) !void {
    parser.reset();
    const tree = try parser.parse(msg);
    assert(std.meta.activeTag(tree.root) == .Array);
    const arr = tree.root.Array;

    const name = arr.at(0).String;
    // TODO replace this with all the types you want to consider deserializing
    inline for (.{SessionGetRequest}) |T| {
        if (std.mem.eql(u8, @typeName(T), name)) {
            const result = try json_deserializer.fromJson(T, allocator, arr.at(1));
            std.debug.warn("deserialized: {}\n", .{result});
            T.handle(result);
            return;
        }
    }
}

fn initCredDb(allocator: *Allocator) !void {
    cred_db = StoS.init(allocator);
    try cred_db.putNoClobber("siva", "password");
    try cred_db.putNoClobber("another", "pw");
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    try initCredDb(allocator);

    var parser = Parser.init(allocator, false);
    var buf = try std.Buffer.initCapacity(allocator, 1024);

    while (true) {
        const req = try std.io.readLine(&buf);
        try handleJson(allocator, req, &parser);
    }
}
