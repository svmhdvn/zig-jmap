const std = @import("std");
const StringHashMap = std.StringHashMap;
const Value = std.json.Value;

// TODO eventually we want to parse a TOML file for the various capabilities
// and settings of this server. In the meantime, it might be quicker to roll
// our own simple configuration file format consisting of lines of KEY VALUE 
// pairs.
pub const Config = struct {
    capabilities: StringHashMap(Value),
    session_url: []const u8,
    api_url: []const u8,
    download_url: []const u8,
    upload_url: []const u8,
    event_source_url: []const u8,
};

// TODO verify that config follows the spec.
