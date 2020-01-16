/// Id is a String of 1-255 characters from the set {A-Z, a-z, 0-9, -, _}. It
/// should be prefixed with an alphabetical character. [RFC 8620, 1.2]
pub const Id = []u8;

// TODO figure out correct bit range

/// -2^53 + 1 <= x <= 2^53 - 1
pub const Int = i64;

// TODO figure out correct bit range

/// 0 <= x <= 2^53 - 1
pub const UnsignedInt = u64;

/// Date is a String in "date-time" format [RFC 3339, 5.6]
pub const Date = []u8;

/// UTCDate is a Date where the "time-offset" is "Z"
pub const UTCDate = Date;
