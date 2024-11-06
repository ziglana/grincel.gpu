#include <metal_stdlib>
using namespace metal;

struct PushConstants {
    uint pattern_length;
    uint fixed_chars[8];
    uint mask[8];
};

kernel void vanityCompute(
    device uint *keys [[buffer(0)]],
    constant PushConstants &constants [[buffer(1)]],
    uint gid [[thread_position_in_grid]]
) {
    // Generate random seed based on global ID and timestamp
    uint seed[8];
    for (uint i = 0; i < 8; i++) {
        seed[i] = gid ^ constants.fixed_chars[i];
    }
    
    // Generate Ed25519 keypair
    uint private_key[32];
    uint public_key[32];
    ed25519_generate_keypair(seed, private_key, public_key);
    
    // Check if public key matches pattern and mask
    bool matches = true;
    for (uint i = 0; i < constants.pattern_length; i++) {
        if (constants.mask[i] == 1 && public_key[i] != constants.fixed_chars[i]) {
            matches = false;
            break;
        }
    }
    
    // Store result if pattern matches
    if (matches) {
        uint offset = gid * 64;
        for (uint i = 0; i < 32; i++) {
            keys[offset + i] = private_key[i];
            keys[offset + 32 + i] = public_key[i];
        }
    }
}