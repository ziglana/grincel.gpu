const std = @import("std");
const metal = @cImport({
    @cInclude("Metal/Metal.h");
});

pub const Metal = struct {
    device: *metal.MTLDevice,
    command_queue: *metal.MTLCommandQueue,
    library: *metal.MTLLibrary,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Metal {
        const device = metal.MTLCreateSystemDefaultDevice();
        if (device == null) return error.NoMetalDevice;

        const queue = device.?.newCommandQueue();
        if (queue == null) return error.CommandQueueCreationFailed;

        // Load default library containing our compute shader
        const library = try device.?.newDefaultLibrary();

        return Metal{
            .device = device.?,
            .command_queue = queue.?,
            .library = library,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Metal) void {
        self.library.release();
        self.command_queue.release();
        self.device.release();
    }

    pub fn createComputePipeline(self: *Metal, _: []const u8) !void {
        const function = try self.library.newFunctionWithName("vanityCompute");
        const pipeline_descriptor = metal.MTLComputePipelineDescriptor.alloc().init();
        pipeline_descriptor.setComputeFunction(function);
        
        return self.device.newComputePipelineStateWithDescriptor(pipeline_descriptor);
    }

    pub fn dispatchCompute(self: *Metal, state: *SearchState, workgroup_size: u32) !void {
        const command_buffer = self.command_queue.commandBuffer();
        const compute_encoder = command_buffer.computeCommandEncoder();

        // Set compute pipeline
        compute_encoder.setComputePipelineState(self.compute_pipeline);

        // Set buffer and dispatch
        const grid_size = metal.MTLSize{ 
            .width = workgroup_size, 
            .height = 1, 
            .depth = 1 
        };
        const thread_group_size = metal.MTLSize{ 
            .width = 256, 
            .height = 1, 
            .depth = 1 
        };

        compute_encoder.dispatchThreadgroups(grid_size, thread_group_size);
        compute_encoder.endEncoding();

        command_buffer.commit();
        command_buffer.waitUntilCompleted();
    }
};