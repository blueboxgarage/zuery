# PostgreSQL Query Generator API - Zig Implementation

**Claude Code Instructions for Building a Natural Language to SQL API Service**

## 🎯 Project Overview

Build a high-performance REST API service in Zig that converts natural language descriptions into PostgreSQL queries using a CSV-based field mapping system. This service will allow non-technical users to query databases using plain English.

## 📋 Core Requirements

### **Primary Functionality**
- Parse CSV file containing database field mappings
- Accept natural language descriptions via HTTP POST
- Generate PostgreSQL queries using fuzzy field matching
- Return structured JSON responses with generated SQL and confidence scores
- Support multiple field mapping systems (system_a, system_b, default)

### **CSV Field Mapping Format**
```csv
column_name,table_name,system_a_fieldmap,system_b_fieldmap,field_description,field_type
user_id,users,uid,user_identifier,Unique identifier for user,INTEGER
email,users,email_addr,user_email,User email address,VARCHAR
created_at,users,create_date,registration_date,Account creation timestamp,TIMESTAMP
order_total,orders,amount,total_cost,Total order value in cents,INTEGER
order_status,orders,status,order_state,Current status of order,VARCHAR
```

## 🔧 Technical Specifications

### **Language & Framework**
- **Language**: Zig (latest stable version)
- **HTTP Server**: Use `std.http.Server` from Zig standard library
- **No external dependencies** for core functionality (prefer stdlib)
- **Memory Management**: Use Arena allocators for request-scoped memory

### **API Endpoints**
1. **POST /generate-query** - Main query generation endpoint
2. **GET /health** - Health check endpoint  
3. **GET /fields** - List available field mappings

### **Request/Response Format**

**POST /generate-query**
```json
{
  "description": "get all active users with email addresses from last 30 days",
  "system": "system_a",
  "limit": 100
}
```

**Response**
```json
{
  "query": "SELECT uid, email_addr, create_date\nFROM users\nWHERE status = 'active' AND create_date >= CURRENT_DATE - INTERVAL '30 days'\nLIMIT 100;",
  "matched_fields": [
    {
      "column_name": "uid",
      "table_name": "users", 
      "field_description": "Unique identifier for user",
      "field_type": "INTEGER",
      "match_score": 85.5,
      "matched_text": "user identifier"
    }
  ],
  "confidence": 0.855
}
```

## 🏗 Architecture Requirements

### **Project Structure**
```
query-generator-api/
├── build.zig
├── src/
│   ├── main.zig              # Entry point, server setup
│   ├── types.zig             # Data structures and types
│   ├── field_mapper.zig      # CSV loading and field matching
│   ├── query_generator.zig   # SQL query generation logic
│   ├── http_server.zig       # HTTP request handling
│   ├── csv_parser.zig        # CSV file parsing
│   ├── nlp_engine.zig        # Natural language processing
│   └── config.zig            # Configuration constants
├── field_mappings.csv        # Sample field mapping data
└── README.md
```

### **Core Modules to Implement**

#### **1. CSV Parser (`csv_parser.zig`)**
- Parse CSV file with field mappings
- Handle quoted fields and escaped characters
- Convert CSV rows to FieldMapping structs
- Error handling for malformed CSV

#### **2. Field Mapper (`field_mapper.zig`)**
- Load field mappings from CSV on startup
- Implement fuzzy string matching for field descriptions
- Extract keywords from natural language input
- Score and rank field matches
- Support system-specific field name resolution

#### **3. NLP Engine (`nlp_engine.zig`)**
- Extract keywords from user descriptions
- Detect query intent (SELECT, COUNT, GROUP BY)
- Identify temporal patterns ("last 30 days", "recent")
- Recognize filter patterns ("active", "status")
- Simple tokenization and stop word filtering

#### **4. Query Generator (`query_generator.zig`)**
- Generate SELECT queries for general data retrieval
- Generate COUNT queries for "how many" questions
- Generate GROUP BY queries for aggregation
- Add WHERE clauses based on detected patterns
- Handle LIMIT clauses and basic JOINs

#### **5. HTTP Server (`http_server.zig`)**
- Handle HTTP requests using `std.http.Server`
- Parse JSON request bodies
- Route requests to appropriate handlers
- Generate JSON responses
- Add CORS headers for web client support

## 🎯 Implementation Priorities

### **Phase 1: Foundation (Start Here)**
1. Set up basic Zig project with `build.zig`
2. Implement CSV parser with basic field mapping support
3. Create HTTP server with health check endpoint
4. Define core data structures in `types.zig`

### **Phase 2: Core Logic**
1. Implement field matching with simple string contains logic
2. Add basic query generation for SELECT statements
3. Create `/generate-query` endpoint with hardcoded examples
4. Add keyword extraction and scoring

### **Phase 3: Intelligence**
1. Implement fuzzy string matching algorithm
2. Add intent detection for different query types
3. Enhance query generation with WHERE clauses
4. Add confidence scoring system

### **Phase 4: Polish**
1. Add comprehensive error handling
2. Implement `/fields` listing endpoint
3. Add proper JSON parsing and serialization
4. Performance optimization and memory management

## 🧠 Algorithm Guidelines

### **Fuzzy Matching Algorithm**
- Use Levenshtein distance or similar string similarity metric
- Score matches between 0-100 (higher = better match)
- Consider both field descriptions and column names
- Apply keyword-based scoring for partial matches

### **Intent Detection Patterns**
- **COUNT**: "how many", "count", "total number"
- **GROUP BY**: "by category", "group by", "breakdown"
- **SELECT**: Default for general queries
- **FILTER**: "active", "recent", "last X days"

### **Query Generation Logic**
```
1. Analyze description for intent and keywords
2. Find relevant fields using fuzzy matching
3. Determine primary table from highest-scoring field
4. Generate appropriate SQL based on intent
5. Add WHERE clauses for detected filters
6. Apply LIMIT if specified
```

## 📊 Performance Requirements

- **Startup Time**: < 100ms (CSV loading)
- **Query Generation**: < 50ms per request
- **Memory Usage**: < 50MB for typical field mapping files
- **Concurrency**: Handle 100+ concurrent requests

## 🧪 Testing Requirements

Create tests for:
- CSV parsing with various input formats
- Field matching accuracy with different descriptions
- Query generation for each supported type
- HTTP endpoint functionality
- Error handling scenarios

## 🔍 Example Use Cases to Support

1. **Simple Selection**: "get user emails" → `SELECT email FROM users;`
2. **Filtered Data**: "active users from last week" → `SELECT * FROM users WHERE status = 'active' AND created_at >= CURRENT_DATE - INTERVAL '7 days';`
3. **Counting**: "how many orders were placed" → `SELECT COUNT(*) FROM orders;`
4. **Grouping**: "orders by status" → `SELECT order_status, COUNT(*) FROM orders GROUP BY order_status;`
5. **Multi-system**: Use system_a field mappings when system="system_a"

## 🚀 Getting Started

1. **Initialize Project**: `zig init-exe` 
2. **Create build.zig** with basic executable configuration
3. **Start with main.zig** and basic HTTP server
4. **Implement CSV parsing first** to establish data foundation
5. **Add field matching logic** before query generation
6. **Test each component** incrementally

## 💡 Implementation Notes

- **Use Arena allocators** for request-scoped memory management
- **Prefer standard library** over external dependencies when possible
- **Keep CSV file path configurable** via command line or environment
- **Add comprehensive logging** for debugging field matches and queries
- **Make fuzzy matching threshold configurable** (default: 30.0)
- **Consider caching** parsed CSV data for performance

## 🎯 Success Criteria

The implementation is successful when:
- ✅ Loads CSV field mappings on startup
- ✅ Responds to HTTP requests on all defined endpoints  
- ✅ Generates valid PostgreSQL queries from natural language
- ✅ Returns structured JSON with confidence scores
- ✅ Handles errors gracefully with appropriate HTTP status codes
- ✅ Supports multiple field mapping systems
- ✅ Processes requests in under 50ms

**Start with the foundation and build incrementally. Focus on getting basic functionality working before adding advanced features like fuzzy matching and complex query generation.**
