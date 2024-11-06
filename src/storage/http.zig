const std = @import("std");
const StorageConfig = @import("../config.zig").StorageConfig;
const Ed25519 = @import("../ed25519.zig").Ed25519;

pub const HttpStorage = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,
    url: []const u8,

    pub fn init(allocator: std.mem.Allocator, config: StorageConfig) !HttpStorage {
        if (config.url == null) return error.MissingUrl;

        return HttpStorage{
            .allocator = allocator,
            .client = try std.http.Client.init(allocator),
            .url = config.url.?,
        };
    }

    pub fn deinit(self: *HttpStorage) void {
        self.client.deinit();
    }

    pub fn store(self: *HttpStorage, keypair: Ed25519.KeyPair) !void {
        var headers = std.http.Headers.init(self.allocator);
        defer headers.deinit();
        try headers.append("Content-Type", "application/json");

        const body = try std.json.stringifyAlloc(self.allocator, .{
            .public_key = std.fmt.fmtSliceHexLower(&keypair.public),
            .private_key = std.fmt.fmtSliceHexLower(&keypair.private),
        }, .{});
        defer self.allocator.free(body);

        _ = try self.client.post(self.url, headers, body);
    }
};