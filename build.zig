const std = @import("std");

const Options = struct {
	shared: bool = false,
};

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	const defaults = Options{};
	const opt = Options{
		.shared = b.option(bool, "shared", "Build shared library")
			orelse defaults.shared,
	};

	const lib = if (opt.shared) b.addSharedLibrary(.{
		.name="unrar", .target=target, .optimize=optimize, .pic=true,
	}) else b.addStaticLibrary(.{
		.name="unrar", .target=target, .optimize=optimize,
	});
	lib.linkLibCpp();

	const src = b.path("src");
	lib.addCSourceFiles(.{
		.root = src,
		.files = &.{
			"rar.cpp",
			"strlist.cpp",
			"strfn.cpp",
			"pathfn.cpp",
			"smallfn.cpp",
			"global.cpp",
			"file.cpp",
			"filefn.cpp",
			"filcreat.cpp",
			"archive.cpp",
			"arcread.cpp",
			"unicode.cpp",
			"system.cpp",
			"crypt.cpp",
			"crc.cpp",
			"rawread.cpp",
			"encname.cpp",
			"resource.cpp",
			"match.cpp",
			"timefn.cpp",
			"rdwrfn.cpp",
			"consio.cpp",
			"options.cpp",
			"errhnd.cpp",
			"rarvm.cpp",
			"secpassword.cpp",
			"rijndael.cpp",
			"getbits.cpp",
			"sha1.cpp",
			"sha256.cpp",
			"blake2s.cpp",
			"hash.cpp",
			"extinfo.cpp",
			"extract.cpp",
			"volume.cpp",
			"list.cpp",
			"find.cpp",
			"unpack.cpp",
			"headers.cpp",
			"threadpool.cpp",
			"rs16.cpp",
			"cmddata.cpp",
			"ui.cpp",
			"filestr.cpp",
			"scantree.cpp",
			"dll.cpp",
			"qopen.cpp",
		},
		.flags = &.{
			"-fno-sanitize=undefined",
			"-D_FILE_OFFSET_BITS=64",
			"-D_LARGEFILE_SOURCE",
			"-DRAR_SMP",
			"-DRARDLL",
		},
	});
	lib.installHeadersDirectory(src, "", .{ .include_extensions = &.{ "dll.hpp" } });
	b.installArtifact(lib);

	const mod = b.addModule("unrar", .{
		.root_source_file = b.path("unrar.zig"),
		.target = target,
		.optimize = optimize,
	});
	mod.linkLibrary(lib);

	const exe = b.addExecutable(.{
		.name = "hello",
		.root_source_file = b.path("examples/hello.zig"),
		.target = target,
		.optimize = optimize,
	});
	exe.root_module.addImport("unrar", mod);

	const install = b.addInstallArtifact(exe, .{});
	const step_install = b.step("hello", "Build the zig example");
	step_install.dependOn(&install.step);

	const run = b.addRunArtifact(exe);
	run.step.dependOn(&install.step);
	const step_run = b.step("run_hello", "Build and run the zig example");
	step_run.dependOn(&run.step);
	if (b.args) |args| {
		run.addArgs(args);
	}
}
