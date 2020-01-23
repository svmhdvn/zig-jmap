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
};

const vacation_response = struct {
    const capability_name = "urn:ietf:params:jmap:vacationresponse";
    // TODO figure out empty capabilities object
};
