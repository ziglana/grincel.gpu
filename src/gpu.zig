const std = @import("std");
const builtin = @import("builtin");
const SearchState = @import("search_state.zig").SearchState;

pub const GpuBackend = enum {
    vulkan,
    metal,
};

pub const GpuManager = struct {
    backend: GpuBackend,
    impl: union {
        vulkan: @import("vulkan.zig").Vulkan,
        metal: @import("metal.zig").Metal,
    },

    pub fn init(allocator: std.mem.Allocator) !GpuManager {
        if (builtin.os.tag == .macos) {
            return GpuManager{
                .backend = .metal,
                .impl = .{ .metal = try @import("metal.zig").Metal.init(allocator) },
            };
        } else {
            return GpuManager{
                .backend = .vulkan,
                .impl = .{ .vulkan = try @import("vulkan.zig").Vulkan.init(allocator) },
            };
        }
    }

    pub fn deinit(self: *GpuManager) void {
        switch (self.backend) {
            .vulkan => self.impl.vulkan.deinit(),
            .metal => self.impl.metal.deinit(),
        }
    }

    pub fn createComputePipeline(self: *GpuManager, shader_code: []const u8) !void {
        switch (self.backend) {
            .vulkan => return self.impl.vulkan.createComputePipeline(shader_code),
            .metal => return self.impl.metal.createComputePipeline(shader_code),
        }
    }

    pub fn dispatchCompute(self: *GpuManager, state: ?*SearchState, workgroup_size: u32) !void {
        switch (self.backend) {
            .vulkan => return self.impl.vulkan.dispatchCompute(state, workgroup_size),
            .metal => return self.impl.metal.dispatchCompute(state, workgroup_size),
        }
    }
};
