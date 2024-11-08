const std = @import("std");
const GpuManager = @import("gpu.zig").GpuManager;

pub const BenchmarkResult = struct {
    attempts_per_second: f64,
    total_attempts: u64,
    duration_ms: u64,
    pattern: []const u8,
};

pub const Benchmark = struct {
    const WARMUP_DURATION_MS = 1000;
    const BENCHMARK_DURATION_MS = 5000;
    const WORKGROUP_SIZE = 256;

    allocator: std.mem.Allocator,
    gpu: *GpuManager,

    pub fn init(allocator: std.mem.Allocator, gpu: *GpuManager) Benchmark {
        return .{
            .allocator = allocator,
            .gpu = gpu,
        };
    }

    pub fn run(self: *Benchmark, pattern: []const u8) !BenchmarkResult {
        // Warm-up phase
        std.debug.print("Warming up for {} ms...\n", .{WARMUP_DURATION_MS});
        const warmup_start = std.time.milliTimestamp();
        while (std.time.milliTimestamp() - warmup_start < WARMUP_DURATION_MS) {
            try self.gpu.dispatchCompute(null, WORKGROUP_SIZE);
        }

        // Actual benchmark
        std.debug.print("Running benchmark for {} ms...\n", .{BENCHMARK_DURATION_MS});
        var total_attempts: u64 = 0;
        const start_time = std.time.milliTimestamp();
        const end_time = start_time + BENCHMARK_DURATION_MS;

        while (std.time.milliTimestamp() < end_time) {
            try self.gpu.dispatchCompute(null, WORKGROUP_SIZE);
            total_attempts += WORKGROUP_SIZE;
        }

        const actual_duration = std.time.milliTimestamp() - start_time;
        const attempts_per_second = @as(f64, @floatFromInt(total_attempts)) / (@as(f64, @floatFromInt(actual_duration)) / 1000.0);

        return BenchmarkResult{
            .attempts_per_second = attempts_per_second,
            .total_attempts = total_attempts,
            .duration_ms = @intCast(actual_duration),
            .pattern = pattern,
        };
    }

    pub fn printResults(result: BenchmarkResult) void {
        std.debug.print("\nBenchmark Results:\n", .{});
        std.debug.print("----------------\n", .{});
        std.debug.print("Pattern: {s}\n", .{result.pattern});
        std.debug.print("Attempts per second: {d:.2}\n", .{result.attempts_per_second});
        std.debug.print("Total attempts: {}\n", .{result.total_attempts});
        std.debug.print("Duration: {} ms\n", .{result.duration_ms});
    }
};
