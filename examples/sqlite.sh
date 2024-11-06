#!/bin/bash

# Example of using SQLite storage

export VANITY_PATTERN="cafe"
export STORAGE_TYPE="sqlite"
export STORAGE_DATABASE="keypairs.db"

# Create table if not exists
sqlite3 keypairs.db << EOF
CREATE TABLE IF NOT EXISTS keypairs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    public_key TEXT NOT NULL,
    private_key TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

./zig-out/bin/vanity-grinder