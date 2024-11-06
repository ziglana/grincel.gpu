FROM debian:bullseye-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    build-essential \
    libvulkan-dev \
    vulkan-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Zig
WORKDIR /tmp
RUN wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz \
    && tar xf zig-linux-x86_64-0.11.0.tar.xz \
    && mv zig-linux-x86_64-0.11.0 /usr/local/zig

# Copy project files
WORKDIR /app
COPY . .

# Build project
RUN /usr/local/zig/zig build -Doptimize=ReleaseFast

# Final stage
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libvulkan1 \
    mesa-vulkan-drivers \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/zig-out/bin/grincel .

# Create entrypoint script
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]