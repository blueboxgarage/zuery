const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const FieldMapper = @import("field_mapper.zig").FieldMapper;
const NlpEngine = @import("nlp_engine.zig").NlpEngine;
const QueryGenerator = @import("query_generator.zig").QueryGenerator;
const CsvParser = @import("csv_parser.zig").CsvParser;

test "nlp_engine query type detection" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    var nlp = NlpEngine.init(testing.allocator);
    
    try testing.expectEqual(
        types.QueryType.Select,
        try nlp.detectQueryType("get all users", arena.allocator())
    );
    
    try testing.expectEqual(
        types.QueryType.Count,
        try nlp.detectQueryType("how many users are there", arena.allocator())
    );
    
    try testing.expectEqual(
        types.QueryType.GroupBy,
        try nlp.detectQueryType("show orders by category", arena.allocator())
    );
}

test "nlp_engine temporal pattern detection" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    var nlp = NlpEngine.init(testing.allocator);
    
    const pattern1 = try nlp.detectTemporalPattern("from last 30 days", arena.allocator());
    try testing.expect(pattern1 != null);
    try testing.expectEqualStrings("CURRENT_DATE - INTERVAL '30 days'", pattern1.?);
    
    const pattern2 = try nlp.detectTemporalPattern("created yesterday", arena.allocator());
    try testing.expect(pattern2 != null);
    try testing.expectEqualStrings("CURRENT_DATE - INTERVAL '1 day'", pattern2.?);
    
    const pattern3 = try nlp.detectTemporalPattern("no date pattern here", arena.allocator());
    try testing.expect(pattern3 == null);
}

test "nlp_engine filter pattern detection" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    var nlp = NlpEngine.init(testing.allocator);
    
    const pattern1 = try nlp.detectFilterPatterns("get active users", arena.allocator());
    try testing.expect(pattern1 != null);
    try testing.expectEqualStrings("status = 'active'", pattern1.?);
    
    const pattern2 = try nlp.detectFilterPatterns("completed orders", arena.allocator());
    try testing.expect(pattern2 != null);
    try testing.expectEqualStrings("status = 'completed'", pattern2.?);
    
    const pattern3 = try nlp.detectFilterPatterns("no filter pattern", arena.allocator());
    try testing.expect(pattern3 == null);
}

test "csv_parser basic parsing" {
    const test_csv = 
        \\column_name,table_name,system_a_fieldmap,system_b_fieldmap,field_description,field_type
        \\user_id,users,uid,user_identifier,Unique identifier for user,INTEGER
        \\email,users,email_addr,user_email,User email address,VARCHAR
    ;
    
    var parser = CsvParser.init(testing.allocator);
    
    // Write the test CSV to a temporary file
    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();
    
    {
        var tmp_file = try tmp_dir.dir.createFile("test.csv", .{});
        try tmp_file.writeAll(test_csv);
        tmp_file.close(); // Close the file to ensure data is written
    }
    
    // Get the absolute path to the temporary file
    const realpath = try tmp_dir.dir.realpathAlloc(testing.allocator, "test.csv");
    defer testing.allocator.free(realpath);
    
    const path = try std.fs.path.join(testing.allocator, &[_][]const u8{ realpath });
    defer testing.allocator.free(path);
    
    const mappings = try parser.parseFile(path);
    defer parser.freeFieldMappings(mappings);
    
    try testing.expectEqual(@as(usize, 2), mappings.len);
    try testing.expectEqualStrings("user_id", mappings[0].column_name);
    try testing.expectEqualStrings("users", mappings[0].table_name);
    try testing.expectEqualStrings("uid", mappings[0].system_a_fieldmap);
    try testing.expectEqualStrings("email", mappings[1].column_name);
    try testing.expectEqualStrings("users", mappings[1].table_name);
    try testing.expectEqualStrings("email_addr", mappings[1].system_a_fieldmap);
}

test "query_generator basic sql generation" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    var query_gen = QueryGenerator.init(testing.allocator);
    
    var test_fields = [_]types.MatchedField{
        .{
            .column_name = "email",
            .table_name = "users",
            .field_description = "User email address",
            .field_type = "VARCHAR",
            .match_score = 85.0,
            .matched_text = "email",
        }
    };
    
    const query = try query_gen.generateQuery(
        types.QueryType.Select,
        &test_fields,
        types.SystemType.default,
        null,
        null,
        null,
        arena.allocator()
    );
    
    try testing.expectEqualStrings("SELECT email\nFROM users;", query);
}

test "field_mapper matching functionality" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    var mapper = FieldMapper.init(testing.allocator);
    defer mapper.deinit();
    
    // Manually set up some test mappings
    const test_mappings = [_]types.FieldMapping{
        .{
            .column_name = "user_id",
            .table_name = "users",
            .system_a_fieldmap = "uid",
            .system_b_fieldmap = "user_identifier",
            .field_description = "Unique identifier for user",
            .field_type = "INTEGER",
        },
        .{
            .column_name = "email",
            .table_name = "users",
            .system_a_fieldmap = "email_addr",
            .system_b_fieldmap = "user_email",
            .field_description = "User email address",
            .field_type = "VARCHAR",
        },
        .{
            .column_name = "first_name",
            .table_name = "users",
            .system_a_fieldmap = "fname",
            .system_b_fieldmap = "first_name",
            .field_description = "User's first name",
            .field_type = "VARCHAR",
        },
    };
    
    // Allocate and copy the test mappings
    var mappings = try testing.allocator.alloc(types.FieldMapping, test_mappings.len);
    for (test_mappings, 0..) |mapping, i| {
        mappings[i] = .{
            .column_name = try testing.allocator.dupe(u8, mapping.column_name),
            .table_name = try testing.allocator.dupe(u8, mapping.table_name),
            .system_a_fieldmap = try testing.allocator.dupe(u8, mapping.system_a_fieldmap),
            .system_b_fieldmap = try testing.allocator.dupe(u8, mapping.system_b_fieldmap),
            .field_description = try testing.allocator.dupe(u8, mapping.field_description),
            .field_type = try testing.allocator.dupe(u8, mapping.field_type),
        };
    }
    
    // Set the mappings
    if (mapper.field_mappings.len > 0) {
        mapper.parser.freeFieldMappings(mapper.field_mappings);
    }
    mapper.field_mappings = mappings;
    
    // Test default system
    {
        const matches = try mapper.findMatchingFields("get user email", .default, arena.allocator());
        try testing.expectEqual(@as(usize, 1), matches.len);
        try testing.expectEqualStrings("email", matches[0].column_name);
    }
    
    // Test system_a specific mapping
    {
        const matches = try mapper.findMatchingFields("find the uid of a user", .system_a, arena.allocator());
        try testing.expectEqual(@as(usize, 1), matches.len);
        try testing.expectEqualStrings("user_id", matches[0].column_name);
        try testing.expectEqualStrings("uid", matches[0].matched_text);
    }
    
    // Test system_b specific mapping
    {
        const matches = try mapper.findMatchingFields("show me the user_email", .system_b, arena.allocator());
        try testing.expectEqual(@as(usize, 1), matches.len);
        try testing.expectEqualStrings("email", matches[0].column_name);
        try testing.expectEqualStrings("user_email", matches[0].matched_text);
    }
    
    // Test multiple matches with fields that will match
    {
        const matches = try mapper.findMatchingFields("get user id and email information", .default, arena.allocator());
        try testing.expect(matches.len > 0);
    }
}

const Config = @import("config.zig").Config;

test "config initialization and defaults" {
    var config = try Config.init(testing.allocator);
    defer config.deinit();
    
    // Test default values
    try testing.expectEqual(@as(u16, 8080), config.port);
    try testing.expectEqualStrings("field_mappings.csv", config.field_mappings_path);
    try testing.expectEqual(@as(f32, 30.0), config.fuzzy_matching_threshold);
    
    // Test modifying values
    config.port = 9090;
    try testing.expectEqual(@as(u16, 9090), config.port);
    
    const new_path = try testing.allocator.dupe(u8, "new_mappings.csv");
    testing.allocator.free(config.field_mappings_path);
    config.field_mappings_path = new_path;
    try testing.expectEqualStrings("new_mappings.csv", config.field_mappings_path);
    
    config.fuzzy_matching_threshold = 50.0;
    try testing.expectEqual(@as(f32, 50.0), config.fuzzy_matching_threshold);
}

const HttpServer = @import("http_server.zig").HttpServer;

// This test simulates the full workflow of the system
test "integration - full query generation process" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    // Initialize all required components
    var mapper = FieldMapper.init(testing.allocator);
    defer mapper.deinit();
    
    var nlp = NlpEngine.init(testing.allocator);
    
    var query_gen = QueryGenerator.init(testing.allocator);
    
    // Set up some test field mappings
    const test_mappings = [_]types.FieldMapping{
        .{
            .column_name = "user_id",
            .table_name = "users",
            .system_a_fieldmap = "uid",
            .system_b_fieldmap = "user_identifier",
            .field_description = "Unique identifier for user",
            .field_type = "INTEGER",
        },
        .{
            .column_name = "email",
            .table_name = "users",
            .system_a_fieldmap = "email_addr",
            .system_b_fieldmap = "user_email",
            .field_description = "User email address",
            .field_type = "VARCHAR",
        },
        .{
            .column_name = "status",
            .table_name = "users",
            .system_a_fieldmap = "user_status",
            .system_b_fieldmap = "account_status",
            .field_description = "User account status",
            .field_type = "VARCHAR",
        },
        .{
            .column_name = "created_at",
            .table_name = "users",
            .system_a_fieldmap = "creation_date",
            .system_b_fieldmap = "registration_date",
            .field_description = "User registration date",
            .field_type = "TIMESTAMP",
        },
        .{
            .column_name = "product_id",
            .table_name = "products",
            .system_a_fieldmap = "pid",
            .system_b_fieldmap = "product_identifier",
            .field_description = "Product unique identifier",
            .field_type = "INTEGER",
        },
        .{
            .column_name = "category",
            .table_name = "products",
            .system_a_fieldmap = "product_category",
            .system_b_fieldmap = "product_type",
            .field_description = "Product category",
            .field_type = "VARCHAR",
        },
    };
    
    // Allocate and copy the test mappings
    var mappings = try testing.allocator.alloc(types.FieldMapping, test_mappings.len);
    for (test_mappings, 0..) |mapping, i| {
        mappings[i] = .{
            .column_name = try testing.allocator.dupe(u8, mapping.column_name),
            .table_name = try testing.allocator.dupe(u8, mapping.table_name),
            .system_a_fieldmap = try testing.allocator.dupe(u8, mapping.system_a_fieldmap),
            .system_b_fieldmap = try testing.allocator.dupe(u8, mapping.system_b_fieldmap),
            .field_description = try testing.allocator.dupe(u8, mapping.field_description),
            .field_type = try testing.allocator.dupe(u8, mapping.field_type),
        };
    }
    
    // Set the mappings
    if (mapper.field_mappings.len > 0) {
        mapper.parser.freeFieldMappings(mapper.field_mappings);
    }
    mapper.field_mappings = mappings;
    
    // Create the HTTP server
    var server = HttpServer.init(
        testing.allocator,
        &mapper,
        &nlp,
        &query_gen,
        8080
    );
    defer server.deinit();
    
    // Define test cases with expected outcomes
    const TestCase = struct {
        query: []const u8,
        system_type: types.SystemType,
        expected_query_type: types.QueryType,
        expected_table: []const u8,
        expected_has_time_filter: bool,
        expected_has_status_filter: bool,
    };
    
    const test_cases = [_]TestCase{
        .{
            .query = "get user status field",
            .system_type = .default,
            .expected_query_type = .Select,
            .expected_table = "users",
            .expected_has_time_filter = false,
            .expected_has_status_filter = true,
        },
        .{
            .query = "show me user_id and email",
            .system_type = .default,
            .expected_query_type = .Select,
            .expected_table = "users",
            .expected_has_time_filter = false,
            .expected_has_status_filter = false,
        },
        .{
            .query = "count products by product_category",
            .system_type = .default,
            .expected_query_type = .GroupBy,
            .expected_table = "products",
            .expected_has_time_filter = false,
            .expected_has_status_filter = false,
        },
        .{
            .query = "how many user_id are there",
            .system_type = .default,
            .expected_query_type = .Count,
            .expected_table = "users",
            .expected_has_time_filter = false,
            .expected_has_status_filter = false,
        },
    };
    
    for (test_cases) |test_case| {
        var test_arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer test_arena.deinit();
        
        const result = try server.processQuery(
            test_case.query, 
            test_case.system_type, 
            null, 
            test_arena.allocator()
        );
        
        // Check the response has the expected properties
        try testing.expect(result.matched_fields.len > 0);
        try testing.expect(result.confidence > 0.0);
        try testing.expect(result.query.len > 0);
        
        // Check that the proper tables are referenced
        try testing.expect(std.mem.indexOf(u8, result.query, test_case.expected_table) != null);
        
        // Check for time filter if expected
        if (test_case.expected_has_time_filter) {
            try testing.expect(std.mem.indexOf(u8, result.query, "CURRENT_DATE") != null);
        }
        
        // Check for status filter if expected
        if (test_case.expected_has_status_filter) {
            try testing.expect(std.mem.indexOf(u8, result.query, "status") != null);
        }
    }
}

test "http_server error handling" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    
    // Initialize all required components
    var mapper = FieldMapper.init(testing.allocator);
    defer mapper.deinit();
    
    var nlp = NlpEngine.init(testing.allocator);
    
    var query_gen = QueryGenerator.init(testing.allocator);
    
    // Create empty field mappings (to force error)
    if (mapper.field_mappings.len > 0) {
        mapper.parser.freeFieldMappings(mapper.field_mappings);
    }
    mapper.field_mappings = &[_]types.FieldMapping{};
    
    // Create the HTTP server
    var server = HttpServer.init(
        testing.allocator,
        &mapper,
        &nlp,
        &query_gen,
        8080
    );
    defer server.deinit();
    
    // Test with an empty query
    {
        var test_arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer test_arena.deinit();
        
        const result = server.processQuery(
            "", 
            .default, 
            null, 
            test_arena.allocator()
        );
        
        // Should fail due to no field mappings
        try testing.expectError(error.FieldMappingNotFound, result);
    }
    
    // Test with an unknown system type
    {
        var test_arena = std.heap.ArenaAllocator.init(testing.allocator);
        defer test_arena.deinit();
        
        // Add a field mapping
        const test_mappings = [_]types.FieldMapping{
            .{
                .column_name = try testing.allocator.dupe(u8, "test"),
                .table_name = try testing.allocator.dupe(u8, "test"),
                .system_a_fieldmap = try testing.allocator.dupe(u8, "test"),
                .system_b_fieldmap = try testing.allocator.dupe(u8, "test"),
                .field_description = try testing.allocator.dupe(u8, "test"),
                .field_type = try testing.allocator.dupe(u8, "VARCHAR"),
            },
        };
        
        var mappings = try testing.allocator.alloc(types.FieldMapping, test_mappings.len);
        mappings[0] = test_mappings[0];
        
        if (mapper.field_mappings.len > 0) {
            mapper.parser.freeFieldMappings(mapper.field_mappings);
        }
        mapper.field_mappings = mappings;
        
        // This should succeed but use the default system
        const result = try server.processQuery(
            "test", 
            .system_b, 
            null, 
            test_arena.allocator()
        );
        
        try testing.expect(result.query.len > 0);
    }
}