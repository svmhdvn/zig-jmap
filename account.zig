const std = @import("std");
const types = @import("types");

const Account = struct {
    /// A user-friendly string to show when presenting content from this
    /// account.
    name: []u8,

    /// This is true if the account belongs to the authenticated user rather
    /// than a group account or a personal account of another user that has
    /// been shared with them.
    isPersonal: bool,

    /// This is true if the entire account is read-only.
    isReadOnly: bool,

    // TODO proper hashmap
    accountCapabilities: bool,

    /// A map of capability URIs (as found in accountCapabilities) to the
    /// account id that is considered to be the user's main or default account
    /// for data pertaining to that capability.
    primaryAccounts: std.StringHashMap(types.Id),

    /// The username associated with the given credentials, or the empty string
    /// if none.
    username: []u8,

    /// The URL to use for JMAP API requests.
    apiUrl: []u8,

    /// The URL endpoint to use when downloading files, in URI Template
    /// (level 1) format [RFC 6570].
    downloadUrl: []u8,

    /// The URL endpoint to use when uploading files, in URI Template (level 1)
    /// format [RFC 6570].
    uploadUrl: []u8,

    /// The URL to connect to for push events, as described in Section 7.3,
    /// in URI Template (level 1) format [RFC 6570].
    eventSourceUrl: []u8,

    /// A (preferably short) string representing the state of this object on
    /// the server.
    state: []u8,
};
