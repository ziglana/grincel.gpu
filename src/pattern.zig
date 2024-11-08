const std = @import("std");

pub const PatternOptions = struct {
    ignore_case: bool = false,
};

pub const Pattern = struct {
    raw: []const u8,
    mask: []const bool, // true for fixed chars, false for wildcards
    fixed_chars: []const u8,
    options: PatternOptions,
    allocator: std.mem.Allocator,
    byte_prefix: ?[4]u8, // First few bytes that could match the pattern

    pub fn init(allocator: std.mem.Allocator, pattern: []const u8, options: PatternOptions) !Pattern {
        var mask = try allocator.alloc(bool, pattern.len);
        var fixed_chars = try allocator.alloc(u8, pattern.len);
        var fixed_count: usize = 0;

        // Pre-compute byte prefix for common patterns
        var byte_prefix: ?[4]u8 = null;
        if (pattern.len >= 1) {
            const first_char = pattern[0];
            switch (first_char) {
                '1' => {
                    byte_prefix = .{ 0, 0, 0, 0 };
                },
                '2'...'9' => {
                    byte_prefix = .{ @as(u8, first_char - '1' + 1), 0, 0, 0 };
                },
                'A'...'H' => {
                    byte_prefix = .{ @as(u8, first_char - 'A' + 58), 0, 0, 0 };
                },
                'J'...'N' => {
                    byte_prefix = .{ @as(u8, first_char - 'J' + 128), 0, 0, 0 };
                },
                'P'...'Z' => {
                    byte_prefix = .{ @as(u8, first_char - 'P' + 178), 0, 0, 0 };
                },
                'a'...'k' => {
                    byte_prefix = .{ @as(u8, first_char - 'a' + 230), 0, 0, 0 };
                },
                'm'...'z' => {
                    byte_prefix = .{ @as(u8, first_char - 'm' + 240), 0, 0, 0 };
                },
                else => {},
            }
        }

        for (pattern, 0..) |c, i| {
            if (c == '?') {
                mask[i] = false;
            } else {
                mask[i] = true;
                fixed_chars[fixed_count] = if (options.ignore_case)
                    std.ascii.toLower(c)
                else
                    c;
                fixed_count += 1;
            }
        }

        return Pattern{
            .raw = try allocator.dupe(u8, pattern),
            .mask = mask,
            .fixed_chars = fixed_chars[0..fixed_count],
            .options = options,
            .allocator = allocator,
            .byte_prefix = byte_prefix,
        };
    }

    pub fn deinit(self: *Pattern) void {
        self.allocator.free(self.raw);
        self.allocator.free(self.mask);
        self.allocator.free(self.fixed_chars);
    }

    // Fast path: check if bytes could possibly match the pattern
    pub fn couldMatch(self: Pattern, bytes: []const u8) bool {
        if (self.byte_prefix) |prefix| {
            if (bytes.len > 0 and bytes[0] != prefix[0]) {
                return false;
            }
            if (bytes.len > 1 and prefix[1] != 0 and bytes[1] != prefix[1]) {
                return false;
            }
            if (bytes.len > 2 and prefix[2] != 0 and bytes[2] != prefix[2]) {
                return false;
            }
            if (bytes.len > 3 and prefix[3] != 0 and bytes[3] != prefix[3]) {
                return false;
            }
        }
        return true;
    }

    pub fn matches(self: Pattern, address: []const u8) bool {
        if (address.len < self.raw.len) return false;

        // Quick check for impossible matches
        if (!self.couldMatch(address)) return false;

        // Full pattern match
        for (self.raw, 0..) |c, i| {
            if (self.mask[i]) {
                const addr_char = if (self.options.ignore_case)
                    std.ascii.toLower(address[i])
                else
                    address[i];

                const pattern_char = if (self.options.ignore_case)
                    std.ascii.toLower(c)
                else
                    c;

                if (addr_char != pattern_char) {
                    return false;
                }
            }
        }
        return true;
    }
};
