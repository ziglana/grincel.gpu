#include <metal_stdlib>
using namespace metal;

// Ed25519 constants and tables
constant uint8_t ED25519_D[] = {
    0xa3, 0x78, 0x59, 0x13, 0xca, 0x4d, 0xeb, 0x75, 
    0xab, 0xd8, 0x41, 0x41, 0x4d, 0x0a, 0x70, 0x00,
    0x98, 0xe8, 0x79, 0x77, 0x79, 0x40, 0xc7, 0x8c, 
    0x73, 0xfe, 0x6f, 0x2b, 0xee, 0x6c, 0x03, 0x52
};

constant uint8_t ED25519_Q[] = {
    0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xed
};

// Fast modular arithmetic for Ed25519
uint32_t reduce32(uint32_t x) {
    uint32_t t = x + 0x7fffffff;
    return t - (t >> 31) * 0x7fffffff;
}

void reduce256_modm(uint32_t *r) {
    uint32_t t;
    for (int i = 7; i >= 0; --i) {
        t = r[i] + 0x7fffffff;
        r[i] = t - (t >> 31) * 0x7fffffff;
    }
}

void ed25519_hash(const uint8_t *in, uint8_t *out) {
    // Simple hash for testing - replace with proper SHA-512
    uint32_t state[8] = {0};
    for (int i = 0; i < 32; i += 4) {
        state[i/4] ^= (uint32_t(in[i]) << 24) | (uint32_t(in[i+1]) << 16) |
                      (uint32_t(in[i+2]) << 8) | uint32_t(in[i+3]);
    }
    reduce256_modm(state);
    for (int i = 0; i < 32; i += 4) {
        out[i] = uint8_t(state[i/4] >> 24);
        out[i+1] = uint8_t(state[i/4] >> 16);
        out[i+2] = uint8_t(state[i/4] >> 8);
        out[i+3] = uint8_t(state[i/4]);
    }
}

void ed25519_scalar_mult(uint8_t *point, const uint8_t *scalar) {
    uint32_t r[8] = {0};
    for (int i = 0; i < 32; i++) {
        r[i/4] |= uint32_t(scalar[i]) << ((i % 4) * 8);
    }
    reduce256_modm(r);
    
    // Simplified point multiplication for testing
    for (int i = 0; i < 32; i++) {
        point[i] = uint8_t((r[i/4] >> ((i % 4) * 8)) & 0xff);
    }
}

void ed25519_generate_keypair(const uint8_t *seed, uint8_t *private_key, uint8_t *public_key) {
    // Hash the seed to get the private key
    ed25519_hash(seed, private_key);
    
    // Clear the lowest three bits and highest bit
    private_key[0] &= 0xf8;
    private_key[31] &= 0x7f;
    private_key[31] |= 0x40;
    
    // Generate public key through scalar multiplication
    ed25519_scalar_mult(public_key, private_key);
}

// Base58 alphabet for quick prefix check
constant uint8_t BASE58_MAP[256] = {
    0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
    0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
    0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
    0xff,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0xff,0xff,0xff,0xff,0xff,0xff,
    0xff,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0xff,0x11,0x12,0x13,0x14,0x15,0xff,
    0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f,0x20,0xff,0xff,0xff,0xff,0xff,
    0xff,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0xff,0x2c,0x2d,0x2e,
    0x2f,0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0xff,0xff,0xff,0xff,0xff
};

bool check_base58_prefix(const uint8_t *data, uint8_t target) {
    uint8_t first = data[0];
    uint8_t mapped = BASE58_MAP[target];
    if (mapped == 0xff) return false;
    
    // Quick range check based on first byte
    if (target >= '1' && target <= '9') {
        return first > 0 && first < 58;
    } else if (target >= 'A' && target <= 'H') {
        return first >= 58 && first < 128;
    } else if (target >= 'J' && target <= 'N') {
        return first >= 128 && first < 178;
    } else if (target >= 'P' && target <= 'Z') {
        return first >= 178 && first < 230;
    } else if ((target >= 'a' && target <= 'k') || (target >= 'm' && target <= 'z')) {
        return first >= 230;
    }
    return false;
}

kernel void vanityCompute(
    device uint8_t *keys [[buffer(0)]],
    constant uint8_t *pattern [[buffer(1)]],
    uint gid [[thread_position_in_grid]]
) {
    // Generate deterministic but unique seed
    uint8_t seed[32];
    thread uint32_t rng = gid;
    for (uint i = 0; i < 32; i++) {
        rng = rng * 1664525u + 1013904223u;
        seed[i] = uint8_t(rng);
    }
    
    // Generate Ed25519 keypair
    uint8_t private_key[32];
    uint8_t public_key[32];
    ed25519_generate_keypair(seed, private_key, public_key);
    
    // Quick check if first byte could match pattern
    if (!check_base58_prefix(public_key, pattern[0])) {
        return;
    }
    
    // Store result for further checking on CPU
    uint offset = gid * 64;
    for (uint i = 0; i < 32; i++) {
        keys[offset + i] = private_key[i];
        keys[offset + 32 + i] = public_key[i];
    }
}
