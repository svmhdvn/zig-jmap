const types = @import("types");

// TODO a "capability" is pretty much like a namespace of data types and methods
// figure out how to encode that into a type in a standard way

const mail = struct {
    const capability_name = "urn:ietf:params:jmap:mail";
    const Capabilities = struct {
        /// The maximum number of Mailboxes that can be assigned to a single
        /// Email object.
        max_mailboxes_per_email: ?types.UnsignedInt,

        /// The maximum depth of the Mailbox hierarchy.
        max_mailbox_depth: ?types.UnsignedInt,

        /// The maximum length, in (UTF-8) octets, allowed for the name of
        /// a Mailbox.
        max_size_mailbox_name: types.UnsignedInt,

        /// The maximum total size of attachments, in octets, allowed for a
        ///single Email object.
        max_size_attachments_per_email: types.UnsignedInt,

        /// A list of all the values the server supports for the "property"
        /// field of the Comparator object in an "Email/query" sort.
        email_query_sort_options: []const []const u8,

        /// If true, the user may create a Mailbox in this account with a null
        /// parentId.
        may_create_top_level_mailbox: bool,
    };

    const Mailbox = DataType(struct {
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
    });

    const Thread = DataType(struct {
        id: types.Id,
        email_ids: []const types.Id,
    });

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

    const Email = DataType(struct {
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
    });

    const SearchSnippet = DataType(struct {
        email_id: types.Id,
        subject: ?[]const u8,
        preview: ?[]const u8,
    });
};

const submission = struct {
    const capability_name = "urn:ietf:params:jmap:submission";
    const Capabilities = struct {
        /// The number in seconds of the maximum delay the server supports in
        /// sending.
        max_delayed_send: types.UnsignedInt,

        /// The set of SMTP submission extensions supported by the server,
        ///which the client may use when creating an EmailSubmission object.
        submission_extensions: JsonStringMap([]const []const u8),
    };

    const Identity = DataType(struct {
        id: types.Id,
        name: []const u8 = "",
        email: []const u8,
        reply_to: ?[]const EmailAddress,
        bcc: ?[]const EmailAddress,
        text_signature: []const u8 = "",
        html_signature: []const u8 = "",
        may_delete: bool,
    });

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

    const EmailSubmission = DataType(struct {
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
    });
};

const vacation_response = struct {
    const capability_name = "urn:ietf:params:jmap:vacationresponse";
    // TODO figure out empty capabilities object

    const VacationResponse = DataType(struct {
        id: types.Id,
        is_enabled: bool,
        from_date: ?types.UTCDate,
        to_date: ?types.UTCDate,
        subject: ?[]const u8,
        text_body: ?[]const u8,
        html_body: ?[]const u8,
    });
};
