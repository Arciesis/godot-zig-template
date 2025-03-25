const std = @import("std");
const gdbindings = @import("godot_zig_bindings");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const godot_path = b.option([]const u8, "godot", "Path to Godot engine binary [default: `godot`]") orelse "godot";

    // const godot_dep = b.dependency("godot_zig_bindings", .{
    //     .target = target,
    //     .optimize = optimize,
    //     .godot = godot_path,
    // });

    //
    // Generate extension_api.json
    //
    // const tmpdir = b.makeTempPath();
    // const api_path = try std.fs.path.join(b.allocator, &.{ tmpdir, "extension_api.json" });
    const dump_cmd = b.addSystemCommand(&.{
        godot_path, "--dump-extension-api", "--headless",
    });

    const flags = std.fs.File.OpenFlags{
        .mode = .read_only,
        .lock = .exclusive,
        .allow_ctty = false,
        .lock_nonblocking = false,
    };

    if (std.fs.cwd().access("extension_api.json", flags)) {} else |_| {
        const output = dump_cmd.captureStdOut();
        b.getInstallStep().dependOn(&b.addInstallFileWithDir(output, .prefix, "extension_api.json").step);
    }

    //
    // use of GodotZigBindings to generate the bindings
    //
    // gdbindings.GenerateGDExtensionAPI("zig-out/extension_api.json", gdbindings.BuildConfiguration.float_64);
    // const gdext_dep = b.dependency("godot_zig_bindings", .{ .gdextension = "zig-out/extension_api.json" });
    // gdext_dep.builder.dependencyFromBuildZig(@This, .{});
    // const gdext_comp = gdext_dep.artifact("binding_generator");
    // b.installArtifact(gdext_comp);

    // const tool = b.addExecutable(.{
    //     .name = "binder",
    //     .target = target,
    //     .optimize = optimize,
    //     .root_source_file =
    // });

    // gdbindings.generateGDExtensionAPI("extension_api.json", gdbindings.BuildConfiguration.float_64);

    // dump_cmd.setCwd(.{ .cwd_relative = tmpdir });
    // const bind_step = b.step("bind", "Build the binding generator");
    // const bind_exe = b.addExecutable(.{
    //     .name = "bind_gen",
    //     .target = target,
    //     .optimize = optimize,
    //     .root_source_file = &.{ .cwd_relative = dump_cmd.cwd, .src_path = .{.owner = b, .sub_path = "binding_generator.zig", }, },
    // });

    // bind_step.makeFn = struct {
    //     pub fn make(_: *std.Build, step: *std.Build.Step) !void {
    //         const godot_build = @import("godot_zig_bindings/build.zig");
    //         const config = godot_build.Config{
    //             .name = "bind",
    //             .root_source_file = &.{ .cwd_relative = dump_cmd.cwd, .src_path = .{.owner = b, .sub_path = "binding_generator.zig", }, },
    //             .bindings_output_path = .{.path = "src/gen/"},
    //         };
    //
    //         const ext = godot_build.init(b, config);
    //         try godot_build.generateBindingsToFile
    //     }
    // };
    //

    const lib = b.addSharedLibrary(.{
        .name = "godot_zig_template",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    // lib.root_module.addImport("godot", godot_dep.module("godot_zig_bindings"));

    b.lib_dir = "../game_project/lib";
    b.installArtifact(lib);

    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
