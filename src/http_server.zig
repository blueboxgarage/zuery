const std = @import("std");
const types = @import("types.zig");
const FieldMapper = @import("field_mapper.zig").FieldMapper;
const NlpEngine = @import("nlp_engine.zig").NlpEngine;
const QueryGenerator = @import("query_generator.zig").QueryGenerator;

pub const HttpError = error{
    RequestTooLarge,
    InvalidRequest,
    InternalServerError,
};

pub const HttpServer = struct {
    allocator: std.mem.Allocator,
    field_mapper: *FieldMapper,
    nlp_engine: *NlpEngine,
    query_generator: *QueryGenerator,
    port: u16,
    
    pub fn init(
        allocator: std.mem.Allocator,
        field_mapper: *FieldMapper,
        nlp_engine: *NlpEngine,
        query_generator: *QueryGenerator,
        port: u16,
    ) HttpServer {
        return HttpServer{
            .allocator = allocator,
            .field_mapper = field_mapper,
            .nlp_engine = nlp_engine,
            .query_generator = query_generator,
            .port = port,
        };
    }
    
    pub fn deinit(self: *HttpServer) void {
        _ = self;
    }
    
    /// This is a simulated server that demonstrates the API functionality
    /// A real implementation would use std.net for the HTTP server
    pub fn start(self: *HttpServer) !void {
        // This is a simplified version - just print some test output for now
        std.debug.print("Server would listen on 0.0.0.0:{}\n", .{self.port});
        
        // Process a few sample queries to demonstrate functionality
        try self.processSampleQueries();
    }
    
    fn processSampleQueries(self: *HttpServer) !void {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        
        const samples = [_][]const u8{
            "get all active users with email addresses from last 30 days",
            "count total orders from last week",
            "show me all products by category",
            "find users who registered yesterday",
            "get all orders with total over 100",
        };
        
        std.debug.print("\n===== Sample Query Results =====\n\n", .{});
        
        for (samples) |query| {
            var query_arena = std.heap.ArenaAllocator.init(self.allocator);
            defer query_arena.deinit();
            
            std.debug.print("Query: \"{s}\"\n", .{query});
            
            // Process the query
            const query_result = try self.processQuery(
                query,
                types.SystemType.default,
                null,
                query_arena.allocator()
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
            
            std.debug.print("\n----------------------------\n\n", .{});
        }
    }
    
    pub fn processQuery(
        self: *HttpServer,
        description: []const u8,
        system: types.SystemType,
        limit: ?u32,
        arena: std.mem.Allocator,
    ) !types.QueryResponse {
        // Extract keywords and detect intent
        const query_type = try self.nlp_engine.detectQueryType(description, arena);
        const time_filter = try self.nlp_engine.detectTemporalPattern(description, arena);
        const additional_filter = try self.nlp_engine.detectFilterPatterns(description, arena);
        
        // Find matching fields
        const matched_fields = try self.field_mapper.findMatchingFields(
            description,
            system,
            arena
        );
        
        if (matched_fields.len == 0) {
            return error.FieldMappingNotFound;
        }
        
        // Generate SQL query
        const sql_query = try self.query_generator.generateQuery(
            query_type,
            matched_fields,
            system,
            time_filter,
            additional_filter,
            limit,
            arena
        );
        
        // Calculate confidence score
        const confidence = self.query_generator.calculateConfidence(matched_fields);
        
        return types.QueryResponse{
            .query = sql_query,
            .matched_fields = matched_fields,
            .confidence = confidence,
        };
    }
};