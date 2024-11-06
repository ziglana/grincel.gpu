#!/bin/bash

# Example of using HTTP webhook storage

export VANITY_PATTERN="cafe"
export STORAGE_TYPE="http"
export STORAGE_URL="https://api.example.com/webhook"

./zig-out/bin/vanity-grinder