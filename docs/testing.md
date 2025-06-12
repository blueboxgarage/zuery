# Zuery Testing Documentation

This document describes the testing approach used in the Zuery project.

## Testing Philosophy

The Zuery project follows a comprehensive testing approach that includes both unit tests and integration tests. The goal is to ensure that:

1. Individual components work correctly in isolation
2. Components work together properly as a system
3. Memory management is handled correctly
4. Edge cases and error conditions are properly addressed

## Test Suite Structure

All tests are contained in the `src/tests.zig` file. The test suite is organized into:

- Unit tests for individual components
- Integration tests for complete workflow validation
- Error handling tests

## Running Tests

Tests can be run using the Zig build system:

```bash
# Run all tests (includes tests from main.zig)
zig build test

# Run only the dedicated test file (src/tests.zig)
zig build test-only
```

## Test Categories

### NLP Engine Tests

- **Query Type Detection**: Tests the ability to detect SELECT, COUNT, and GROUP BY intents
- **Temporal Pattern Detection**: Tests detection of time-related patterns like "last 30 days"
- **Filter Pattern Detection**: Tests detection of filter conditions like "active" or "completed"

### CSV Parser Tests

- **Basic Parsing**: Tests parsing CSV input into FieldMapping structs
- **Memory Management**: Tests proper allocation and deallocation of resources

### Field Mapper Tests

- **Matching Functionality**: Tests the field matching algorithm with various inputs
- **System-specific Mapping**: Tests mapping with system_a, system_b, and default systems
- **Multiple Matches**: Tests handling of multiple potential field matches

### Query Generator Tests

- **Basic SQL Generation**: Tests generating simple SELECT queries
- **Filter Handling**: Tests adding WHERE clauses based on detected filters
- **Query Type Handling**: Tests generating different types of queries (SELECT, COUNT, GROUP BY)

### Config Tests

- **Default Values**: Tests configuration initialization with default values
- **Overrides**: Tests configuration overrides via environment variables

### Integration Tests

- **Full Query Generation**: Tests the complete workflow from natural language to SQL
- **Multiple Query Types**: Tests generating different types of queries
- **Error Handling**: Tests proper error propagation and handling

## Error Handling Testing

The test suite includes specific tests for error conditions:

- Empty query handling
- Missing field mappings
- Unknown system types
- Malformed input

## Memory Management Testing

All tests use the `testing.allocator` which tracks allocations and detects leaks. Each test uses proper cleanup patterns including:

- Deferring arena cleanup
- Properly freeing allocated resources
- Using defer statements for cleanup

## Adding New Tests

When adding new functionality to Zuery, follow these guidelines for testing:

1. Add unit tests for the new component in isolation
2. Update integration tests if the component affects the overall workflow
3. Test edge cases and error conditions
4. Verify memory management with the testing allocator
5. Run the full test suite to ensure no regressions

## Test Performance

Tests are designed to be fast and have minimal dependencies. The test suite should run in under a second on most systems.