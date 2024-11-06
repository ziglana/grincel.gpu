# 🚀 Grincel - GPU Vanity Address Generator

A blazing-fast GPU-accelerated Solana vanity address generator written in Zig.

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

## ✨ Features

- 🎮 GPU acceleration using Vulkan/Metal compute shaders
- 🚄 Parallel processing across multiple workgroups
- 🔑 Ed25519 key generation on GPU
- 🎯 Flexible pattern matching with wildcards
- 🔠 Case-sensitive and case-insensitive matching
- 💾 Multiple storage options (HTTP, PostgreSQL, ClickHouse, SQLite)
- 🤖 Telegram bot integration
- 🖥️ Cross-platform support (Linux, macOS)

## 🛠️ Building

```bash
zig build
```

## 📦 Docker

```bash
# Build the image
docker build -t grincel .

# Run with NVIDIA GPU support
docker-compose up
```

## 🎯 Usage

### Basic Usage

```bash
# Fixed pattern
export VANITY_PATTERN="cafe"
./zig-out/bin/grincel

# Pattern with wildcards (? matches any character)
export VANITY_PATTERN="???cafe"  # Matches any address ending with "cafe"
./zig-out/bin/grincel

# Case-insensitive matching
export VANITY_PATTERN="CAFE"
export IGNORE_CASE=true
./zig-out/bin/grincel  # Will match "cafe", "CAFE", "CaFe", etc.
```

### Storage Integration

#### HTTP Webhook
```bash
export STORAGE_TYPE="http"
export STORAGE_URL="https://api.example.com/webhook"
./zig-out/bin/grincel
```

#### PostgreSQL
```bash
export STORAGE_TYPE="postgresql"
export STORAGE_URL="postgresql://user:pass@localhost:5432/vanity"
export STORAGE_TABLE="keypairs"
./zig-out/bin/grincel
```

#### ClickHouse
```bash
export STORAGE_TYPE="clickhouse"
export STORAGE_URL="http://localhost:8123"
export STORAGE_DATABASE="vanity"
export STORAGE_TABLE="keypairs"
./zig-out/bin/grincel
```

#### SQLite
```bash
export STORAGE_TYPE="sqlite"
export STORAGE_DATABASE="keypairs.db"
./zig-out/bin/grincel
```

#### Telegram Bot
```bash
export STORAGE_TYPE="telegram"
export STORAGE_TOKEN="your_bot_token"
export STORAGE_CHAT_ID="your_chat_id"
./zig-out/bin/grincel
```

## 📊 Benchmarking

Run the built-in benchmark:

```bash
./zig-out/bin/grincel --benchmark
```

Sample output:
```
Benchmark Results:
----------------
Pattern: cafe
Attempts per second: 1,234,567
Total attempts: 6,172,835
Duration: 5000 ms
```

## 🎨 Pattern Syntax

- Use regular characters for exact matches
- Use `?` for any character
- Set `IGNORE_CASE=true` for case-insensitive matching

Examples:
- `cafe` - Matches addresses starting with "cafe"
- `???cafe` - Matches addresses with "cafe" at positions 4-7
- `ca?e` - Matches "cafe", "cake", etc.
- `CAFE` with `IGNORE_CASE=true` - Matches any case variation

## 🏗️ Architecture

```mermaid
graph TD
    A[Main] --> B[GPU Manager]
    B --> C[Vulkan Backend]
    B --> D[Metal Backend]
    A --> E[Pattern Matcher]
    A --> F[Storage Manager]
    F --> G[HTTP]
    F --> H[PostgreSQL]
    F --> I[ClickHouse]
    F --> J[SQLite]
    F --> K[Telegram]
```

## 🚀 Performance

This implementation utilizes GPU compute shaders for parallel key generation and pattern matching, achieving significantly higher throughput compared to CPU-based solutions.

Key optimizations:
- Parallel key generation in GPU workgroups
- Efficient pattern matching on GPU
- Zero-copy memory transfers
- Batched storage operations

## 📄 License

This project is released into the public domain. See LICENSE file for details.