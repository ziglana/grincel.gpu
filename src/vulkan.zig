const std = @import("std");
const vk = @import("vulkan");
const SearchState = @import("main.zig").SearchState;

pub const Vulkan = struct {
    instance: vk.Instance,
    device: vk.Device,
    queue: vk.Queue,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Vulkan {
        const app_info = vk.ApplicationInfo{
            .sType = .VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pApplicationName = "Solana Vanity Grinder",
            .applicationVersion = vk.makeApiVersion(0, 1, 0, 0),
            .pEngineName = "No Engine",
            .engineVersion = vk.makeApiVersion(0, 1, 0, 0),
            .apiVersion = vk.API_VERSION_1_2,
        };

        const instance = try vk.createInstance(&.{
            .sType = .VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .pApplicationInfo = &app_info,
        }, null);

        const device = try selectComputeDevice(instance);
        const queue = try device.getQueue(0);

        return Vulkan{
            .instance = instance,
            .device = device,
            .queue = queue,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Vulkan) void {
        self.device.destroy();
        self.instance.destroy();
    }

    pub fn createComputePipeline(self: *Vulkan, shader_code: []const u8) !ComputePipeline {
        const shader_module = try self.device.createShaderModule(&.{
            .sType = .VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
            .codeSize = shader_code.len,
            .pCode = @ptrCast(*const u32, shader_code.ptr),
        }, null);

        // Create compute pipeline
        const pipeline_layout = try self.device.createPipelineLayout(&.{
            .sType = .VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .setLayoutCount = 1,
            .pSetLayouts = &[_]vk.DescriptorSetLayout{descriptor_set_layout},
        }, null);

        const pipeline = try self.device.createComputePipelines(null, 1, &[_]vk.ComputePipelineCreateInfo{.{
            .sType = .VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
            .stage = .{
                .sType = .VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .stage = .VK_SHADER_STAGE_COMPUTE_BIT,
                .module = shader_module,
                .pName = "main",
            },
            .layout = pipeline_layout,
        }}, null);

        return ComputePipeline{
            .pipeline = pipeline[0],
            .layout = pipeline_layout,
            .shader = shader_module,
        };
    }

    pub fn dispatchCompute(self: *Vulkan, pipeline: ComputePipeline, state: *SearchState, workgroup_size: u32) !void {
        const command_buffer = try self.beginSingleTimeCommands();
        defer self.endSingleTimeCommands(command_buffer);

        command_buffer.cmdBindPipeline(.VK_PIPELINE_BIND_POINT_COMPUTE, pipeline.pipeline);
        command_buffer.cmdBindDescriptorSets(
            .VK_PIPELINE_BIND_POINT_COMPUTE,
            pipeline.layout,
            0,
            1,
            &[_]vk.DescriptorSet{state.descriptor_set},
            0,
            null,
        );

        command_buffer.cmdDispatch(workgroup_size, 1, 1);
    }
};