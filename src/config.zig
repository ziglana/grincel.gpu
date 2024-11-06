const std = @import("std");

pub const StorageConfig = struct {
    type: enum {
        none,
        http,
        postgresql,
        clickhouse,
        sqlite,
        telegram,
    },
    url: ?[]const u8 = null,
    token: ?[]const u8 = null,
    chat_id: ?[]const u8 = null,
    database: ?[]const u8 = null,
    table: ?[]const u8 = null,
};

pub const Config = struct {
    storage: StorageConfig,

    pub fn fromEnv(allocator: std.mem.Allocator) !Config {
        const storage_type = std.process.getEnvVarOwned(allocator, "STORAGE_TYPE") catch "none";
        defer allocator.free(storage_type);

        var storage = StorageConfig{
            .type = std.meta.stringToEnum(StorageConfig.type, storage_type) orelse .none,
        };

        if (std.process.getEnvVarOwned(allocator, "STORAGE_URL")) |url| {
            storage.url = url;
        } else |_| {}

        if (std.process.getEnvVarOwned(allocator, "STORAGE_TOKEN")) |token| {
            storage.token = token;
        } else |_| {}

        if (std.process.getEnvVarOwned(allocator, "STORAGE_CHAT_ID")) |chat_id| {
            storage.chat_id = chat_id;
        } else |_| {}

        if (std.process.getEnvVarOwned(allocator, "STORAGE_DATABASE")) |database| {
            storage.database = database;
        } else |_| {}

        if (std.process.getEnvVarOwned(allocator, "STORAGE_TABLE")) |table| {
            storage.table = table;
        } else |_| {}

        return Config{
            .storage = storage,
        };
    }
};