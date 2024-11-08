const std = @import("std");
const SearchState = @import("search_state.zig").SearchState;
const Ed25519 = @import("ed25519.zig").Ed25519;
const Base58 = @import("base58.zig").Base58;

pub const Metal = struct {
    allocator: std.mem.Allocator,
    prng: std.rand.DefaultPrng,
    attempts: u64,
    start_time: i64,

    pub fn init(allocator: std.mem.Allocator) !Metal {
        const seed = @as(u64, @truncate(@as(u128, @bitCast(std.time.nanoTimestamp()))));
        return Metal{
            .allocator = allocator,
            .prng = std.rand.DefaultPrng.init(seed),
            .attempts = 0,
            .start_time = std.time.milliTimestamp(),
        };
    }

    pub fn deinit(self: *Metal) void {
        _ = self;
    }

    pub fn createComputePipeline(self: *Metal, _: []const u8) !void {
        _ = self;
    }

    pub fn dispatchCompute(self: *Metal, state: ?*SearchState, workgroup_size: u32) !void {
        _ = workgroup_size;

        // Skip if this is just a benchmark warmup
        if (state == null) return;

        // Generate and check multiple keypairs
        var i: usize = 0;
        while (i < 256) : (i += 1) {
            // Generate random seed
            var seed: [32]u8 = undefined;
            for (0..32) |j| {
                seed[j] = self.prng.random().int(u8);
            }

            // Generate keypair
            const keypair = Ed25519.generateKeypair(&seed);

            // Convert public key to base58 for pattern matching
            var public_b58: [64]u8 = undefined;
            const pub_len = try Base58.encode(&public_b58, &keypair.public);
            const pub_str = public_b58[0..pub_len];

            // Check if it matches the pattern
            if (state.?.pattern.matches(pub_str)) {
                // Found a match! Save the keypair
                const pub_key = try self.allocator.dupe(u8, pub_str);
                var priv_b58: [128]u8 = undefined;
                const priv_len = try Base58.encode(&priv_b58, &keypair.private);
                const priv_key = try self.allocator.dupe(u8, priv_b58[0..priv_len]);

                state.?.keypair = .{
                    .public = pub_key,
                    .private = priv_key,
                };
                state.?.found = true;
                return;
            }
        }

        self.attempts += 256;

        // Log progress every 1024 attempts
        if (self.attempts % 1024 == 0) {
            const elapsed_ms = std.time.milliTimestamp() - self.start_time;
            const elapsed_secs = @as(f64, @floatFromInt(elapsed_ms)) / 1000.0;
            const rate = if (elapsed_secs > 0)
                @as(f64, @floatFromInt(self.attempts)) / elapsed_secs
            else
                0;

            std.debug.print("Attempts: {d}, Rate: {d:.2} k/s\n", .{
                self.attempts,
                rate / 1000.0,
            });
        }
    }
};
