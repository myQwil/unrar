const std = @import("std");
const LinkMode = std.builtin.LinkMode;

const Options = struct {
	linkage: LinkMode = .static,

	fn init(b: *std.Build) Options {
		const default: Options = .{};
		return .{
			.linkage = b.option(LinkMode, "linkage",
				"Library linking method"
			) orelse default.linkage,
		};
	}
};

pub fn build(b: *std.Build) !void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});
	const opt: Options = .init(b);

	//---------------------------------------------------------------------------
	// Library
	const lib = blk: {
		const mod = b.createModule(.{
			.target = target,
			.optimize = optimize,
			.link_libcpp = true,
		});

		const mem = b.allocator;
		var files: std.ArrayList([]const u8) = try .initCapacity(mem, 0);
		defer files.deinit(mem);

		try files.appendSlice(mem, &src.main);
		if (target.result.os.tag == .windows) {
			try files.appendSlice(mem, &src.windows);
			mod.linkSystemLibrary("powrprof", .{});
			mod.linkSystemLibrary("oleaut32", .{});
			mod.linkSystemLibrary("ole32", .{});
		}

		mod.addCSourceFiles(.{
			.files = files.items,
			.flags = &.{
				"-fno-sanitize=undefined",
				"-D_FILE_OFFSET_BITS=64",
				"-D_LARGEFILE_SOURCE",
				"-DRAR_SMP",
				"-DRARDLL",
			},
		});
		const lib = b.addLibrary(.{
			.name = "unrar",
			.linkage = opt.linkage,
			.root_module = mod,
		});
		lib.installHeadersDirectory(b.path("src"), "", .{
			.include_extensions = &.{ "dll.hpp" },
		});
		b.installArtifact(lib);
		break :blk lib;
	};

	//---------------------------------------------------------------------------
	// Zig module
	const zig_mod = b.addModule("unrar", .{
		.root_source_file = b.path("unrar.zig"),
		.target = target,
		.optimize = optimize,
	});
	zig_mod.linkLibrary(lib);

	//---------------------------------------------------------------------------
	// Zig example
	const exe = b.addExecutable(.{
		.name = "hello",
		.root_module = b.createModule(.{
			.root_source_file = b.path("examples/hello.zig"),
			.target = target,
			.optimize = optimize,
			.imports = &.{ .{ .name = "unrar", .module = zig_mod } },
		}),
	});

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

const src = struct {
	const main = [_][]const u8{
		"src/rar.cpp",
		"src/strlist.cpp",
		"src/strfn.cpp",
		"src/pathfn.cpp",
		"src/smallfn.cpp",
		"src/global.cpp",
		"src/file.cpp",
		"src/filefn.cpp",
		"src/filcreat.cpp",
		"src/archive.cpp",
		"src/arcread.cpp",
		"src/unicode.cpp",
		"src/system.cpp",
		"src/crypt.cpp",
		"src/crc.cpp",
		"src/rawread.cpp",
		"src/encname.cpp",
		"src/resource.cpp",
		"src/match.cpp",
		"src/timefn.cpp",
		"src/rdwrfn.cpp",
		"src/consio.cpp",
		"src/options.cpp",
		"src/errhnd.cpp",
		"src/rarvm.cpp",
		"src/secpassword.cpp",
		"src/rijndael.cpp",
		"src/getbits.cpp",
		"src/sha1.cpp",
		"src/sha256.cpp",
		"src/blake2s.cpp",
		"src/hash.cpp",
		"src/extinfo.cpp",
		"src/extract.cpp",
		"src/volume.cpp",
		"src/list.cpp",
		"src/find.cpp",
		"src/unpack.cpp",
		"src/headers.cpp",
		"src/threadpool.cpp",
		"src/rs16.cpp",
		"src/cmddata.cpp",
		"src/ui.cpp",
		"src/largepage.cpp",
		"src/filestr.cpp",
		"src/scantree.cpp",
		"src/dll.cpp",
		"src/qopen.cpp",
	};

	const windows = [_][]const u8{
		"src/motw.cpp",
		"src/isnt.cpp",
	};
};
