const c = @import("cdef");
const c_wchar = c.wchar_t;

pub const Callback = fn (CallbackMsg, usize, usize, usize) callconv(.c) ErrorCode;
pub const ChangeVolProc = fn (?[*:0]u8, VolMode) callconv(.c) c_uint;
pub const ProcessDataProc = fn (?[*:0]u8, c_int) callconv(.c) c_uint;

pub const dll_version = c.RAR_DLL_VERSION;

const success = c.ERAR_SUCCESS;
const end_of_archive = c.ERAR_END_ARCHIVE;
const err_offset = c.ERAR_NO_MEMORY;

pub const ErrorCode = enum(c_uint) {
	success = c.ERAR_SUCCESS,
	no_memory = c.ERAR_NO_MEMORY,
	bad_data = c.ERAR_BAD_DATA,
	bad_archive = c.ERAR_BAD_ARCHIVE,
	unknown_format = c.ERAR_UNKNOWN_FORMAT,
	eopen = c.ERAR_EOPEN,
	ecreate = c.ERAR_ECREATE,
	eclose = c.ERAR_ECLOSE,
	eread = c.ERAR_EREAD,
	ewrite = c.ERAR_EWRITE,
	small_buf = c.ERAR_SMALL_BUF,
	unknown = c.ERAR_UNKNOWN,
	missing_password = c.ERAR_MISSING_PASSWORD,
	ereference = c.ERAR_EREFERENCE,
	bad_password = c.ERAR_BAD_PASSWORD,
	large_dict = c.ERAR_LARGE_DICT,
};

pub const Error = error {
	OutOfMemory,
	BadData,
	BadArchive,
	UnknownFormat,
	OpenFail,
	CreateFail,
	CloseFail,
	ReadFail,
	WriteFail,
	SmallBuffer,
	Unknown,
	MissingPassword,
	BadReference,
	BadPassword,
	LargeDictionary,
};

const error_list = [_]Error{
	error.OutOfMemory,
	error.BadData,
	error.BadArchive,
	error.UnknownFormat,
	error.OpenFail,
	error.CreateFail,
	error.CloseFail,
	error.ReadFail,
	error.WriteFail,
	error.SmallBuffer,
	error.Unknown,
	error.MissingPassword,
	error.BadReference,
	error.BadPassword,
	error.LargeDictionary,
};

fn toError(i: c_int) Error {
	return error_list[@as(usize, @intCast(i)) - err_offset];
}

pub const OpenMode = enum(c_uint) {
	list = 0,
	extract = 1,
	list_incsplit = 2,
};

pub const Operation = enum(c_int) {
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
	flags: HeaderFlags = .{},
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

	pub fn read(self: *Header, arc: *Archive) Error!bool {
		return switch (c.RARReadHeader(arc, @ptrCast(self))) {
			success => true,
			end_of_archive => false,
			else => |res| toError(res),
		};
	}
};

pub const HeaderEx = extern struct {
	arc_name: [1023:0]u8 = @splat(0),
	arc_name_w: [1023:0]c_wchar = @splat(0),
	file_name: [1023:0]u8 = @splat(0),
	file_name_w: [1023:0]c_wchar = @splat(0),
	flags: HeaderFlags = .{},
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

	pub fn read(self: *HeaderEx, arc: *Archive) Error!bool {
		return switch (c.RARReadHeaderEx(arc, self)) {
			success => true,
			end_of_archive => false,
			else => |res| toError(res),
		};
	}
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
	callback: ?*const Callback = null,
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
		return if (c.RAROpenArchive(@ptrCast(data))) |arc|
			@ptrCast(arc)
		else toError(@intCast(data.open_result));
	}

	pub fn openEx(data: *OpenDataEx) Error!*Archive {
		return if (c.RAROpenArchiveEx(@ptrCast(data))) |arc|
			@ptrCast(arc)
		else toError(@intCast(data.open_result));
	}

	pub fn close(self: *Archive) Error!void {
		const result = c.RARCloseArchive(self);
		if (result != success)
			return toError(result);
	}

	pub fn processFile(
		self: *Archive,
		op: Operation,
		dest: ?[*:0]u8,
		name: ?[*:0]u8,
	) Error!void {
		const result = c.RARProcessFile(self, @intFromEnum(op), dest, name);
		if (result != success)
			return toError(result);
	}

	pub fn processFileW(
		self: *Archive,
		op: Operation,
		dest: ?[*:0]c_wchar,
		name: ?[*:0]c_wchar,
	) Error!void {
		const result = c.RARProcessFileW(self, @intFromEnum(op), dest, name);
		if (result != success)
			return toError(result);
	}

	pub fn setCallback(self: *Archive, cb: ?*const Callback, data: usize) void {
		c.RARSetCallback(self, @ptrCast(cb), data);
	}

	pub fn setChangeVolProc(self: *Archive, proc: ?*const ChangeVolProc) void {
		c.RARSetChangeVolProc(self, @ptrCast(proc));
	}

	pub fn setProcessDataProc(self: *Archive, proc: ?*const ProcessDataProc) void {
		c.RARSetProcessDataProc(self, @ptrCast(proc));
	}

	pub fn setPassword(self: *Archive, password: [*:0]u8) void {
		c.RARSetPassword(self, password);
	}
};

pub fn getDllVersion() c_int {
	return c.RARGetDllVersion();
}
