const std = @import("std");
const types = @import("types.zig");

pub const NlpEngine = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) NlpEngine {
        return .{
            .allocator = allocator,
        };
    }
    
    pub fn detectQueryType(self: *NlpEngine, description: []const u8, arena: std.mem.Allocator) !types.QueryType {
        _ = self;
        
        // Convert description to lowercase for easier matching
        const lower_buf1 = try arena.alloc(u8, description.len);
        const lower_desc = std.ascii.lowerString(lower_buf1, description);
        
        // Check for COUNT intent
        if (std.mem.indexOf(u8, lower_desc, "how many") != null or
            std.mem.indexOf(u8, lower_desc, "count") != null or
            std.mem.indexOf(u8, lower_desc, "total number") != null) {
            return types.QueryType.Count;
        }
        
        // Check for GROUP BY intent
        if (std.mem.indexOf(u8, lower_desc, "by category") != null or
            std.mem.indexOf(u8, lower_desc, "group by") != null or
            std.mem.indexOf(u8, lower_desc, "breakdown") != null) {
            return types.QueryType.GroupBy;
        }
        
        // Default to SELECT
        return types.QueryType.Select;
    }
    
    pub fn extractKeywords(self: *NlpEngine, description: []const u8, arena: std.mem.Allocator) ![][]const u8 {
        _ = self;
        
        var keywords = std.ArrayList([]const u8).init(arena);
        
        const stop_words = [_][]const u8{
            "a", "an", "the", "of", "for", "with", "by", "in", "on", "at", "to", "and", "or", "but",
            "get", "find", "show", "list", "me", "all", "from",
        };
        
        // Convert to lowercase
        const lower_buf2 = try arena.alloc(u8, description.len);
        const lower_desc = std.ascii.lowerString(lower_buf2, description);
        
        // Split by whitespace
        var it = std.mem.split(u8, lower_desc, " ");
        while (it.next()) |word| {
            if (word.len == 0) continue;
            
            // Skip stop words
            var is_stop_word = false;
            for (stop_words) |stop_word| {
                if (std.mem.eql(u8, word, stop_word)) {
                    is_stop_word = true;
                    break;
                }
            }
            if (is_stop_word) continue;
            
            try keywords.append(try arena.dupe(u8, word));
        }
        
        return keywords.toOwnedSlice();
    }
    
    pub fn detectTemporalPattern(self: *NlpEngine, description: []const u8, arena: std.mem.Allocator) !?[]const u8 {
        _ = self;
        
        // Convert to lowercase
        const lower_buf3 = try arena.alloc(u8, description.len);
        const lower_desc = std.ascii.lowerString(lower_buf3, description);
        
        const patterns = [_]struct { pattern: []const u8, sql: []const u8 }{
            .{ .pattern = "last 7 days", .sql = "CURRENT_DATE - INTERVAL '7 days'" },
            .{ .pattern = "last week", .sql = "CURRENT_DATE - INTERVAL '7 days'" },
            .{ .pattern = "last 30 days", .sql = "CURRENT_DATE - INTERVAL '30 days'" },
            .{ .pattern = "last month", .sql = "CURRENT_DATE - INTERVAL '1 month'" },
            .{ .pattern = "last 90 days", .sql = "CURRENT_DATE - INTERVAL '90 days'" },
            .{ .pattern = "last 3 months", .sql = "CURRENT_DATE - INTERVAL '3 months'" },
            .{ .pattern = "last year", .sql = "CURRENT_DATE - INTERVAL '1 year'" },
            .{ .pattern = "last 365 days", .sql = "CURRENT_DATE - INTERVAL '365 days'" },
            .{ .pattern = "yesterday", .sql = "CURRENT_DATE - INTERVAL '1 day'" },
            .{ .pattern = "today", .sql = "CURRENT_DATE" },
        };
        
        for (patterns) |p| {
            if (std.mem.indexOf(u8, lower_desc, p.pattern)) |_| {
                return try arena.dupe(u8, p.sql);
            }
        }
        
        return null;
    }
    
    pub fn detectFilterPatterns(self: *NlpEngine, description: []const u8, arena: std.mem.Allocator) !?[]const u8 {
        _ = self;
        
        // Convert to lowercase
        const lower_buf4 = try arena.alloc(u8, description.len);
        const lower_desc = std.ascii.lowerString(lower_buf4, description);
        
        const patterns = [_]struct { pattern: []const u8, column: []const u8, value: []const u8 }{
            .{ .pattern = "active", .column = "status", .value = "'active'" },
            .{ .pattern = "inactive", .column = "status", .value = "'inactive'" },
            .{ .pattern = "pending", .column = "status", .value = "'pending'" },
            .{ .pattern = "completed", .column = "status", .value = "'completed'" },
        };
        
        for (patterns) |p| {
            if (std.mem.indexOf(u8, lower_desc, p.pattern)) |_| {
                const filter = try std.fmt.allocPrint(arena, "{s} = {s}", .{ p.column, p.value });
                return filter;
            }
        }
        
        return null;
    }
};