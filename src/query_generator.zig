const std = @import("std");
const types = @import("types.zig");

pub const QueryGenerator = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) QueryGenerator {
        return .{
            .allocator = allocator,
        };
    }
    
    pub fn generateQuery(
        self: *QueryGenerator,
        query_type: types.QueryType,
        matched_fields: []types.MatchedField,
        system: types.SystemType,
        time_filter: ?[]const u8,
        additional_filter: ?[]const u8,
        limit: ?u32,
        arena: std.mem.Allocator,
    ) ![]const u8 {
        _ = self;
        
        if (matched_fields.len == 0) {
            return error.FieldMappingNotFound;
        }
        
        // Determine primary table from highest-scoring field
        const primary_table = matched_fields[0].table_name;
        
        // Get field names for the specific system
        var field_names = std.ArrayList([]const u8).init(arena);
        var tables = std.StringHashMap(void).init(arena);
        
        for (matched_fields) |field| {
            const field_name = switch (system) {
                .system_a => brk: {
                    // Check if system_a_fieldmap was matched
                    for (matched_fields) |f| {
                        if (std.mem.eql(u8, f.matched_text, field.column_name)) {
                            break :brk field.column_name;
                        }
                    }
                    break :brk try getSystemFieldName(field, "system_a", arena);
                },
                .system_b => brk: {
                    // Check if system_b_fieldmap was matched
                    for (matched_fields) |f| {
                        if (std.mem.eql(u8, f.matched_text, field.column_name)) {
                            break :brk field.column_name;
                        }
                    }
                    break :brk try getSystemFieldName(field, "system_b", arena);
                },
                .default => field.column_name,
            };
            
            try field_names.append(field_name);
            try tables.put(field.table_name, {});
        }
        
        // Build the query based on the type
        var query = std.ArrayList(u8).init(arena);
        
        switch (query_type) {
            .Select => {
                try query.appendSlice("SELECT ");
                
                // Add fields
                for (field_names.items, 0..) |field, i| {
                    if (i > 0) try query.appendSlice(", ");
                    try query.appendSlice(field);
                }
                
                try query.appendSlice("\nFROM ");
                try query.appendSlice(primary_table);
                
                // Add WHERE clause if needed
                var has_where = false;
                
                if (time_filter) |tf| {
                    try query.appendSlice("\nWHERE created_at >= ");
                    try query.appendSlice(tf);
                    has_where = true;
                }
                
                if (additional_filter) |af| {
                    if (has_where) {
                        try query.appendSlice(" AND ");
                    } else {
                        try query.appendSlice("\nWHERE ");
                        has_where = true;
                    }
                    try query.appendSlice(af);
                }
                
                // Add LIMIT if specified
                if (limit) |l| {
                    try query.appendSlice("\nLIMIT ");
                    try query.appendSlice(try std.fmt.allocPrint(arena, "{d}", .{l}));
                }
            },
            
            .Count => {
                try query.appendSlice("SELECT COUNT(*)");
                try query.appendSlice("\nFROM ");
                try query.appendSlice(primary_table);
                
                // Add WHERE clause if needed
                var has_where = false;
                
                if (time_filter) |tf| {
                    try query.appendSlice("\nWHERE created_at >= ");
                    try query.appendSlice(tf);
                    has_where = true;
                }
                
                if (additional_filter) |af| {
                    if (has_where) {
                        try query.appendSlice(" AND ");
                    } else {
                        try query.appendSlice("\nWHERE ");
                        has_where = true;
                    }
                    try query.appendSlice(af);
                }
            },
            
            .GroupBy => {
                // Assume first field is what we're grouping by
                try query.appendSlice("SELECT ");
                try query.appendSlice(field_names.items[0]);
                try query.appendSlice(", COUNT(*)");
                try query.appendSlice("\nFROM ");
                try query.appendSlice(primary_table);
                
                // Add WHERE clause if needed
                var has_where = false;
                
                if (time_filter) |tf| {
                    try query.appendSlice("\nWHERE created_at >= ");
                    try query.appendSlice(tf);
                    has_where = true;
                }
                
                if (additional_filter) |af| {
                    if (has_where) {
                        try query.appendSlice(" AND ");
                    } else {
                        try query.appendSlice("\nWHERE ");
                        has_where = true;
                    }
                    try query.appendSlice(af);
                }
                
                try query.appendSlice("\nGROUP BY ");
                try query.appendSlice(field_names.items[0]);
            },
        }
        
        try query.appendSlice(";");
        
        return query.toOwnedSlice();
    }
    
    fn getSystemFieldName(field: types.MatchedField, system: []const u8, arena: std.mem.Allocator) ![]const u8 {
        if (std.mem.eql(u8, system, "system_a")) {
            return try arena.dupe(u8, "system_a_fieldmap");
        } else if (std.mem.eql(u8, system, "system_b")) {
            return try arena.dupe(u8, "system_b_fieldmap");
        } else {
            return try arena.dupe(u8, field.column_name);
        }
    }
    
    pub fn calculateConfidence(self: *QueryGenerator, matched_fields: []types.MatchedField) f32 {
        _ = self;
        
        if (matched_fields.len == 0) return 0.0;
        
        var total_score: f32 = 0.0;
        for (matched_fields) |field| {
            total_score += field.match_score;
        }
        
        // Normalize confidence score between 0 and 1
        return @min(total_score / 100.0, 1.0);
    }
};