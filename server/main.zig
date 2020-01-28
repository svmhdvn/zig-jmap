const std = @import("std");
const StreamServer = std.net.StreamServer;


const Client = struct {
    conn: StreamServer.Connection,
    handle_frame: @Frame(handle),

    pub fn handle(self: *Client) !void {
        try self.conn.file.write("server: welcome to the JMAP test!\n");
        while (true) {
            var buf: [1024]u8 = undefined;
            const amt = try self.conn.file.read(&buf);
            const msg = buf[0..amt];
            if (msg[0] == 'a') {
                try self.conn.file.write("your message starts with an 'a'!\n");
            }
        }
    }
};

pub fn main() anyerror!void {
    var server = StreamServer.init(StreamServer.Options{});
    defer server.deinit();

    const addr = std.net.Address.parseIp4("127.0.0.1", 0) catch unreachable;

    try server.listen(addr);
    std.debug.warn("listening on {}\n", .{server.listen_address});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var clients = std.ArrayList(*Client).init(allocator);

    while (true) {
        const conn = try server.accept();
        const client = try allocator.create(Client);
        client.* = Client{
            .conn = conn,
            .handle_frame = async client.handle(),
        };
        try clients.append(client);
    }
}
