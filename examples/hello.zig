const std = @import("std");
const rar = @import("unrar");

pub fn main() !void {
	var args = std.process.args();
	_ = args.skip();
	const arg = args.next()
		orelse return std.debug.print("No arg given.\n", .{});

	var data = rar.OpenData{ .arc_name = arg.ptr, .open_mode = .list };
	const arc = data.open()
		catch return std.debug.print("Arg is not a valid rar file.\n", .{});

	var head = rar.Header{};
	while (try head.read(arc)) {
		std.debug.print("{s}\n", .{ head.file_name });
		try arc.process(.skip, null, null);
	}
}
