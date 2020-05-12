const std = @import("std");
const Value = std.json.Value;

pub const Account = struct {
    /// A user-friendly string to show when presenting content from this
    /// account.
    name: []const u8,

    /// This is true if the account belongs to the authenticated user rather
    /// than a group account or a personal account of another user that has
    /// been shared with them.
    is_personal: bool,

    /// This is true if the entire account is read-only.
    is_read_only: bool,

    // TODO see if there's a way to make this a better type. We have
    // types for each of the different Capabilities, but how do we get a
    // string hashmap to *different* capabilities?
    account_capabilities: std.StringHashMap(Value),
};

pub const Session = struct {
    // TODO figure out if there is a better way of doing this
    /// An object specifying the capabilities of this server. Each key is
    /// a URI for a capability supported by the server. The value for
    /// each of these keys is an object with further information about the
    /// server's capabilities in relation to that capability.
    capabilities: std.StringHashMap(Value),

    /// A map of an account id to an Account object for each account the user
    /// has access to.
    accounts: std.AutoHashMap(types.Id, Account),

    /// A map of capability URIs (as found in accountCapabilities) to the
    /// account id that is considered to be the user's main or default account
    /// for data pertaining to that capability.
    primary_accounts: std.StringHashMap(types.Id),

    /// The username associated with the given credentials, or the empty string
    /// if none.
    username: []const u8,

    /// The URL to use for JMAP API requests.
    api_url: []const u8,

    /// The URL endpoint to use when downloading files, in URI Template
    /// (level 1) format [RFC 6570].
    download_url: []const u8,

    /// The URL endpoint to use when uploading files, in URI Template (level 1)
    /// format [RFC 6570].
    upload_url: []const u8,

    /// The URL to connect to for push events, as described in Section 7.3,
    /// in URI Template (level 1) format [RFC 6570].
    event_source_url: []const u8,

    /// A (preferably short) string representing the state of this object on
    /// the server.
    state: []const u8,
};
