const types = @import("types.zig");
usingnamespace @import("method.zig");

const email_submission = struct {
    const Record = struct {
        id: types.Id,
        identity_id: types.Id,
        email_id: types.Id,
        thread_id: types.Id,
        envelope: ?Envelope,
        send_at: types.UTCDate,
        undo_status: []const u8,
        delivery_status: ?JsonStringMap(DeliveryStatus),
        dsn_blob_ids: []const types.Id,
        mdn_blob_ids: []const types.Id,
    };

    pub const Get = Method(standard.GetRequest, standard.GetResponse);
    pub const Changes = Method(standard.ChangesRequest, standard.ChangesResponse);
    pub const QueryChanges = Method(standard.QueryChangesRequest, standard.QueryChangesResponse);
    pub const Set = Method(standard.SetRequest, standard.SetResponse);

    const Address = struct {
        email: []const u8,
        parameters: ?JsonStringMap(?[]const u8),
    };

    const Envelope = struct {
        mail_from: Address,
        rcpt_to: []const Address,
    };

    const DeliveryStatus = struct {
        smtp_reply: []const u8,
        delivered: []const u8,
        displayed: []const u8,
    };
};
