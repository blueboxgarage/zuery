const std = @import("std");

pub const Config = struct {
    allocator: std.mem.Allocator,
    port: u16,
    field_mappings_path: []const u8,
    fuzzy_matching_threshold: f32,
    
    pub fn init(allocator: std.mem.Allocator) !Config {
        var config = Config{
            .allocator = allocator,
            .port = 8080,
            .field_mappings_path = try allocator.dupe(u8, "field_mappings.csv"),
            .fuzzy_matching_threshold = 30.0,
        };
        
        // Try to read environment variables
        if (std.process.getEnvVarOwned(allocator, "PORT")) |port_str| {
            defer allocator.free(port_str);
            config.port = std.fmt.parseInt(u16, port_str, 10) catch config.port;
        } else |_| {}
        
        if (std.process.getEnvVarOwned(allocator, "FIELD_MAPPINGS_PATH")) |path| {
            allocator.free(config.field_mappings_path);
            config.field_mappings_path = path;
        } else |_| {}
        
        if (std.process.getEnvVarOwned(allocator, "FUZZY_MATCHING_THRESHOLD")) |threshold_str| {
            defer allocator.free(threshold_str);
            config.fuzzy_matching_threshold = std.fmt.parseFloat(f32, threshold_str) catch config.fuzzy_matching_threshold;
        } else |_| {}
        
        return config;
    }
    
    pub fn deinit(self: *Config) void {
        self.allocator.free(self.field_mappings_path);
        self.* = undefined;
    }
};