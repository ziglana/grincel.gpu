const std = @import("std");
const crypto = std.crypto;

pub const Ed25519 = struct {
    pub const KeyPair = struct {
        public: [32]u8,
        private: [64]u8,
    };

    pub fn generateKeypair(seed: []const u8) KeyPair {
        var private_key: [64]u8 = undefined;
        var public_key: [32]u8 = undefined;

        // Hash the seed to get the private key
        var hasher = crypto.hash.sha2.Sha512.init(.{});
        hasher.update(seed);
        var hash: [64]u8 = undefined;
        hasher.final(&hash);

        // Clear the lowest three bits and highest bit
        hash[0] &= 0xf8;
        hash[31] &= 0x7f;
        hash[31] |= 0x40;

        // Generate key pair using Zig's crypto library
        const key_pair = crypto.sign.Ed25519.KeyPair.create(hash[0..32].*) catch unreachable;
        const pub_bytes = key_pair.public_key.toBytes();

        // Copy the keys
        @memcpy(&public_key, &pub_bytes);
        @memcpy(private_key[0..32], hash[0..32]);
        @memcpy(private_key[32..], &pub_bytes);

        return KeyPair{
            .public = public_key,
            .private = private_key,
        };
    }

    // Batch key generation for multiple seeds
    pub fn generateKeypairBatch(seeds: []const u8, count: usize) ?[]KeyPair {
        var pairs = std.heap.page_allocator.alloc(KeyPair, count) catch return null;

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const seed_offset = i * 32;
            const seed = seeds[seed_offset..][0..32];
            pairs[i] = generateKeypair(seed);
        }

        return pairs;
    }
};
