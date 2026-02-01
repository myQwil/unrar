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

		const upstream = b.dependency("unrar", .{});
		mod.addCSourceFiles(.{
			.root = upstream.path("."),
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
		lib.installHeadersDirectory(b.path("."), "", .{
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
		"largepage.cpp",
		"filestr.cpp",
		"scantree.cpp",
		"dll.cpp",
		"qopen.cpp",
	};

	const windows = [_][]const u8{
		"motw.cpp",
		"isnt.cpp",
	};
};
