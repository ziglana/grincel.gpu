const std = @import("std");
const Config = @import("../config.zig").Config;
const http = @import("storage/http.zig");
const postgresql = @import("storage/postgresql.zig");
const clickhouse = @import("storage/clickhouse.zig");
const sqlite = @import("storage/sqlite.zig");
const telegram = @import("storage/telegram.zig");

pub const Storage = union(enum) {
    http: http.HttpStorage,
    postgresql: postgresql.PostgresStorage,
    clickhouse: clickhouse.ClickHouseStorage,
    sqlite: sqlite.SqliteStorage,
    telegram: telegram.TelegramStorage,
    none: void,

    pub fn init(allocator: std.mem.Allocator, config: Config) !Storage {
        return switch (config.storage.type) {
            .http => Storage{ .http = try http.HttpStorage.init(allocator, config.storage) },
            .postgresql => Storage{ .postgresql = try postgresql.PostgresStorage.init(allocator, config.storage) },
            .clickhouse => Storage{ .clickhouse = try clickhouse.ClickHouseStorage.init(allocator, config.storage) },
            .sqlite => Storage{ .sqlite = try sqlite.SqliteStorage.init(allocator, config.storage) },
            .telegram => Storage{ .telegram = try telegram.TelegramStorage.init(allocator, config.storage) },
            .none => Storage{ .none = {} },
        };
    }

    pub fn deinit(self: *Storage) void {
        switch (self.*) {
            .http => |*h| h.deinit(),
            .postgresql => |*p| p.deinit(),
            .clickhouse => |*c| c.deinit(),
            .sqlite => |*s| s.deinit(),
            .telegram => |*t| t.deinit(),
            .none => {},
        }
    }

    pub fn store(self: *Storage, keypair: Ed25519.KeyPair) !void {
        switch (self.*) {
            .http => |*h| try h.store(keypair),
            .postgresql => |*p| try p.store(keypair),
            .clickhouse => |*c| try c.store(keypair),
            .sqlite => |*s| try s.store(keypair),
            .telegram => |*t| try t.store(keypair),
            .none => {},
        }
    }
};