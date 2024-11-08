const std = @import("std");
const SearchState = @import("search_state.zig").SearchState;
const Ed25519 = @import("ed25519.zig").Ed25519;
const Base58 = @import("base58.zig").Base58;

pub const Metal = struct {
    allocator: std.mem.Allocator,
    attempts: std.atomic.Value(u64),
    start_time: i64,
    should_stop: std.atomic.Value(bool),
    threads: []std.Thread,

    const NUM_THREADS = 32;
    const BATCH_SIZE = 8192;

    pub fn init(allocator: std.mem.Allocator) !Metal {
        return Metal{
            .allocator = allocator,
            .attempts = std.atomic.Value(u64).init(0),
            .start_time = std.time.milliTimestamp(),
            .should_stop = std.atomic.Value(bool).init(false),
            .threads = try allocator.alloc(std.Thread, NUM_THREADS),
        };
    }

    pub fn deinit(self: *Metal) void {
        self.allocator.free(self.threads);
    }

    pub fn createComputePipeline(self: *Metal, _: []const u8) !void {
        _ = self;
        std.debug.print("Warning: Metal tools not available, falling back to CPU implementation\n", .{});
    }

    fn workerThread(self: *Metal, state: *SearchState) void {
        var thread_prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        var local_attempts: u64 = 0;

        // Pre-allocate buffers
        var public_b58: [64]u8 = undefined;
        var priv_b58: [128]u8 = undefined;

        while (!self.should_stop.load(.monotonic)) {
            // Generate and check multiple keypairs
            var i: usize = 0;
            while (i < BATCH_SIZE) : (i += 1) {
                // Generate random seed
                var seed: [32]u8 = undefined;
                for (0..32) |j| {
                    seed[j] = thread_prng.random().int(u8);
                }

                // Generate keypair
                const keypair = Ed25519.generateKeypair(&seed);

                // Convert just enough bytes for the pattern length
                const prefix_len = @min(4, keypair.public.len);
                const pub_len = Base58.encode(&public_b58, keypair.public[0..prefix_len]) catch continue;
                const pub_prefix = public_b58[0..pub_len];

                // Check if prefix matches the pattern
                if (state.pattern.matches(pub_prefix)) {
                    // Full match! Convert the entire key
                    const full_pub_len = Base58.encode(&public_b58, &keypair.public) catch continue;
                    const pub_str = public_b58[0..full_pub_len];

                    // Double check the full key matches
                    if (state.pattern.matches(pub_str)) {
                        const pub_key = self.allocator.dupe(u8, pub_str) catch continue;
                        const priv_len = Base58.encode(&priv_b58, &keypair.private) catch {
                            self.allocator.free(pub_key);
                            continue;
                        };
                        const priv_key = self.allocator.dupe(u8, priv_b58[0..priv_len]) catch {
                            self.allocator.free(pub_key);
                            continue;
                        };

                        state.keypair = .{
                            .public = pub_key,
                            .private = priv_key,
                        };
                        state.found = true;
                        self.should_stop.store(true, .monotonic);
                        return;
                    }
                }
            }

            local_attempts += BATCH_SIZE;
            if (local_attempts >= 1000000) {
                _ = self.attempts.fetchAdd(local_attempts, .monotonic);
                local_attempts = 0;

                // Log progress every ~10M attempts across all threads
                const total = self.attempts.load(.monotonic);
                if (total % 10000000 == 0) {
                    const elapsed_ms = std.time.milliTimestamp() - self.start_time;
                    const elapsed_secs = @as(f64, @floatFromInt(elapsed_ms)) / 1000.0;
                    const rate = if (elapsed_secs > 0)
                        @as(f64, @floatFromInt(total)) / elapsed_secs
                    else
                        0;

                    std.debug.print("Searched {} keypairs in {d:.1}s. Rate: {d:.0} keys/s\n", .{
                        total,
                        elapsed_secs,
                        rate,
                    });
                }
            }
        }
    }

    pub fn dispatchCompute(self: *Metal, state: ?*SearchState, workgroup_size: u32) !void {
        if (state == null) return;
        _ = workgroup_size;

        // Reset atomic counters
        self.attempts.store(0, .monotonic);
        self.should_stop.store(false, .monotonic);
        self.start_time = std.time.milliTimestamp();

        // Spawn worker threads
        for (0..NUM_THREADS) |i| {
            self.threads[i] = try std.Thread.spawn(.{}, workerThread, .{ self, state.? });
        }

        // Wait for all threads
        for (self.threads) |thread| {
            thread.join();
        }
    }
};
