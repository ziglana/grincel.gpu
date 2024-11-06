const std = @import("std");
const GpuManager = @import("gpu.zig").GpuManager;
const Ed25519 = @import("ed25519.zig").Ed25519;
const Benchmark = @import("benchmark.zig").Benchmark;
const Pattern = @import("pattern.zig").Pattern;
const PatternOptions = @import("pattern.zig").PatternOptions;

const MAX_DEVICES = 8;
const WORKGROUP_SIZE = 256;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize GPU backend
    var gpu = try GpuManager.init(allocator);
    defer gpu.deinit();

    // Load appropriate shader based on backend
    const shader_code = switch (gpu.backend) {
        .vulkan => @embedFile("shaders/vanity.spv"),
        .metal => @embedFile("shaders/vanity.metallib"),
    };
    
    const pipeline = try gpu.createComputePipeline(shader_code);
    defer pipeline.deinit();

    // Get pattern and options
    const raw_pattern = try std.process.getEnvVarOwned(allocator, "VANITY_PATTERN");
    defer allocator.free(raw_pattern);

    const ignore_case = blk: {
        const case_env = std.process.getEnvVarOwned(allocator, "IGNORE_CASE") catch "";
        defer allocator.free(case_env);
        break :blk std.mem.eql(u8, case_env, "1") or 
                std.mem.eql(u8, case_env, "true") or 
                std.mem.eql(u8, case_env, "yes");
    };

    var pattern = try Pattern.init(allocator, raw_pattern, .{ .ignore_case = ignore_case });
    defer pattern.deinit();

    std.debug.print("Using GPU backend: {s}\n", .{@tagName(gpu.backend)});
    std.debug.print("Pattern: {s} ({} fixed characters)\n", .{pattern.raw, pattern.fixed_chars.len});
    std.debug.print("Case-sensitive: {}\n", .{!pattern.options.ignore_case});

    // Run benchmark if --benchmark flag is present
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 1 and std.mem.eql(u8, args[1], "--benchmark")) {
        var benchmark = Benchmark.init(allocator, &gpu);
        const result = try benchmark.run(pattern.raw);
        Benchmark.printResults(result);
        return;
    }

    // Normal vanity address search
    std.debug.print("Searching for Solana addresses matching pattern...\n", .{});

    // Initialize compute resources
    var search_state = try SearchState.init(allocator, &pattern);
    defer search_state.deinit();

    // Main search loop
    while (!search_state.found) {
        try gpu.dispatchCompute(search_state, WORKGROUP_SIZE);
        try search_state.checkResults();
    }

    // Print results
    const keypair = search_state.getFoundKeypair();
    std.debug.print("\nFound matching keypair!\n", .{});
    std.debug.print("Public: {s}\n", .{keypair.public});
    std.debug.print("Private: {s}\n", .{keypair.private});
}