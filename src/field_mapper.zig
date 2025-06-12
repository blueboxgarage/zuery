const std = @import("std");
const types = @import("types.zig");
const CsvParser = @import("csv_parser.zig").CsvParser;

pub const FieldMapper = struct {
    allocator: std.mem.Allocator,
    field_mappings: []types.FieldMapping,
    parser: CsvParser,
    
    pub fn init(allocator: std.mem.Allocator) FieldMapper {
        return .{
            .allocator = allocator,
            .field_mappings = &[_]types.FieldMapping{},
            .parser = CsvParser.init(allocator),
        };
    }
    
    pub fn deinit(self: *FieldMapper) void {
        if (self.field_mappings.len > 0) {
            self.parser.freeFieldMappings(self.field_mappings);
        }
    }
    
    pub fn loadFromCsv(self: *FieldMapper, file_path: []const u8) !void {
        // Clear any existing field mappings
        if (self.field_mappings.len > 0) {
            self.parser.freeFieldMappings(self.field_mappings);
            self.field_mappings = &[_]types.FieldMapping{};
        }
        
        self.field_mappings = try self.parser.parseFile(file_path);
    }
    
    pub fn findMatchingFields(
        self: *FieldMapper, 
        description: []const u8,
        system: types.SystemType,
        arena: std.mem.Allocator
    ) ![]types.MatchedField {
        var matches = std.ArrayList(types.MatchedField).init(arena);
        
        // Convert description to lowercase for matching
        const lower_desc_buf = try arena.alloc(u8, description.len);
        const lower_desc = std.ascii.lowerString(lower_desc_buf, description);
        
        // Simple keyword matching for now
        for (self.field_mappings) |field| {
            var score: f32 = 0.0;
            
            // Create lowercase versions of the fields we want to match against
            const buf1 = try arena.alloc(u8, field.field_description.len);
            const lower_field_desc = std.ascii.lowerString(buf1, field.field_description);
            
            const buf2 = try arena.alloc(u8, field.column_name.len);
            const lower_column_name = std.ascii.lowerString(buf2, field.column_name);
            
            // Check if description contains the field description
            if (std.mem.indexOf(u8, lower_desc, lower_field_desc)) |_| {
                score += 50.0;
            }
            
            // Check if description contains the column name
            if (std.mem.indexOf(u8, lower_desc, lower_column_name)) |_| {
                score += 40.0;
            }
            
            // Get the appropriate field map for the selected system
            const field_map = switch (system) {
                .system_a => field.system_a_fieldmap,
                .system_b => field.system_b_fieldmap,
                .default => field.column_name,
            };
            
            const buf3 = try arena.alloc(u8, field_map.len);
            const lower_field_map = std.ascii.lowerString(buf3, field_map);
            
            // Check if description contains the system-specific field map
            if (std.mem.indexOf(u8, lower_desc, lower_field_map)) |_| {
                score += 60.0;
            }
            
            // Add field to matches if it scores above threshold
            if (score > 30.0) {
                try matches.append(.{
                    .column_name = try arena.dupe(u8, field.column_name),
                    .table_name = try arena.dupe(u8, field.table_name),
                    .field_description = try arena.dupe(u8, field.field_description),
                    .field_type = try arena.dupe(u8, field.field_type),
                    .match_score = score,
                    .matched_text = try arena.dupe(u8, field_map),
                });
            }
        }
        
        // Sort by score (highest first)
        std.sort.insertion(types.MatchedField, matches.items, {}, struct {
            fn lessThan(_: void, a: types.MatchedField, b: types.MatchedField) bool {
                return a.match_score > b.match_score;
            }
        }.lessThan);
        
        return matches.toOwnedSlice();
    }
    
    pub fn getAllFields(self: *FieldMapper, arena: std.mem.Allocator) ![]types.FieldMapping {
        var result = try arena.alloc(types.FieldMapping, self.field_mappings.len);
        for (self.field_mappings, 0..) |field, i| {
            result[i] = .{
                .column_name = try arena.dupe(u8, field.column_name),
                .table_name = try arena.dupe(u8, field.table_name),
                .system_a_fieldmap = try arena.dupe(u8, field.system_a_fieldmap),
                .system_b_fieldmap = try arena.dupe(u8, field.system_b_fieldmap),
                .field_description = try arena.dupe(u8, field.field_description),
                .field_type = try arena.dupe(u8, field.field_type),
            };
        }
        return result;
    }
};