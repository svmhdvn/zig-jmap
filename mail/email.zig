const types = @import("types.zig");
usingnamespace @import("method.zig");

const email = struct {
    const Record = struct {
        // meta
        id: types.Id,
        blob_id: types.Id,
        thread_id: types.Id,
        mailbox_ids: JsonStringMap(bool),
        keywords: JsonStringMap(bool),
        size: types.UnsignedInt,
        received_at: types.UTCDate,

        // convenience headers
        message_id: ?[]const []const u8, // header:Message-ID:asMessageIds
        in_reply_to: ?[]const []const u8, // header:In-Reply-To:asMessageIds
        references: ?[]const []const u8, // header:References:asMessageIds
        sender: ?[]const EmailAddress, // header:Sender:asAddresses
        from: ?[]const EmailAddress, // header:From:asAddresses
        to: ?[]const EmailAddress, // header:To:asAddresses
        cc: ?[]const EmailAddress, // header:Cc:asAddresses
        bcc: ?[]const EmailAddress, // header:Bcc:asAddresses
        reply_to: ?[]const EmailAddress, // header:Reply-To:asAddresses
        subject: ?[]const u8, // header:Subject:asText
        sent_at: ?types.Date, // header:Date:asDate

        // body parts
        body_structure: EmailBodyPart,
        body_values: JsonStringMap(EmailBodyValue),
        text_body: []const EmailBodyPart,
        html_body: []const EmailBodyPart,
        attachments: []const EmailBodyPart,
        has_attachment: bool,
        preview: []const u8,
    };

    // standard methods
    const Get = Method(GetRequest, standard.GetResponse(Record));
    const Changes = Method(standard.ChangesRequest, standard.ChangesResponse);
    const Query = Method(QueryRequest, standard.QueryResponse);
    const QueryChanges = Method(QueryChangesRequest, standard.QueryChangesResponse);
    const Set = Method(standard.SetRequest(Record), standard.SetResponse(Record));
    const Copy = Method(standard.CopyRequest(Record), standard.CopyResponse(Record));

    // non-standard methods
    const Import = Method(ImportRequest, ImportResponse);
    const Parse = Method(ParseRequest, ParseResponse);

    const EmailHeader = struct {
        name: []const u8,
        value: []const u8,
    };

    const EmailBodyPart = struct {
        part_id: ?[]const u8,
        blob_id: ?types.Id,
        size: types.UnsignedInt,
        headers: []const EmailHeader,
        name: ?[]const u8,
        type: []const u8,
        charset: ?[]const u8,
        disposition: ?[]const u8,
        cid: ?[]const u8,
        language: ?[]const []const u8,
        location: ?[]const u8,
        sub_parts: ?[]const EmailBodyPart,
    };

    const EmailBodyValue = struct {
        value: []const u8,
        is_encoding_problem: bool = false,
        is_truncated: bool = false,
    };

    pub const GetRequest = struct {
        account_id: types.Id,
        ids: ?[]const types.Id,

        // changed fields
        properties: []const []const u8 = .{"id", "blobId", "threadId", "mailboxIds", "keywords", "size",
 "receivedAt", "messageId", "inReplyTo", "references", "sender", "from",
 "to", "cc", "bcc", "replyTo", "subject", "sentAt", "hasAttachment",
 "preview", "bodyValues", "textBody", "htmlBody", "attachments"},

        // extra fields
        body_properties: []const []const u8 = .{"partId", "blobId", "size", "name", "type", "charset",
           "disposition", "cid", "language", "location"},
        fetch_text_body_values: bool = false,
        fetch_html_body_values: bool = false,
        fetch_all_body_values: bool = false,
        max_body_values_bytes: types.UnsignedInt = 0,
    };

    pub const FilterCondition = struct {
        in_mailbox: ?types.Id,
        in_mailbox_other_than: ?[]const types.Id,
        before: ?types.UTCDate,
        after: ?types.UTCDate,
        min_size: ?types.UnsignedInt,
        max_size: ?types.UnsignedInt,
        all_in_thread_have_keyword: ?[]const u8,
        some_in_thread_have_keyword: ?[]const u8,
        none_in_thread_have_keyword: ?[]const u8,
        has_keyword: ?[]const u8,
        not_keyword: ?[]const u8,
        has_attachment: ?bool,
        text: ?[]const u8,
        from: ?[]const u8,
        to: ?[]const u8,
        cc: ?[]const u8,
        bcc: ?[]const u8,
        subject: ?[]const u8,
        body: ?[]const u8,
        header: ?[]const []const u8,
    };
    
    pub const QueryRequest = struct {
        account_id: types.Id,
        filter: ?custom_filter(FilterCondition).Filter,
        sort: ?[]const Comparator,

        // extra fields
        collapse_threads: bool = false,
    };

    pub const QueryChangesRequest = struct {
        account_id: types.Id,
        filter: ?Filter,
        sort: ?[]const Comparator,
        since_query_state: []const u8,
        max_changes: ?types.UnsignedInt,
        up_to_id: ?types.Id,
        calculate_total: bool = false,

        // extra fields
        collapse_threads: bool = false,
    };

    pub const EmailImport = struct {
        blob_id: types.Id,
        mailbox_ids: JsonStringMap(bool),
        keywords: JsonStringMap(bool),
        received_at: types.UTCDate,
    };

    pub const ImportResponse = struct {
        account_id: types.Id,
        old_state: ?[]const u8,
        new_state: []const u8,
        created: ?JsonStringMap(Record),
        not_created: ?JsonStringMap(SetError),
    };

    pub const ImportRequest = struct {
        account_id: types.Id,
        if_in_state: ?[]const u8,
        emails: JsonStringMap(EmailImport),
    };

    pub const ParseRequest = struct {
        account_id: types.Id,
        blob_ids: []const types.Id,
        properties: []const []const u8 = .{"messageId", "inReplyTo", "references", "sender", "from", "to",
            "cc", "bcc", "replyTo", "subject", "sentAt", "hasAttachment",
            "preview", "bodyValues", "textBody", "htmlBody", "attachments"},
        body_properties: []const []const u8,
        fetch_text_body_values: bool = false,
        fetch_html_body_values: bool = false,
        fetch_all_body_values: bool = false,
        max_body_value_bytes: types.UnsignedInt = 0,
    };

    pub const ParseResponse = struct {
        account_id: types.Id,
        parsed: ?JsonStringMap(Record),
        not_parsable: ?[]const types.Id,
        not_found: ?[]const types.Id,
    };
};
