pub const c_wchar = @cImport({
	@cInclude("wchar.h");
}).wchar_t;

pub const Callback = ?*const fn (CallbackMsg, usize, usize, usize) callconv(.c) c_uint;
pub const ChangeVolProc = ?*const fn (?[*:0]u8, VolMode) callconv(.c) c_uint;
pub const ProcessDataProc = ?*const fn (?[*:0]u8, c_int) callconv(.c) c_uint;
pub const dll_version = 9;

const success = 0;
const end_of_archive = 10;
const err_offset = 11;

pub const ErrorCode = enum(c_uint) {
	no_memory = 11,
	bad_data = 12,
	bad_archive = 13,
	unknown_format = 14,
	eopen = 15,
	ecreate = 16,
	eclose = 17,
	eread = 18,
	ewrite = 19,
	small_buf = 20,
	unknown = 21,
	missing_password = 22,
	ereference = 23,
	bad_password = 24,
	large_dict = 25,
};

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

const error_list = [_]Error{
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

fn toError(i: c_uint) Error {
	return error_list[i - err_offset];
}

pub const OpenMode = enum(c_uint) {
	list = 0,
	extract = 1,
	list_incsplit = 2,
};

pub const Operation = enum(c_uint) {
	skip = 0,
	read = 1,
	extract = 2,
};

pub const VolMode = enum(c_uint) {
	ask = 0,
	notify = 1,
};

pub const HashType = enum(c_uint) {
	none = 0,
	crc32 = 1,
	blake2 = 2,
};

pub const CallbackMsg = enum(c_uint) {
	change_volume = 0,
	process_data = 1,
	need_password = 2,
	change_volume_w = 3,
	need_password_w = 4,
	large_dict = 5,
};

pub const HeaderFlags = packed struct(c_uint) {
	split_before: bool = false,
	split_after: bool = false,
	encrypted: bool = false,
	_unused1: u1 = 0,
	solid: bool = false,
	directory: bool = false,
	_unused2: @Int(.unsigned, @bitSizeOf(c_uint) - 6) = 0,
};

pub const Header = extern struct {
	arc_name: [259:0]u8 = @splat(0),
	file_name: [259:0]u8 = @splat(0),
	flags: Flags = .{},
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

	pub const Flags = HeaderFlags;

	pub fn read(self: *Header, arc: *Archive) Error!bool {
		return switch (RARReadHeader(arc, self)) {
			success => true,
			end_of_archive => false,
			else => |res| toError(res),
		};
	}
	extern fn RARReadHeader(*Archive, *Header) c_uint;
};

pub const HeaderEx = extern struct {
	arc_name: [1023:0]u8 = @splat(0),
	arc_name_w: [1023:0]c_wchar = @splat(0),
	file_name: [1023:0]u8 = @splat(0),
	file_name_w: [1023:0]c_wchar = @splat(0),
	flags: Flags = .{},
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
	hash_type: HashType = .none,
	hash: [32]u8 = @splat(0),
	redir_type: c_uint = 0,
	redir_name: ?[*:0]c_wchar = null,
	redir_name_size: c_uint = 0,
	dir_target: c_uint = 0,
	mtime_low: c_uint = 0,
	mtime_high: c_uint = 0,
	ctime_low: c_uint = 0,
	ctime_high: c_uint = 0,
	atime_low: c_uint = 0,
	atime_high: c_uint = 0,
	arc_name_ex: ?[*:0]c_wchar = null,
	arc_name_ex_size: c_uint = 0,
	file_name_ex: ?[*:0]c_wchar = null,
	file_name_ex_size: c_uint = 0,
	reserved: [982]c_uint = @splat(0),

	pub const Flags = HeaderFlags;

	pub fn read(self: *HeaderEx, arc: *Archive) Error!bool {
		return switch (RARReadHeaderEx(arc, self)) {
			success => true,
			end_of_archive => false,
			else => |res| toError(res),
		};
	}
	extern fn RARReadHeaderEx(*Archive, *HeaderEx) c_uint;
};

pub const OpenData = extern struct {
	arc_name: ?[*:0]const u8 = null,
	open_mode: OpenMode = .list,
	open_result: c_uint = 0,
	cmt_buf: ?[*:0]u8 = null,
	cmt_buf_size: c_uint = 0,
	cmt_size: c_uint = 0,
	cmt_state: c_uint = 0,

	pub const open = Archive.open;
};

pub const OpenDataEx = extern struct {
	arc_name: ?[*:0]const u8 = null,
	arc_name_w: ?[*:0]const c_wchar = null,
	open_mode: OpenMode = .list,
	open_result: c_uint = 0,
	cmt_buf: ?[*:0]u8 = null,
	cmt_buf_size: c_uint = 0,
	cmt_size: c_uint = 0,
	cmt_state: c_uint = 0,
	flags: Flags = .{},
	callback: Callback = null,
	user_data: usize = 0,
	op_flags: OpFlags = .{},
	cmt_buf_w: ?[*:0]c_wchar = null,
	reserved: [25]c_uint = @splat(0),

	pub const Flags = packed struct(c_uint) {
		volume: bool = false,
		comment: bool = false,
		lock: bool = false,
		solid: bool = false,
		new_numbering: bool = false,
		signed: bool = false,
		recovery: bool = false,
		enc_headers: bool = false,
		first_volume: bool = false,
		_unused: @Int(.unsigned, @bitSizeOf(c_uint) - 9) = 0,
	};

	pub const OpFlags = packed struct(c_uint) {
		keep_broken: bool = false,
		_unused: @Int(.unsigned, @bitSizeOf(c_uint) - 1) = 0,
	};

	pub const open = Archive.openEx;
};

pub const Archive = opaque {
	pub fn open(data: *OpenData) Error!*Archive {
		return RAROpenArchive(data) orelse toError(data.open_result);
	}
	extern fn RAROpenArchive(*OpenData) ?*Archive;

	pub fn openEx(data: *OpenDataEx) Error!*Archive {
		return RAROpenArchiveEx(data) orelse toError(data.open_result);
	}
	extern fn RAROpenArchiveEx(*OpenDataEx) ?*Archive;

	pub fn close(self: *Archive) Error!void {
		const result = RARCloseArchive(self);
		if (result != success)
			return toError(result);
	}
	extern fn RARCloseArchive(*Archive) c_uint;

	pub fn processFile(
		self: *Archive,
		op: Operation,
		dest: ?[*:0]u8,
		name: ?[*:0]u8,
	) Error!void {
		const result = RARProcessFile(self, op, dest, name);
		if (result != success)
			return toError(result);
	}
	extern fn RARProcessFile(*Archive, Operation, ?[*:0]u8, ?[*:0]u8) c_uint;

	pub fn processFileW(
		self: *Archive,
		op: Operation,
		dest: ?[*:0]c_wchar,
		name: ?[*:0]c_wchar,
	) Error!void {
		const result = RARProcessFileW(self, op, dest, name);
		if (result != success)
			return toError(result);
	}
	extern fn RARProcessFileW(*Archive, Operation, ?[*:0]c_wchar, ?[*:0]c_wchar) c_uint;

	pub const setCallback = RARSetCallback;
	extern fn RARSetCallback(*Archive, cb: Callback, data: usize) void;

	pub const setChangeVolProc = RARSetChangeVolProc;
	extern fn RARSetChangeVolProc(*Archive, proc: ChangeVolProc) void;

	pub const setProcessDataProc = RARSetProcessDataProc;
	extern fn RARSetProcessDataProc(*Archive, proc: ProcessDataProc) void;

	pub const setPassword = RARSetPassword;
	extern fn RARSetPassword(*Archive, password: [*:0]u8) void;
};

pub const getDllVersion = RARGetDllVersion;
extern fn RARGetDllVersion() c_int;
