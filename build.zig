const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "grincel",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // System libraries
    exe.linkSystemLibrary("c");
    
    // Detect OS and link appropriate GPU libraries
    if (target.isDarwin()) {
        exe.linkSystemLibrary("Metal");
        exe.linkSystemLibrary("QuartzCore");
        exe.linkFramework("Metal");
        exe.linkFramework("Foundation");
        exe.addIncludePath("deps/MoltenVK/include");
        exe.linkSystemLibrary("MoltenVK");
    } else {
        exe.linkSystemLibrary("vulkan");
    }
    
    exe.addIncludePath("deps/ed25519/src");
    
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the vanity address generator");
    run_step.dependOn(&run_cmd.step);
}