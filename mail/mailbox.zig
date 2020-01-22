const types = @import("types.zig");
usingnamespace @import("method.zig");

const mailbox = struct {
    pub const Record = struct {
        id: types.Id,
        name: []const u8,
        parent_id: ?types.Id,
        role: ?[]const u8,
        sort_order: types.UnsignedInt = 0,
        total_emails: types.UnsignedInt,
        unread_emails: types.UnsignedInt,
        total_threads: types.UnsignedInt,
        unread_threads: types.UnsignedInt,
        my_rights: MailboxRights,
        is_subscribed: bool,
    };

    pub const Get = Method(standard.GetRequest, standard.GetResponse);
    pub const Changes = Method(standard.ChangesRequest, ChangesResponse);
    pub const Query = Method(QueryRequest, standard.QueryResponse);
    pub const QueryChanges = Method(standard.QueryChangesRequest, standard.QueryChangesResponse);
    pub const Set = Method(SetRequest, standard.SetResponse);

    const MailboxRights = struct {
        may_read_items: bool,
        may_add_items: bool,
        may_remove_items: bool,
        may_set_seen: bool,
        may_set_keywords: bool,
        may_create_child: bool,
        may_rename: bool,
        may_delete: bool,
        may_submit: bool,
    };

    pub const ChangesResponse = struct {
        account_id: types.Id,
        old_state: []const u8,
        new_state: []const u8,
        has_more_changes: bool,
        created: []const types.Id,
        updated: []const types.Id,
        destroyed: []const types.Id,
        // extra fields
        updated_properties: ?[]const []const u8,
    };

    pub const FilterCondition = struct {
        parent_id: ?types.Id,
        name: []const u8,
        role: ?[]const u8,
        has_any_role: bool,
        is_subscribed: bool,
    };

    pub const QueryRequest = struct {
        account_id: types.Id,
        filter: ?custom_filter(FilterCondition).Filter,
        sort: ?[]const Comparator,
        // extra fields
        sort_as_tree: bool = false,
        filter_as_tree: bool = false,
    };

    pub const SetRequest = struct {
        account_id: types.Id,
        if_in_state: ?[]const u8,
        create: ?JsonStringMap(T),
        update: ?json.ObjectMap,
        destroy: ?[]const types.Id,
        // extra fields
        on_destroy_remove_emails: bool = false,

        pub fn toJson(self: Self, allocator: *Allocator) !Value {
            var map = ObjectMap.init(allocator);
            try map.ensureCapacity(6);
            _ = map.putAssumeCapacity("accountId", js.toJson(self.account_id, allocator));
            _ = map.putAssumeCapacity("ifInState", js.toJson(self.if_in_state, allocator));
            _ = map.putAssumeCapacity("create", js.toJson(self.create, allocator));
            _ = map.putAssumeCapacity("destroy", js.toJson(self.destroy, allocator));
            _ = map.putAssumeCapacity("onDestroyRemoveEmails", js.toJson(self.on_destroy_remove_emails, allocator));

            const update = if (self.update) |unwrapped|
                Value{ .Object = unwrapped }
            else
                Value{ .Null = {} };
            _ = map.putAssumeCapacity("update", update);

            return Value{ .Object = map };
        }
    };
};
