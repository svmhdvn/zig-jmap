const std = @import("std");

const SomeUnion = union(enum) {
    Int: i32,
    Bool: bool,
};

pub fn recRefl(thing: var) SomeUnion {
    const type_info = @typeInfo(@TypeOf(thing));
    return switch (type_info) {
        .Bool => SomeUnion{ .Bool = thing },
        .Int => SomeUnion{ .Int = thing },
        .Union => |u| blk: {
            const tag_int = @enumToInt(std.meta.activeTag(thing));
            inline for (u.fields) |field| {
                if (field.enum_field.?.value == tag_int) {
                    break :blk recRefl(@field(thing, field.name));
                }
            }
            unreachable;
        },
        else => unreachable
    };
}

pub fn main() void {
    var x: i32 = 42;
    const u_val = SomeUnion{ .Int = x };
    const result = recRefl(u_val);
    std.debug.warn("{}\n", .{result});
}
