const std = @import("std");
const types = @import("types.zig");
const FieldMapper = @import("field_mapper.zig").FieldMapper;
const NlpEngine = @import("nlp_engine.zig").NlpEngine;
const QueryGenerator = @import("query_generator.zig").QueryGenerator;
const HttpServer = @import("http_server.zig").HttpServer;
const Config = @import("config.zig").Config;

pub fn main() !void {
    // Create a general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Load configuration
    var config = try Config.init(allocator);
    defer config.deinit();
    
    // Initialize components
    var field_mapper = FieldMapper.init(allocator);
    defer field_mapper.deinit();
    
    var nlp_engine = NlpEngine.init(allocator);
    var query_generator = QueryGenerator.init(allocator);
    
    // Create sample CSV file for testing
    try createSampleCsvFile(allocator, config.field_mappings_path);
    
    // Load field mappings from CSV
    std.debug.print("Loading field mappings from {s}...\n", .{config.field_mappings_path});
    try field_mapper.loadFromCsv(config.field_mappings_path);
    std.debug.print("Loaded {} field mappings\n", .{field_mapper.field_mappings.len});
    
    // Check if a query was provided as a command-line argument
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    if (args.len > 1) {
        // Process a single query from the command line
        const query = args[1];
        std.debug.print("Query: \"{s}\"\n", .{query});
        
        // Process the query
        const query_result = try processQuery(
            &field_mapper,
            &nlp_engine,
            &query_generator,
            query,
            types.SystemType.default,
            null,
            arena.allocator()
        );
        
        // Print the result
        std.debug.print("SQL: {s}\n", .{query_result.query});
        std.debug.print("Confidence: {d:.2}\n", .{query_result.confidence});
        std.debug.print("Matched Fields: {d}\n", .{query_result.matched_fields.len});
        
        for (query_result.matched_fields, 0..) |field, i| {
            std.debug.print("  {d}. {s}.{s} (score: {d:.1})\n", .{
                i + 1,
                field.table_name,
                field.column_name,
                field.match_score,
            });
        }
        return;
    }
    
    // Start HTTP server
    var http_server = HttpServer.init(
        allocator,
        &field_mapper,
        &nlp_engine,
        &query_generator,
        config.port
    );
    defer http_server.deinit();
    
    std.debug.print("Starting server on port {}...\n", .{config.port});
    try http_server.start();
}

/// Process a query using the NLP pipeline
fn processQuery(
    field_mapper: *FieldMapper,
    nlp_engine: *NlpEngine,
    query_generator: *QueryGenerator,
    description: []const u8,
    system: types.SystemType,
    limit: ?u32,
    arena: std.mem.Allocator,
) !types.QueryResponse {
    // Extract keywords and detect intent
    const query_type = try nlp_engine.detectQueryType(description, arena);
    const time_filter = try nlp_engine.detectTemporalPattern(description, arena);
    const additional_filter = try nlp_engine.detectFilterPatterns(description, arena);
    
    // Find matching fields
    const matched_fields = try field_mapper.findMatchingFields(
        description,
        system,
        arena
    );
    
    if (matched_fields.len == 0) {
        return error.FieldMappingNotFound;
    }
    
    // Generate SQL query
    const sql_query = try query_generator.generateQuery(
        query_type,
        matched_fields,
        system,
        time_filter,
        additional_filter,
        limit,
        arena
    );
    
    // Calculate confidence score
    const confidence = query_generator.calculateConfidence(matched_fields);
    
    return types.QueryResponse{
        .query = sql_query,
        .matched_fields = matched_fields,
        .confidence = confidence,
    };
}

fn createSampleCsvFile(_: std.mem.Allocator, file_path: []const u8) !void {
    // Check if file already exists
    if (std.fs.cwd().access(file_path, .{})) {
        return;
    } else |_| {
        // File doesn't exist, create it with sample data
        const file = try std.fs.cwd().createFile(file_path, .{});
        defer file.close();
        
        const sample_data =
            \\column_name,table_name,system_a_fieldmap,system_b_fieldmap,field_description,field_type
            \\user_id,users,uid,user_identifier,Unique identifier for user,INTEGER
            \\email,users,email_addr,user_email,User email address,VARCHAR
            \\status,users,account_status,user_status,Account status (active/inactive),VARCHAR
            \\created_at,users,create_date,registration_date,Account creation timestamp,TIMESTAMP
            \\order_id,orders,oid,order_identifier,Unique identifier for order,INTEGER
            \\order_total,orders,amount,total_cost,Total order value in cents,INTEGER
            \\order_status,orders,status,order_state,Current status of order,VARCHAR
            \\order_date,orders,purchase_date,order_timestamp,Date when order was placed,TIMESTAMP
            \\product_id,products,pid,product_identifier,Unique identifier for product,INTEGER
            \\product_name,products,name,product_name,Name of the product,VARCHAR
            \\price,products,cost,product_price,Product price in cents,INTEGER
            \\category,products,product_category,product_type,Product category,VARCHAR
        ;
        
        try file.writeAll(sample_data);
        std.debug.print("Created sample CSV file at {s}\n", .{file_path});
    }
}