const std = @import("std");
const crypto = std.crypto;

pub const Ed25519 = struct {
    pub const KeyPair = struct {
        public: [32]u8,
        private: [64]u8,
    };

    pub fn generateKeypair(seed: []const u8) KeyPair {
        var key_pair: KeyPair = undefined;

        // Create a key pair from the seed
        var kp = crypto.sign.Ed25519.KeyPair.create(seed[0..32].*) catch unreachable;

        // Copy the public key bytes
        const pub_bytes = kp.public_key.toBytes();
        @memcpy(&key_pair.public, &pub_bytes);

        // Copy the secret key bytes
        const secret_bytes = kp.secret_key.toBytes();
        @memcpy(&key_pair.private, &secret_bytes);

        return key_pair;
    }
};
