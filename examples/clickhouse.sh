#!/bin/bash

# Example of using ClickHouse storage

export VANITY_PATTERN="cafe"
export STORAGE_TYPE="clickhouse"
export STORAGE_URL="http://localhost:8123"
export STORAGE_DATABASE="vanity"
export STORAGE_TABLE="keypairs"

# Create table if not exists
clickhouse-client << EOF
CREATE DATABASE IF NOT EXISTS vanity;
CREATE TABLE IF NOT EXISTS vanity.keypairs (
    public_key String,
    private_key String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY created_at;
EOF

./zig-out/bin/vanity-grinder