const std = @import("std");
const Pattern = @import("pattern.zig").Pattern;

pub const Keypair = struct {
    public: []const u8,
    private: []const u8,
};

pub const SearchState = struct {
    allocator: std.mem.Allocator,
    pattern: *Pattern,
    found: bool,
    keypair: ?Keypair,

    pub fn init(allocator: std.mem.Allocator, pattern: *Pattern) !SearchState {
        return SearchState{
            .allocator = allocator,
            .pattern = pattern,
            .found = false,
            .keypair = null,
        };
    }

    pub fn deinit(self: *SearchState) void {
        if (self.keypair) |kp| {
            self.allocator.free(kp.public);
            self.allocator.free(kp.private);
        }
    }

    pub fn checkResults(self: *SearchState) !void {
        _ = self; // autofix
        // TODO: Check GPU results and update state
        // This would be implemented based on the specific GPU backend
    }

    pub fn getFoundKeypair(self: *SearchState) Keypair {
        return self.keypair orelse unreachable;
    }
};
