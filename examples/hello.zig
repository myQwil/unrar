const std = @import("std");
const rar = @import("unrar");

pub fn main() !void {
	var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
	defer switch (gpa.deinit()) {
		.leak => std.debug.print("Memory leaks detected!\n", .{}),
		.ok => std.debug.print("No memory leaks detected.\n", .{}),
	};

	var args = try std.process.argsWithAllocator(gpa.allocator());
	defer args.deinit();

	_ = args.skip();
	const arg = args.next()
		orelse return std.debug.print("No arg given.\n", .{});

	var data: rar.OpenData = .{ .arc_name = arg.ptr, .open_mode = .list };
	const arc: *rar.Archive = try data.open();

	// print the file name of each entry
	var header: rar.Header = .{};
	while (try header.read(arc)) {
		const name = header.file_name[0..std.mem.len(header.file_name[0..].ptr)];
		std.debug.print("{s}\n", .{ name });
		try arc.processFile(.skip, null, null);
	}
}
