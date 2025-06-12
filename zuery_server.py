#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import os
import re

class ZueryHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != '/query':
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error": "Not found"}')
            return

        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode('utf-8'))
        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error": "Invalid JSON"}')
            return

        if 'query' not in data:
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error": "Missing query field"}')
            return

        query = data['query']
        
        # Create a temporary file to contain the query
        with open('/tmp/zuery_query.txt', 'w') as f:
            f.write(query)
        
        # Call the zuery binary - we need to redirect stdin to avoid issues
        # with the query containing special characters
        try:
            result = subprocess.run(
                ['/home/mgarce/zuery/zig-out/bin/zuery'],
                input=query.encode('utf-8'),
                capture_output=True,
                text=True
            )
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": f"Failed to run zuery: {str(e)}"}).encode('utf-8'))
            return
        
        print(f"\n==== Query: {query} ====")
        print(result.stdout)
        
        # Parse the output to extract SQL and confidence
        try:
            lines = result.stdout.strip().split('\n')
            
            # Find the SQL line
            sql_line = None
            for line in lines:
                if line.startswith("SQL:"):
                    sql_line = line[4:].strip()
                    break
            
            # Find the confidence line
            confidence = 0.0
            for line in lines:
                if line.startswith("Confidence:"):
                    confidence = float(line[11:].strip())
                    break
            
            # Extract matched fields
            matched_fields = []
            in_fields_section = False
            
            for line in lines:
                if line.startswith("Matched Fields:"):
                    in_fields_section = True
                    continue
                    
                if in_fields_section and line and not line.startswith("----"):
                    # Parse lines like: "  1. users.email (score: 100.0)"
                    field_match = re.match(r'\s*\d+\.\s+(\w+)\.(\w+)\s+\(score:\s+([\d\.]+)', line)
                    if field_match:
                        table, column, score = field_match.groups()
                        matched_fields.append({
                            "table": table,
                            "column": column,
                            "score": float(score)
                        })
            
            response = {
                "sql": sql_line if sql_line else "No SQL generated",
                "confidence": confidence,
                "matched_fields": matched_fields
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            error_response = {
                "error": f"Failed to parse zuery output: {str(e)}",
                "raw_output": result.stdout
            }
            self.wfile.write(json.dumps(error_response, indent=2).encode('utf-8'))

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

def run(server_class=HTTPServer, handler_class=ZueryHandler, port=8080):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting Zuery HTTP server on port {port}...')
    print(f'Test with: curl -X POST http://localhost:{port}/query -H "Content-Type: application/json" -d \'{{"query": "get all active users"}}\'')
    print('Press Ctrl+C to stop the server')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print('Server stopped')

if __name__ == '__main__':
    run()