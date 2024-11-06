const std = @import("std");

pub const Ed25519 = struct {
    pub const KeyPair = struct {
        public: [32]u8,
        private: [64]u8,
    };

    pub fn generateKeypair(seed: []const u8) KeyPair {
        var public_key: [32]u8 = undefined;
        var private_key: [64]u8 = undefined;
        
        // Ed25519 key generation
        ed25519_create_keypair(&public_key, &private_key, seed);
        
        return KeyPair{
            .public = public_key,
            .private = private_key,
        };
    }

    extern fn ed25519_create_keypair(
        public_key: *[32]u8,
        private_key: *[64]u8,
        seed: [*]const u8,
    ) void;
};