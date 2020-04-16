const std = @import("std");
const StreamServer = std.net.StreamServer;
const Allocator = std.mem.Allocator;
const Parser = std.json.Parser;

const TypeA = struct {
    field1: i64,
    field2: []const u8,
};

const TypeB = struct {
    field3: bool,
    field4: []const u8,
};

const Client = struct {
    conn: StreamServer.Connection,
    parser: Parser,
    handle_frame: @Frame(handle),

    pub fn handle(self: *Client) !void {
        try self.conn.file.write("server: welcome to the JMAP test!\n");
        while (true) {
            var buf: [1024]u8 = undefined;
            const amt = try self.conn.file.read(&buf);
            const msg = buf[0..amt];
            std.debug.warn("msg received: {}", .{msg});
            try self.handleJson(msg);
        }
    }

    fn handleJson(self: *Client, msg: []const u8) !void {
        const tree = try self.parser.parse(msg);
        switch (tree.root) {
            .Array => |arr| {
                const name = arr.at(0).String;
                inline for (.{TypeA, TypeB}) |T| {
                    if (std.mem.eql(u8, @typeName(T), name)) {
                        const result = deserialize(T, arr.at(1).Object);
                        std.debug.warn("deserialized: {}", .{result});
                        return;
                    }
                }
            },
            else => unreachable
        }
    }

    fn deserialize(comptime T: type, obj: std.json.ObjectMap) !T {
        var result: T = undefined;
        const type_info = @typeInfo(T);
        inline for (type_info.Struct.fields) |f| {
            if (!obj.contains(f.name)) {
                return error.CannotDeserialize;
            }
            const val = obj.getValue(f.name).?;
            switch (f.field_type) {
                i64 => @field(result, f.name) = val.Integer,
                bool => @field(result, f.name) = val.Bool,
                []const u8 => @field(result, f.name) = val.String,
                else => unreachable
            }
        }

        return result;
    }
};

pub fn main() anyerror!void {
    var server = StreamServer.init(StreamServer.Options{});
    defer server.deinit();

    const addr = std.net.Address.parseIp4("127.0.0.1", 9999) catch unreachable;

    try server.listen(addr);
    std.debug.warn("listening on {}\n", .{server.listen_address});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    while (true) {
        const conn = try server.accept();
        const client = try allocator.create(Client);
        client.* = Client{
            .conn = conn,
            .parser = Parser.init(allocator, false),
            .handle_frame = async client.handle(),
        };
    }
}
