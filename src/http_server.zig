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
    pub fn start(self: *HttpServer) !void {
        // Just print some test output for now
        std.debug.print("Server would listen on 0.0.0.0:{}\n", .{self.port});
        
        // Show curl examples
        std.debug.print("\nTest with curl:\n", .{});
        std.debug.print("curl -X POST http://localhost:{d}/query -H \"Content-Type: application/json\" -d '", .{self.port});
        std.debug.print("{{\"query\": \"get all active users\"}}'\n\n", .{});
        
        // Process a few sample queries to demonstrate functionality
        try self.processSampleQueries();
        
        // Print instructions for running a separate HTTP server
        std.debug.print("\n===== Run a Separate HTTP Server =====\n\n", .{});
        std.debug.print("To test with a real HTTP server, you can use a simple Python server:\n\n", .{});
        std.debug.print("1. Create a file named zuery_server.py with this content:\n\n", .{});
        std.debug.print("```python\n", .{});
        std.debug.print("from http.server import HTTPServer, BaseHTTPRequestHandler\n", .{});
        std.debug.print("import json\n", .{});
        std.debug.print("import subprocess\n", .{});
        std.debug.print("import os\n\n", .{});
        
        std.debug.print("class ZueryHandler(BaseHTTPRequestHandler):\n", .{});
        std.debug.print("    def do_POST(self):\n", .{});
        std.debug.print("        if self.path != '/query':\n", .{});
        std.debug.print("            self.send_response(404)\n", .{});
        std.debug.print("            self.end_headers()\n", .{});
        std.debug.print("            self.wfile.write(b'{{\"error\": \"Not found\"}}')\n", .{});
        std.debug.print("            return\n\n", .{});
        
        std.debug.print("        content_length = int(self.headers['Content-Length'])\n", .{});
        std.debug.print("        post_data = self.rfile.read(content_length)\n", .{});
        std.debug.print("        data = json.loads(post_data.decode('utf-8'))\n\n", .{});
        
        std.debug.print("        if 'query' not in data:\n", .{});
        std.debug.print("            self.send_response(400)\n", .{});
        std.debug.print("            self.end_headers()\n", .{});
        std.debug.print("            self.wfile.write(b'{{\"error\": \"Missing query field\"}}')\n", .{});
        std.debug.print("            return\n\n", .{});
        
        std.debug.print("        query = data['query']\n", .{});
        std.debug.print("        # Call the zuery binary with the query\n", .{});
        std.debug.print("        result = subprocess.run(\n", .{});
        std.debug.print("            ['/home/mgarce/zuery/zig-out/bin/zuery', query],\n", .{});
        std.debug.print("            capture_output=True,\n", .{});
        std.debug.print("            text=True\n", .{});
        std.debug.print("        )\n\n", .{});
        
        std.debug.print("        # Parse the output and format it as JSON\n", .{});
        std.debug.print("        lines = result.stdout.strip().split('\\n')\n", .{});
        std.debug.print("        response = {{\n", .{});
        std.debug.print("            'sql': lines[1].replace('SQL: ', ''),\n", .{});
        std.debug.print("            'confidence': float(lines[2].replace('Confidence: ', '')),\n", .{});
        std.debug.print("            'matched_fields': []\n", .{});
        std.debug.print("        }}\n\n", .{});
        
        std.debug.print("        self.send_response(200)\n", .{});
        std.debug.print("        self.send_header('Content-type', 'application/json')\n", .{});
        std.debug.print("        self.end_headers()\n", .{});
        std.debug.print("        self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))\n\n", .{});
        
        std.debug.print("httpd = HTTPServer(('0.0.0.0', 8080), ZueryHandler)\n", .{});
        std.debug.print("print('Server running at http://0.0.0.0:8080')\n", .{});
        std.debug.print("httpd.serve_forever()\n", .{});
        std.debug.print("```\n\n", .{});
        
        std.debug.print("2. Run the server: python3 zuery_server.py\n\n", .{});
        std.debug.print("3. Test with curl: curl -X POST http://localhost:8080/query -H \"Content-Type: application/json\" -d '{{\"query\": \"get all active users\"}}'\n", .{});
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