const std = @import("std");

pub const MetalFramework = struct {
    pub const Device = *anyopaque;
    pub const CommandQueue = *anyopaque;
    pub const CommandBuffer = *anyopaque;
    pub const ComputeCommandEncoder = *anyopaque;
    pub const Library = *anyopaque;
    pub const Function = *anyopaque;
    pub const ComputePipelineState = *anyopaque;
    pub const Buffer = *anyopaque;
    pub const Error = *anyopaque;

    pub const Size = extern struct {
        width: usize,
        height: usize,
        depth: usize,
    };

    pub const ResourceOptions = packed struct(u32) {
        storage_mode: u2 = 0,
        cpu_cache_mode: u2 = 0,
        _padding: u28 = 0,
    };

    // Function types
    pub const CreateSystemDefaultDeviceFn = fn () callconv(.C) ?Device;
    pub const NewCommandQueueFn = fn (Device) callconv(.C) ?CommandQueue;
    pub const NewBufferWithLengthFn = fn (Device, usize, ResourceOptions) callconv(.C) ?Buffer;
    pub const CommandBufferFn = fn (CommandQueue) callconv(.C) ?CommandBuffer;
    pub const ComputeCommandEncoderFn = fn (CommandBuffer) callconv(.C) ?ComputeCommandEncoder;
    pub const SetComputePipelineStateFn = fn (ComputeCommandEncoder, ComputePipelineState) callconv(.C) void;
    pub const SetBufferFn = fn (ComputeCommandEncoder, Buffer, usize, u32) callconv(.C) void;
    pub const DispatchThreadgroupsFn = fn (ComputeCommandEncoder, Size, Size) callconv(.C) void;
    pub const EndEncodingFn = fn (ComputeCommandEncoder) callconv(.C) void;
    pub const CommitFn = fn (CommandBuffer) callconv(.C) void;
    pub const WaitUntilCompletedFn = fn (CommandBuffer) callconv(.C) void;
    pub const GetContentsFn = fn (Buffer) callconv(.C) [*]u8;
    pub const GetLengthFn = fn (Buffer) callconv(.C) usize;
    pub const NewLibraryWithDataFn = fn (Device, [*]const u8, usize, ?*Error) callconv(.C) ?Library;
    pub const NewFunctionWithNameFn = fn (Library, [*:0]const u8) callconv(.C) ?Function;
    pub const NewComputePipelineStateFn = fn (Device, Function, ?*Error) callconv(.C) ?ComputePipelineState;

    // Function pointers
    create_system_default_device: CreateSystemDefaultDeviceFn,
    new_command_queue: NewCommandQueueFn,
    new_buffer_with_length: NewBufferWithLengthFn,
    command_buffer: CommandBufferFn,
    compute_command_encoder: ComputeCommandEncoderFn,
    set_compute_pipeline_state: SetComputePipelineStateFn,
    set_buffer: SetBufferFn,
    dispatch_threadgroups: DispatchThreadgroupsFn,
    end_encoding: EndEncodingFn,
    commit: CommitFn,
    wait_until_completed: WaitUntilCompletedFn,
    get_contents: GetContentsFn,
    get_length: GetLengthFn,
    new_library_with_data: NewLibraryWithDataFn,
    new_function_with_name: NewFunctionWithNameFn,
    new_compute_pipeline_state: NewComputePipelineStateFn,

    pub fn init() !MetalFramework {
        // Load Metal framework
        const framework = try std.DynLib.openZ("/System/Library/Frameworks/Metal.framework/Metal");
        defer framework.close();

        // Load function pointers
        return MetalFramework{
            .create_system_default_device = framework.lookup(CreateSystemDefaultDeviceFn, "MTLCreateSystemDefaultDevice") orelse return error.SymbolNotFound,
            .new_command_queue = framework.lookup(NewCommandQueueFn, "newCommandQueue") orelse return error.SymbolNotFound,
            .new_buffer_with_length = framework.lookup(NewBufferWithLengthFn, "newBufferWithLength:options:") orelse return error.SymbolNotFound,
            .command_buffer = framework.lookup(CommandBufferFn, "commandBuffer") orelse return error.SymbolNotFound,
            .compute_command_encoder = framework.lookup(ComputeCommandEncoderFn, "computeCommandEncoder") orelse return error.SymbolNotFound,
            .set_compute_pipeline_state = framework.lookup(SetComputePipelineStateFn, "setComputePipelineState:") orelse return error.SymbolNotFound,
            .set_buffer = framework.lookup(SetBufferFn, "setBuffer:offset:atIndex:") orelse return error.SymbolNotFound,
            .dispatch_threadgroups = framework.lookup(DispatchThreadgroupsFn, "dispatchThreadgroups:threadsPerThreadgroup:") orelse return error.SymbolNotFound,
            .end_encoding = framework.lookup(EndEncodingFn, "endEncoding") orelse return error.SymbolNotFound,
            .commit = framework.lookup(CommitFn, "commit") orelse return error.SymbolNotFound,
            .wait_until_completed = framework.lookup(WaitUntilCompletedFn, "waitUntilCompleted") orelse return error.SymbolNotFound,
            .get_contents = framework.lookup(GetContentsFn, "contents") orelse return error.SymbolNotFound,
            .get_length = framework.lookup(GetLengthFn, "length") orelse return error.SymbolNotFound,
            .new_library_with_data = framework.lookup(NewLibraryWithDataFn, "newLibraryWithData:error:") orelse return error.SymbolNotFound,
            .new_function_with_name = framework.lookup(NewFunctionWithNameFn, "newFunctionWithName:") orelse return error.SymbolNotFound,
            .new_compute_pipeline_state = framework.lookup(NewComputePipelineStateFn, "newComputePipelineStateWithFunction:error:") orelse return error.SymbolNotFound,
        };
    }
};
