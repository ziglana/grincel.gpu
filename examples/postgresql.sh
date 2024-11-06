#!/bin/bash

# Example of using PostgreSQL storage

export VANITY_PATTERN="cafe"
export STORAGE_TYPE="postgresql"
export STORAGE_URL="postgresql://user:pass@localhost:5432/vanity"
export STORAGE_TABLE="keypairs"

# Create table if not exists
psql $STORAGE_URL << EOF
CREATE TABLE IF NOT EXISTS keypairs (
    id SERIAL PRIMARY KEY,
    public_key TEXT NOT NULL,
    private_key TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
EOF

./zig-out/bin/vanity-grinder