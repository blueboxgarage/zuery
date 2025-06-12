# Zuery Documentation

Welcome to the Zuery documentation. Zuery is a natural language to SQL query generator implemented in Zig.

## Table of Contents

- [Architecture Overview](architecture.md)
- [Usage Guide](usage.md)
- [Testing Documentation](testing.md)

## Quick Links

- [GitHub Repository](https://github.com/yourusername/zuery)
- [README](../README.md)
- [System Design Diagram](../zig_system_design.mermaid)

## Introduction

Zuery converts natural language descriptions into PostgreSQL queries using a CSV-based field mapping system. It supports different query types (SELECT, COUNT, GROUP BY), handles temporal filters, and works with multiple field mapping systems.

### Core Features

- **CSV-based Field Mapping**: Load and parse database field definitions from CSV
- **Natural Language Processing**: Extract intent, fields, and filters from text
- **Multi-system Support**: Map fields differently based on the target system
- **Query Generation**: Create PostgreSQL queries with appropriate clauses
- **Memory Safety**: Proper memory management with arena allocators

## Getting Started

See the [Usage Guide](usage.md) for details on how to build and use Zuery.

## Architecture

See the [Architecture Overview](architecture.md) for details on how Zuery is designed.

## Testing

See the [Testing Documentation](testing.md) for details on how Zuery is tested.

## Project Structure

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
├── docs/                  # Documentation
│   ├── index.md           # This file
│   ├── architecture.md    # Architecture overview
│   ├── usage.md           # Usage guide
│   └── testing.md         # Testing documentation
└── README.md              # Project overview
```