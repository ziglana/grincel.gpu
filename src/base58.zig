const std = @import("std");

pub const Base58 = struct {
    const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    pub fn encode(out: []u8, input: []const u8) !usize {
        if (input.len == 0) return 0;

        // Count leading zeros
        var zeros: usize = 0;
        while (zeros < input.len and input[zeros] == 0) : (zeros += 1) {}

        // Convert to base58
        var b58: [128]u8 = undefined;
        var length: usize = 0;

        // Process input bytes
        for (input) |byte| {
            var carry: u32 = byte;
            var i: usize = 0;

            // Apply "b58 = b58 * 256 + ch".
            while (i < length or carry != 0) : (i += 1) {
                if (i < length) {
                    carry += @as(u32, b58[i]) * 256;
                }
                b58[i] = @truncate(carry % 58);
                carry /= 58;
            }
            length = i;
        }

        // Skip leading zeros in b58
        var b58_zeros: usize = 0;
        while (b58_zeros < length and b58[length - 1 - b58_zeros] == 0) : (b58_zeros += 1) {}

        // Copy result
        if (zeros + length - b58_zeros > out.len) return error.NoSpace;

        var i: usize = 0;
        while (i < zeros) : (i += 1) {
            out[i] = '1';
        }

        var j: usize = 0;
        while (j < length - b58_zeros) : (j += 1) {
            out[zeros + j] = ALPHABET[b58[length - 1 - b58_zeros - j]];
        }

        return zeros + length - b58_zeros;
    }
};
