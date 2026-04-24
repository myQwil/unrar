const std = @import("std");
const rar = @import("unrar");

pub fn main(init: std.process.Init) !void {
	var args = init.minimal.args.iterate();
	_ = args.skip();
	const arg = args.next() orelse return error.NoArgSpecified;

	std.debug.print("listing contents of: {s}\n", .{ arg });

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
