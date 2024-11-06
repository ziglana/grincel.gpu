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

    pub fn init(allocator: std.mem.Allocator, pattern: []const u8, options: PatternOptions) !Pattern {
        var mask = try allocator.alloc(bool, pattern.len);
        var fixed_chars = try allocator.alloc(u8, pattern.len);
        var fixed_count: usize = 0;

        for (pattern) |c, i| {
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
        };
    }

    pub fn deinit(self: *Pattern) void {
        self.allocator.free(self.raw);
        self.allocator.free(self.mask);
        self.allocator.free(self.fixed_chars);
    }

    pub fn matches(self: Pattern, address: []const u8) bool {
        if (address.len < self.raw.len) return false;

        for (self.raw) |c, i| {
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