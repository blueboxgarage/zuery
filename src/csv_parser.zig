const std = @import("std");
const types = @import("types.zig");

pub const CsvParser = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) CsvParser {
        return .{
            .allocator = allocator,
        };
    }
    
    pub fn parseFile(self: *CsvParser, file_path: []const u8) ![]types.FieldMapping {
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();
        
        var buffered_reader = std.io.bufferedReader(file.reader());
        var reader = buffered_reader.reader();
        
        var mappings = std.ArrayList(types.FieldMapping).init(self.allocator);
        errdefer {
            // Clean up any fields that were already added
            for (mappings.items) |mapping| {
                self.allocator.free(mapping.column_name);
                self.allocator.free(mapping.table_name);
                self.allocator.free(mapping.system_a_fieldmap);
                self.allocator.free(mapping.system_b_fieldmap);
                self.allocator.free(mapping.field_description);
                self.allocator.free(mapping.field_type);
            }
            mappings.deinit();
        }
        
        // Skip header line
        var header_buffer: [1024]u8 = undefined;
        _ = try reader.readUntilDelimiterOrEof(&header_buffer, '\n');
        
        // Parse data rows
        var buffer: [1024]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len == 0) continue;
            
            const field_mapping = try self.parseCsvLine(line);
            try mappings.append(field_mapping);
        }
        
        return mappings.toOwnedSlice();
    }
    
    fn parseCsvLine(self: *CsvParser, line: []const u8) !types.FieldMapping {
        var fields = std.ArrayList([]const u8).init(self.allocator);
        defer {
            // We don't need to free the strings in fields.items since they'll be owned by the field_mapping
            fields.deinit();
        }
        
        var current_field = std.ArrayList(u8).init(self.allocator);
        defer current_field.deinit();
        
        var in_quotes = false;
        var i: usize = 0;
        
        while (i < line.len) : (i += 1) {
            const char = line[i];
            
            if (char == '"') {
                in_quotes = !in_quotes;
                continue;
            }
            
            if (char == ',' and !in_quotes) {
                try fields.append(try self.allocator.dupe(u8, current_field.items));
                current_field.clearRetainingCapacity();
                continue;
            }
            
            try current_field.append(char);
        }
        
        // Add the last field
        try fields.append(try self.allocator.dupe(u8, current_field.items));
        
        if (fields.items.len < 6) {
            // Free any fields that were allocated
            for (fields.items) |field| {
                self.allocator.free(field);
            }
            return error.InvalidCsvFormat;
        }
        
        return types.FieldMapping{
            .column_name = fields.items[0],
            .table_name = fields.items[1],
            .system_a_fieldmap = fields.items[2],
            .system_b_fieldmap = fields.items[3],
            .field_description = fields.items[4],
            .field_type = fields.items[5],
        };
    }
    
    pub fn freeFieldMappings(self: *CsvParser, mappings: []types.FieldMapping) void {
        for (mappings) |mapping| {
            self.allocator.free(mapping.column_name);
            self.allocator.free(mapping.table_name);
            self.allocator.free(mapping.system_a_fieldmap);
            self.allocator.free(mapping.system_b_fieldmap);
            self.allocator.free(mapping.field_description);
            self.allocator.free(mapping.field_type);
        }
        self.allocator.free(mappings);
    }
};