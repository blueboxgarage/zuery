const std = @import("std");

pub const FieldMapping = struct {
    column_name: []const u8,
    table_name: []const u8,
    system_a_fieldmap: []const u8,
    system_b_fieldmap: []const u8,
    field_description: []const u8,
    field_type: []const u8,
};

pub const QueryType = enum {
    Select,
    Count,
    GroupBy,
};

pub const MatchedField = struct {
    column_name: []const u8,
    table_name: []const u8,
    field_description: []const u8,
    field_type: []const u8,
    match_score: f32,
    matched_text: []const u8,
};

pub const QueryRequest = struct {
    description: []const u8,
    system: []const u8 = "default",
    limit: ?u32 = null,
};

pub const QueryResponse = struct {
    query: []const u8,
    matched_fields: []MatchedField,
    confidence: f32,
};

pub const SystemType = enum {
    system_a,
    system_b,
    default,

    pub fn fromString(str: []const u8) SystemType {
        if (std.mem.eql(u8, str, "system_a")) return .system_a;
        if (std.mem.eql(u8, str, "system_b")) return .system_b;
        return .default;
    }
};

pub const Error = error{
    OutOfMemory,
    InvalidCsvFormat,
    FieldMappingNotFound,
    InvalidQueryRequest,
    ServerError,
};