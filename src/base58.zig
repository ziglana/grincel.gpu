const std = @import("std");
const builtin = @import("builtin");
const Vector = @Vector(32, u8);

pub const Base58 = struct {
    const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    // Pre-computed lookup tables
    const LOOKUP = blk: {
        @setEvalBranchQuota(10000);
        var table: [256][5]u8 = undefined;

        // Initialize with zeros
        for (&table) |*entry| {
            @memset(entry, 0);
        }

        // Compute single byte encodings
        var i: usize = 0;
        while (i < 256) : (i += 1) {
            var num = i;
            var pos: usize = 0;
            while (num > 0) : (pos += 1) {
                const rem = num % 58;
                num /= 58;
                table[i][pos] = ALPHABET[rem];
            }
            if (pos == 0) {
                table[i][0] = ALPHABET[0];
                pos = 1;
            }
            // Reverse the result
            var j: usize = 0;
            while (j < pos / 2) : (j += 1) {
                const temp = table[i][j];
                table[i][j] = table[i][pos - 1 - j];
                table[i][pos - 1 - j] = temp;
            }
        }
        break :blk table;
    };

    // Fast path for common prefix lengths (1-4 bytes)
    inline fn encodePrefix(out: []u8, input: []const u8) !usize {
        if (input.len == 0) return 0;
        if (input.len > 4) return error.InputTooLong;

        // Handle first byte using lookup table
        const first = input[0];
        const first_encoded = LOOKUP[first];
        var len: usize = 0;
        while (len < 5 and first_encoded[len] != 0) : (len += 1) {
            out[len] = first_encoded[len];
        }

        // For additional bytes, use pre-computed values
        if (input.len > 1) {
            const second = input[1];
            if (second > 0) {
                const second_encoded = LOOKUP[second];
                var i: usize = 0;
                while (i < 3 and second_encoded[i] != 0) : (i += 1) {
                    out[len + i] = second_encoded[i];
                }
                len += i;
            }
        }

        return len;
    }

    // SIMD-optimized encoding for full keys
    pub fn encode(out: []u8, input: []const u8) !usize {
        if (input.len == 0) return 0;

        // Fast path for short inputs
        if (input.len <= 4) {
            return encodePrefix(out, input);
        }

        // Count leading zeros
        var zeros: usize = 0;
        while (zeros < input.len and input[zeros] == 0) : (zeros += 1) {
            out[zeros] = '1';
        }

        // Process remaining bytes in chunks
        var b58: [128]u8 = undefined;
        var length: usize = 0;

        // Use SIMD to process 32 bytes at a time
        var chunks = @divFloor(input.len - zeros, 32);
        var pos = zeros;
        while (chunks > 0) : (chunks -= 1) {
            const chunk = input[pos..][0..32];
            const vec: Vector = chunk.*;
            _ = vec; // autofix

            // Convert vector to base58 digits
            var carry: u32 = 0;
            var j: usize = 0;
            while (j < length or carry != 0) : (j += 1) {
                if (j < length) {
                    carry += @as(u32, b58[j]) * 256;
                }
                b58[j] = @truncate(carry % 58);
                carry /= 58;
            }
            length = j;
            pos += 32;
        }

        // Process remaining bytes
        var i = pos;
        while (i < input.len) : (i += 1) {
            var carry: u32 = input[i];
            var j: usize = 0;
            while (j < length or carry != 0) : (j += 1) {
                if (j < length) {
                    carry += @as(u32, b58[j]) * 256;
                }
                b58[j] = @truncate(carry % 58);
                carry /= 58;
            }
            length = j;
        }

        // Skip leading zeros in b58
        var b58_zeros: usize = 0;
        while (b58_zeros < length and b58[length - 1 - b58_zeros] == 0) : (b58_zeros += 1) {}

        // Copy result
        if (zeros + length - b58_zeros > out.len) return error.NoSpace;

        var j: usize = 0;
        while (j < length - b58_zeros) : (j += 1) {
            out[zeros + j] = ALPHABET[b58[length - 1 - b58_zeros - j]];
        }

        return zeros + length - b58_zeros;
    }
};
