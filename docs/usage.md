# Zuery Usage Guide

This document provides guidance on how to use the Zuery natural language to SQL query generator.

## Getting Started

### Building Zuery

```bash
# Clone the repository
git clone https://github.com/yourusername/zuery.git
cd zuery

# Build the project
zig build

# Run the executable
./zig-out/bin/zuery
```

### Using Zuery

Currently, Zuery implements a simplified HTTP server that demonstrates the API functionality by processing sample queries. In the future, a full HTTP server implementation will allow for interactive use.

## Field Mapping Configuration

Zuery uses a CSV file to define the mapping between natural language descriptions and database fields. By default, it looks for a file named `field_mappings.csv` in the current directory.

### CSV Format

The CSV file should have the following format:

```csv
column_name,table_name,system_a_fieldmap,system_b_fieldmap,field_description,field_type
user_id,users,uid,user_identifier,Unique identifier for user,INTEGER
email,users,email_addr,user_email,User email address,VARCHAR
created_at,users,create_date,registration_date,Account creation timestamp,TIMESTAMP
```

### Fields Explanation

- **column_name**: The actual column name in the database
- **table_name**: The database table containing this column
- **system_a_fieldmap**: Alternate name for the field in system A
- **system_b_fieldmap**: Alternate name for the field in system B
- **field_description**: Human-readable description of the field
- **field_type**: SQL data type of the field

## Natural Language Queries

Zuery supports converting various natural language descriptions into SQL queries. Here are some examples of supported query formats:

### Simple Selection Queries

Natural Language:
```
get all users
```

Generated SQL:
```sql
SELECT *
FROM users;
```

### Filtered Queries

Natural Language:
```
find active users from last 30 days
```

Generated SQL:
```sql
SELECT *
FROM users
WHERE status = 'active' AND created_at >= CURRENT_DATE - INTERVAL '30 days';
```

### Count Queries

Natural Language:
```
how many orders are there
```

Generated SQL:
```sql
SELECT COUNT(*)
FROM orders;
```

### Group By Queries

Natural Language:
```
show orders by status
```

Generated SQL:
```sql
SELECT status, COUNT(*)
FROM orders
GROUP BY status;
```

## System-Specific Field Mapping

Zuery supports different field naming conventions through system-specific mappings:

### Default System

Uses the standard column names from the database.

### System A

Uses the field names defined in the `system_a_fieldmap` column.

Example:
```
find user uid
```

Will match to `user_id` in the database when using System A.

### System B

Uses the field names defined in the `system_b_fieldmap` column.

Example:
```
find user_identifier
```

Will match to `user_id` in the database when using System B.

## Configuration Options

Zuery supports the following configuration options, which can be set via environment variables:

- **PORT**: The HTTP server port (default: 8080)
- **FIELD_MAPPINGS_PATH**: Path to the CSV field mappings file (default: "field_mappings.csv")
- **FUZZY_MATCHING_THRESHOLD**: Minimum score for field matches (default: 30.0)

Example:
```bash
PORT=9090 FIELD_MAPPINGS_PATH="/path/to/mappings.csv" ./zig-out/bin/zuery
```

## Query Processing Pipeline

When Zuery processes a query, it follows these steps:

1. **Intent Detection**: Determines if the query is a SELECT, COUNT, or GROUP BY
2. **Temporal Pattern Detection**: Identifies time-related filters
3. **Filter Pattern Detection**: Identifies other filters (status, etc.)
4. **Field Matching**: Matches keywords to database fields
5. **SQL Generation**: Creates the appropriate SQL based on intent and fields
6. **Response Creation**: Returns the generated SQL and metadata

## Advanced Features

### Confidence Scoring

Each generated query includes a confidence score based on:
- Quality of field matches
- Number of matched fields
- Clarity of detected intent

### Matching Score

Each matched field includes a score indicating how well it matched the natural language input. Higher scores (closer to 100) indicate better matches.

## Troubleshooting

### Common Issues

- **No Fields Matched**: Try using keywords that match column names or field descriptions
- **Low Confidence Score**: Add more specific field names to your query
- **Wrong Query Type**: Use clearer intent indicators (e.g., "how many" for COUNT)

### Debugging

Run with verbose output to see the matching process:
```bash
VERBOSE=true ./zig-out/bin/zuery
```

## Example Output

Here's an example of the output from Zuery:

```
Query: "get all active users with email addresses from last 30 days"
SQL: SELECT email FROM users WHERE status = 'active' AND created_at >= CURRENT_DATE - INTERVAL '30 days';
Confidence: 0.85
Matched Fields: 2
  1. users.email (score: 90.0)
  2. users.status (score: 70.0)
```