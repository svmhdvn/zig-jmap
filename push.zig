const std = @import("std");
const types = @import("types");

// TODO figure out type name
const TypeState = std.AutoHashMap([]u8, []u8);

// TODO optimize the type out of this
const StateChange = struct {
    type: []u8,
    changed: std.AutoHashMap(types.Id, TypeState),
};

const PushSubscriptionKeys = struct {
    p256dh: []u8,
    auth: []u8,
    verificationCode: ?[]u8,
    expires: ?types.UTCDate,
    types: ?[][]u8,
};

const PushSubscription = struct {
    id: types.Id,
    deviceClientId: []u8,
    url: []u8,
    keys: ?PushSubscriptionKeys,
};
