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

	var files = std.ArrayList([]const u8).init(b.allocator);
	defer files.deinit();
	for ([_][]const u8{
		"rar", "strlist", "strfn", "pathfn", "smallfn", "global", "file", "filefn",
		"filcreat", "archive", "arcread", "unicode", "system", "crypt", "crc", "rawread",
		"encname", "resource", "match", "timefn", "rdwrfn", "consio", "options", "errhnd",
		"rarvm", "secpassword", "rijndael", "getbits", "sha1", "sha256", "blake2s", "hash",
		"extinfo", "extract", "volume", "list", "find", "unpack", "headers", "threadpool",
		"rs16", "cmddata", "ui",
		"filestr", "scantree", "dll", "qopen",
	}) |s|
		try files.append(b.fmt("{s}.cpp", .{ s }));
	lib.addCSourceFiles(.{
		.root = b.path("src"),
		.files = files.items,
		.flags = &.{"-fno-sanitize=undefined"}
	});
	lib.defineCMacro("_FILE_OFFSET_BITS", "64");
	lib.defineCMacro("_LARGEFILE_SOURCE", null);
	lib.defineCMacro("RAR_SMP", null);
	lib.defineCMacro("RARDLL", null);
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
