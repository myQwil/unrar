const std = @import("std");
pub const WChar = c_int;
pub const Callback = ?*const fn (CallbackMsg, usize, usize, usize) callconv(.C) c_int;
pub const ChangeVolProc = ?*const fn (?[*:0]u8, c_int) callconv(.C) c_int;
pub const ProcessDataProc = ?*const fn (?[*:0]u8, c_int) callconv(.C) c_int;
pub const dll_version = 9;

const success = 0;
const end_of_archive = 10;

pub const Error = error {
	OutOfMemory,
	BadData,
	BadArchive,
	UnknownFormat,
	Open,
	Create,
	Close,
	Read,
	Write,
	SmallBuffer,
	Unknown,
	MissingPassword,
	Reference,
	BadPassword,
	LargeDictionary,
};

const error_list = [_]Error {
	Error.OutOfMemory,
	Error.BadData,
	Error.BadArchive,
	Error.UnknownFormat,
	Error.Open,
	Error.Create,
	Error.Close,
	Error.Read,
	Error.Write,
	Error.SmallBuffer,
	Error.Unknown,
	Error.MissingPassword,
	Error.Reference,
	Error.BadPassword,
	Error.LargeDictionary,
};

const Result = c_uint;

fn toError(i: Result) Error {
	return error_list[i - 11];
}

pub const OpenMode = enum(c_uint) {
	list,
	extract,
	list_incsplit,
};

pub const Operation = enum(c_int) {
	read = -1,
	skip,
	check,
	extract,
};

pub const CallMode = enum(c_uint) {
	ask,
	notify,
};

pub const HashType = enum(c_uint) {
	none,
	crc32,
	blake2,
};

pub const HeaderFlag = enum(c_uint) {
	split_before = 0x01,
	split_after = 0x02,
	encrypted = 0x04,
	solid = 0x10,
	directory = 0x20,
};

pub const OpenFlag = enum(c_uint) {
	volume = 0x0001,
	comment = 0x0002,
	lock = 0x0004,
	solid = 0x0008,
	new_numbering = 0x0010,
	signed = 0x0020,
	recovery = 0x0040,
	enc_headers = 0x0080,
	first_volume = 0x0100,
	keep_broken = 0x0001,
};

pub const CallbackMsg = enum(c_uint) {
	change_volume,
	process_data,
	need_password,
	change_volume_w,
	need_password_w,
	large_dict,
};

pub const Header = extern struct {
	const Self = @This();

	arc_name: [259:0]u8 = std.mem.zeroes([259:0]u8),
	file_name: [259:0]u8 = std.mem.zeroes([259:0]u8),
	flags: c_uint = 0,
	pack_size: c_uint = 0,
	unp_size: c_uint = 0,
	host_os: c_uint = 0,
	file_crc: c_uint = 0,
	file_time: c_uint = 0,
	unp_ver: c_uint = 0,
	method: c_uint = 0,
	file_attr: c_uint = 0,
	cmt_buf: ?[*:0]u8 = null,
	cmt_buf_size: c_uint = 0,
	cmt_size: c_uint = 0,
	cmt_state: c_uint = 0,

	pub fn read(self: *Self, data: *Archive) Error!bool {
		return switch (RARReadHeader(data, self)) {
			success => true,
			end_of_archive => false,
			else => |res| toError(res),
		};
	}
	extern fn RARReadHeader(*Archive, *Self) Result;
};

pub const HeaderEx = extern struct {
	const Self = @This();

	arc_name: [1023:0]u8 = std.mem.zeroes([1023:0]u8),
	arc_name_w: [1023:0]WChar = std.mem.zeroes([1023:0]WChar),
	file_name: [1023:0]u8 = std.mem.zeroes([1023:0]u8),
	file_name_w: [1023:0]WChar = std.mem.zeroes([1023:0]WChar),
	flags: c_uint = 0,
	pack_size: c_uint = 0,
	pack_size_high: c_uint = 0,
	unp_size: c_uint = 0,
	unp_size_high: c_uint = 0,
	host_os: c_uint = 0,
	file_crc: c_uint = 0,
	file_time: c_uint = 0,
	unp_ver: c_uint = 0,
	method: c_uint = 0,
	file_attr: c_uint = 0,
	cmt_buf: ?[*:0]u8 = null,
	cmt_buf_size: c_uint = 0,
	cmt_size: c_uint = 0,
	cmt_state: c_uint = 0,
	dict_size: c_uint = 0,
	hash_type: c_uint = 0,
	hash: [32]u8 = std.mem.zeroes([32]u8),
	redir_type: c_uint = 0,
	redir_name: ?[*:0]WChar = null,
	redir_name_size: c_uint = 0,
	dir_target: c_uint = 0,
	mtime_low: c_uint = 0,
	mtime_high: c_uint = 0,
	ctime_low: c_uint = 0,
	ctime_high: c_uint = 0,
	atime_low: c_uint = 0,
	atime_high: c_uint = 0,
	arc_name_ex: ?[*:0]WChar = null,
	arc_name_ex_size: c_uint = 0,
	file_name_ex: ?[*:0]WChar = null,
	file_name_ex_size: c_uint = 0,
	reserved: [982]c_uint = std.mem.zeroes([982]c_uint),

	pub fn read(self: *Self, data: *Archive) Error!bool {
		return switch (RARReadHeaderEx(data, self)) {
			success => true,
			end_of_archive => false,
			else => |res| toError(res),
		};
	}
	extern fn RARReadHeaderEx(*Archive, *Self) Result;
};

pub const OpenData = extern struct {
	const Self = @This();

	arc_name: ?[*:0]const u8 = null,
	open_mode: OpenMode = .list,
	open_result: Result = 0,
	cmt_buf: ?[*:0]u8 = null,
	cmt_buf_size: c_uint = 0,
	cmt_size: c_uint = 0,
	cmt_state: c_uint = 0,

	pub fn open(self: *Self) Error!*Archive {
		return RAROpenArchive(self) orelse toError(self.open_result);
	}
	extern fn RAROpenArchive(*Self) ?*Archive;
};

pub const OpenDataEx = extern struct {
	const Self = @This();

	arc_name: ?[*:0]const u8 = null,
	arc_name_w: ?[*:0]const WChar = null,
	open_mode: OpenMode = .list,
	open_result: Result = 0,
	cmt_buf: ?[*:0]u8 = null,
	cmt_buf_size: c_uint = 0,
	cmt_size: c_uint = 0,
	cmt_state: c_uint = 0,
	flags: c_uint = 0,
	callback: Callback = null,
	user_data: usize = 0,
	op_flags: c_uint = 0,
	cmt_buf_w: ?[*:0]WChar = null,
	reserved: [25]c_uint = std.mem.zeroes([25]c_uint),

	pub fn open(self: *Self) Error!*Archive {
		return RAROpenArchiveEx(self) orelse toError(self.open_result);
	}
	extern fn RAROpenArchiveEx(*Self) ?*Archive;
};

pub const Archive = opaque {
	const Self = @This();

	pub fn close(self: *Self) Error!void {
		const result = RARCloseArchive(self);
		if (result != success)
			return toError(result);
	}
	extern fn RARCloseArchive(*Self) Result;

	pub fn processFile(
		self: *Self, op: Operation, dest: ?[:0]u8, name: ?[:0]u8,
	) Error!void {
		const d = if (dest) |d| d.ptr else null;
		const n = if (name) |n| n.ptr else null;
		const result = RARProcessFile(self, op, d, n);
		if (result != success)
			return toError(@intCast(result));
	}
	extern fn RARProcessFile(*Self, Operation, ?[*:0]u8, ?[*:0]u8) c_int;

	pub fn processFileW(
		self: *Self, op: Operation, dest: ?[:0]WChar, name: ?[:0]WChar,
	) Error!void {
		const d = if (dest) |d| d.ptr else null;
		const n = if (name) |n| n.ptr else null;
		const result = RARProcessFileW(self, op, d, n);
		if (result != success)
			return toError(@intCast(result));
	}
	extern fn RARProcessFileW(*Self, Operation, ?[*:0]WChar, ?[*:0]WChar) c_int;

	pub fn next(self: *Self) Error!?Header {
		var head: Header = undefined;
		return if (try head.read(self)) head else null;
	}

	pub fn nextEx(self: *Self) Error!?HeaderEx {
		var head: HeaderEx = undefined;
		return if (try head.read(self)) head else null;
	}

	pub const setCallback = RARSetCallback;
	extern fn RARSetCallback(*Self, cb: Callback, data: usize) void;

	pub const setChangeVolProc = RARSetChangeVolProc;
	extern fn RARSetChangeVolProc(*Self, proc: ChangeVolProc) void;

	pub const setProcessDataProc = RARSetProcessDataProc;
	extern fn RARSetProcessDataProc(*Self, proc: ProcessDataProc) void;

	pub fn setPassword(self: *Self, password: [:0]u8) void {
		RARSetPassword(self, password.ptr);
	}
	extern fn RARSetPassword(*Self, password: [*:0]u8) void;
};

pub const getDllVersion = RARGetDllVersion;
extern fn RARGetDllVersion() c_int;
