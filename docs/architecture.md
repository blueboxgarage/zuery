# Zuery Architecture Documentation

This document provides an overview of the Zuery system architecture.

## System Overview

Zuery is a natural language to SQL query generator implemented in Zig. The system converts English language descriptions into PostgreSQL queries by:

1. Parsing a CSV file of field mappings
2. Processing natural language input to detect intent and extract relevant fields
3. Matching detected fields to database columns
4. Generating appropriate SQL queries with filters

## Core Components

### 1. CSV Parser (`csv_parser.zig`)

The CSV parser reads and parses field mapping definitions from a CSV file, creating structured data that can be used by the field mapper.

**Key responsibilities:**
- Parse CSV files according to the expected format
- Handle error conditions like malformed CSV
- Create FieldMapping structs for each CSV row
- Manage memory for field mappings

**Implementation details:**
- Line-by-line parsing using Zig's standard library
- Error handling for different CSV parsing scenarios
- Proper memory management with allocator-based design

### 2. Field Mapper (`field_mapper.zig`)

The field mapper matches natural language text to database fields using the field mappings loaded from CSV.

**Key responsibilities:**
- Load and manage field mappings
- Match natural language input to database fields
- Support system-specific field mapping (system_a, system_b)
- Score and rank potential field matches

**Implementation details:**
- Keyword-based matching algorithm
- System-specific field name resolution
- Score-based ranking system for matches
- Arena allocator usage for efficient memory management

### 3. NLP Engine (`nlp_engine.zig`)

The NLP engine analyzes natural language input to detect query intent, temporal patterns, and filter conditions.

**Key responsibilities:**
- Detect query type (SELECT, COUNT, GROUP BY)
- Identify temporal patterns like "last 30 days"
- Recognize filter patterns like "active" or "completed"
- Extract relevant information from text

**Implementation details:**
- Pattern matching for intent detection
- Regular expression-like pattern matching for time references
- Status/filter keyword detection
- Text normalization (lowercase conversion)

### 4. Query Generator (`query_generator.zig`)

The query generator builds SQL queries based on the detected intent, matched fields, and identified patterns.

**Key responsibilities:**
- Generate SQL queries based on intent and fields
- Build WHERE clauses from detected filters
- Handle temporal conditions in queries
- Calculate confidence scores for generated queries

**Implementation details:**
- Template-based SQL generation
- Different generation strategies per query type
- Clause building for WHERE, GROUP BY, etc.
- Confidence scoring based on field match quality

### 5. HTTP Server (`http_server.zig`)

The HTTP server handles incoming requests, processes them through the pipeline, and returns query results.

**Key responsibilities:**
- Handle incoming HTTP requests
- Process natural language descriptions
- Coordinate the query generation pipeline
- Return structured responses with generated SQL

**Implementation details:**
- Simplified demonstration server
- Sample query processing
- Arena allocator usage for request-scoped memory
- Error handling for request processing

### 6. Config (`config.zig`)

The config module manages application configuration, including defaults and environment variable overrides.

**Key responsibilities:**
- Provide default configuration values
- Support environment variable overrides
- Manage configuration resources properly

**Implementation details:**
- Environment variable reading and parsing
- Type conversion for configuration values
- Proper cleanup in destructors

## Data Flow

1. **Initialization**:
   - Load CSV field mappings using the CSV parser
   - Initialize components with configuration

2. **Request Processing**:
   - Receive natural language description
   - Extract intent and keywords using NLP engine
   - Find matching fields using field mapper
   - Generate SQL query using query generator
   - Return query and metadata

## Memory Management

Zuery uses a combination of memory management techniques:

- **Arena Allocators**: Used for request-scoped memory to efficiently handle allocations that have the same lifetime
- **Explicit Allocator Passing**: All components take an allocator parameter for clear ownership
- **Proper Resource Cleanup**: Destructors and cleanup functions free allocated resources
- **Testing Allocator**: Used in tests to detect leaks and misuse

## Error Handling

The system employs comprehensive error handling:

- **Error Unions**: Functions return error unions to propagate errors
- **Specific Error Types**: Custom error types for different components
- **Graceful Degradation**: Fall back to simpler options when advanced processing fails
- **Error Propagation**: Errors are propagated up the call stack for appropriate handling

## Testing Strategy

See the [testing documentation](testing.md) for details on the testing approach.

## Future Enhancements

Planned architectural improvements include:

- Replacing the simplified HTTP server with a full implementation
- Adding more sophisticated NLP algorithms
- Implementing caching for performance optimization
- Supporting more complex query types (JOINs, subqueries, etc.)
- Adding a plugin system for extensibility