const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "grincel",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // System libraries
    exe.linkSystemLibrary("c");

    // Platform specific libraries
    if (target.result.os.tag == .macos) {
        exe.addFrameworkPath(.{ .cwd_relative = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks" });
        exe.addSystemIncludePath(.{ .cwd_relative = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include" });
        exe.linkFramework("Metal");
        exe.linkFramework("Foundation");
        exe.linkFramework("QuartzCore");

        // Add optional Metal shader compilation
        const shader_step = b.step("shader", "Compile Metal shader");
        const metal_shader = b.addSystemCommand(&[_][]const u8{
            "/usr/bin/env",
            "xcrun",
            "-sdk",
            "macosx",
            "metal",
            "-c",
            "src/shaders/vanity.metal",
            "-o",
            "src/shaders/vanity.air",
        });
        shader_step.dependOn(&metal_shader.step);

        const metal_lib = b.addSystemCommand(&[_][]const u8{
            "/usr/bin/env",
            "xcrun",
            "-sdk",
            "macosx",
            "metallib",
            "src/shaders/vanity.air",
            "-o",
            "src/shaders/vanity.metallib",
        });
        metal_lib.step.dependOn(&metal_shader.step);
        shader_step.dependOn(&metal_lib.step);
    } else {
        exe.linkSystemLibrary("vulkan");
    }

    exe.addIncludePath(.{ .cwd_relative = "deps/ed25519/src" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the vanity address generator");
    run_step.dependOn(&run_cmd.step);
}
