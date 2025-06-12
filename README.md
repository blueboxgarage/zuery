# Zuery - PostgreSQL Query Generator in Zig

A high-performance natural language to SQL query generator implemented in Zig. This service allows non-technical users to query databases using plain English by converting natural language descriptions into PostgreSQL queries.

## 🎯 Project Overview

Zuery converts natural language descriptions into PostgreSQL queries using a CSV-based field mapping system. It supports different query types (SELECT, COUNT, GROUP BY), handles temporal filters, and works with multiple field mapping systems.

## 📋 Core Features

- **CSV-based Field Mapping**: Load and parse database field definitions from CSV
- **Natural Language Processing**: Extract intent, fields, and filters from text
- **Multi-system Support**: Map fields differently based on the target system (system_a, system_b, default)
- **Query Generation**: Create PostgreSQL queries with appropriate clauses
- **Memory Safety**: Proper memory management with arena allocators

## 🚀 Current Implementation

The project currently implements:

- **CSV Parser**: Parses field mapping definitions from CSV files
- **Field Mapper**: Matches natural language input to database fields
- **NLP Engine**: Detects query type, temporal patterns, and filters
- **Query Generator**: Generates SQL based on matched fields and intent
- **HTTP Server**: Simplified server that demonstrates the API functionality
- **Config**: Environment-aware configuration system
- **Tests**: Comprehensive test suite for all components

### **CSV Field Mapping Format**
```csv
column_name,table_name,system_a_fieldmap,system_b_fieldmap,field_description,field_type
user_id,users,uid,user_identifier,Unique identifier for user,INTEGER
email,users,email_addr,user_email,User email address,VARCHAR
created_at,users,create_date,registration_date,Account creation timestamp,TIMESTAMP
order_total,orders,amount,total_cost,Total order value in cents,INTEGER
order_status,orders,status,order_state,Current status of order,VARCHAR
```

## 🏗 Project Structure

```
zuery/
├── build.zig              # Build configuration
├── field_mappings.csv     # Sample field mappings
├── src/
│   ├── main.zig           # Entry point, server setup
│   ├── types.zig          # Core data structures
│   ├── field_mapper.zig   # Maps natural language to fields
│   ├── query_generator.zig # SQL generation logic
│   ├── http_server.zig    # HTTP request handling
│   ├── csv_parser.zig     # CSV file parsing
│   ├── nlp_engine.zig     # NLP intent detection
│   ├── config.zig         # Configuration handling
│   └── tests.zig          # Test suite
├── zig_system_design.mermaid # System design diagram
└── README.md              # Project documentation
```

## 📘 Module Descriptions

### **CSV Parser (`csv_parser.zig`)**
- Parses CSV field mapping files
- Converts rows to FieldMapping structs
- Includes proper memory management and cleanup
- Handles basic error conditions

### **Field Mapper (`field_mapper.zig`)**
- Loads and manages field mappings
- Implements keyword-based matching algorithm
- Scores and ranks potential field matches
- Supports system-specific field mapping (system_a, system_b)
- Uses arena allocators for efficient memory use

### **NLP Engine (`nlp_engine.zig`)**
- Detects query intent (SELECT, COUNT, GROUP BY)
- Identifies temporal patterns ("last 30 days", "yesterday")
- Recognizes filter patterns ("active", "completed")
- Implements simple pattern matching

### **Query Generator (`query_generator.zig`)**
- Generates SQL queries based on detected intent
- Builds WHERE clauses from detected filters
- Handles temporal filters in queries
- Supports different query types
- Calculates confidence scores

### **HTTP Server (`http_server.zig`)**
- Simplified demonstration server
- Processes sample queries to show functionality
- Includes proper error handling
- Uses arena allocators for request-scoped memory

### **Config (`config.zig`)**
- Manages application configuration
- Supports environment variable overrides
- Includes proper resource management

## 🧪 Testing

The project includes a comprehensive test suite in `src/tests.zig` that verifies:

- NLP engine query type detection
- Temporal pattern detection
- Filter pattern detection
- CSV parser functionality
- Query generator SQL generation
- Field mapper matching functionality
- Configuration handling
- Integration tests for the full query generation process
- HTTP server error handling

Run tests with:
```
zig build test         # Run all tests
zig build test-only    # Run only the dedicated test file
```

## 🔍 Example Use Cases

1. **Simple Selection**: "get user emails"
   ```sql
   SELECT email FROM users;
   ```

2. **Filtered Data**: "active users registered yesterday"
   ```sql
   SELECT * FROM users 
   WHERE status = 'active' AND created_at >= CURRENT_DATE - INTERVAL '1 day';
   ```

3. **Counting**: "how many users are there"
   ```sql
   SELECT COUNT(*) FROM users;
   ```

4. **Grouping**: "count products by category"
   ```sql
   SELECT category, COUNT(*) FROM products GROUP BY category;
   ```

5. **System-specific**: "find the uid of a user" (when system_a is specified)
   ```sql
   SELECT uid FROM users;
   ```

## 🚀 Building and Running

```bash
# Clone the repository
git clone https://github.com/yourusername/zuery.git
cd zuery

# Build the project
zig build

# Run the executable
./zig-out/bin/zuery

# Run tests
zig build test
```

## 💡 Implementation Details

- **Memory Management**: Uses arena allocators for request-scoped memory
- **Field Matching**: Implements a keyword-based scoring system
- **Intent Detection**: Pattern matching to determine query type
- **Error Handling**: Comprehensive error detection and handling
- **Testing**: Extensive test suite for all components

## 🔮 Future Improvements

- Replace simplified HTTP server with full implementation
- Enhance NLP capabilities with more sophisticated algorithms
- Add more complex query types (JOIN, HAVING, etc.)
- Implement full JSON parsing for request/response
- Add more extensive logging and debugging tools
- Implement caching for frequently used queries

---

Created with Zig 0.14.1
