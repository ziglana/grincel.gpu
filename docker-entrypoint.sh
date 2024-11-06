#!/bin/bash
set -e

# Validate VANITY_PATTERN environment variable
if [ -z "$VANITY_PATTERN" ]; then
    echo "Error: VANITY_PATTERN environment variable is required"
    echo "Usage: docker run -e VANITY_PATTERN=<pattern> [-e IGNORE_CASE=true] grincel"
    exit 1
fi

# Run grincel
exec ./grincel