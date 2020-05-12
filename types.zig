/// Id is a String of 1-255 characters from the set {A-Z, a-z, 0-9, -, _}.
/// It SHOULD be prefixed with an alphabetical character [RFC 8620, 1.2].
pub const Id = []const u8;

// TODO helper functions for determining if a given Id is valid
// with the above requirements

// TODO figure out correct bit ranges for Int and UnsignedInt values
/// Int is an integer in the range -2^53 + 1 <= x <= 2^53 - 1
pub const Int = i64;

/// An UnsignedInt is an integer in the range 0 <= x <= 2^53 - 1
pub const UnsignedInt = u64;

/// Date is a String in "date-time" format [RFC 3339, 5.6].
/// Additional constraints:
/// - The "time-secfrac" MUST always be omitted if zero
/// - Any letters in the string MUST be uppercase
pub const Date = []const u8;

/// UTCDate is a Date where the "time-offset" is "Z" (must be in UTC time).
pub const UTCDate = Date;
