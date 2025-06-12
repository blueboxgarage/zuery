// Zuery Build Configuration
//
// This file configures the build process for the Zuery project.
// It sets up the main executable, test suite, and additional build steps.

const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the user to customize build for different architectures
    const target = b.standardTargetOptions(.{});
    
    // Standard optimization options allow the user to specify performance vs. debug settings
    const optimize = b.standardOptimizeOption(.{});

    // Create the main executable
    const exe = b.addExecutable(.{
        .name = "zuery",
        .root_source_file = b.path("src/main.zig"), // Main entry point
        .target = target,
        .optimize = optimize,
    });

    // Install the executable to the configured path
    b.installArtifact(exe);

    // Create a run step to execute the binary
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Register the run step
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Add tests
    // Tests from main.zig
    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Tests from the dedicated test file
    const dedicated_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Register the test step to run all tests
    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&b.addRunArtifact(main_tests).step);
    test_step.dependOn(&b.addRunArtifact(dedicated_tests).step);
    
    // Register a dedicated test step for the tests.zig file only
    const test_only_step = b.step("test-only", "Run only the dedicated test file");
    test_only_step.dependOn(&b.addRunArtifact(dedicated_tests).step);
    
    // Add docs step (placeholder - can be expanded later with a document generation tool)
    const docs_step = b.step("docs", "Open the documentation (placeholder)");
    const docs_cmd = b.addSystemCommand(&[_][]const u8{
        "echo", "Documentation is available in the docs/ directory"
    });
    docs_step.dependOn(&docs_cmd.step);
}