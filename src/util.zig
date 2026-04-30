const std = @import("std");
const builtin = @import("builtin");

pub fn readFile(path: []const u8, buf: []u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const len = file.readAll(buf) catch return null;
    return buf[0..len];
}

pub fn countDirEntries(path: []const u8) ?usize {
    var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch return null;
    defer dir.close();

    var count: usize = 0;
    var iter = dir.iterate();
    while (iter.next() catch return null) |entry| {
        if (entry.name.len > 0 and entry.name[0] != '.') count += 1;
    }
    return count;
}

pub fn countUserProfileBins() ?usize {
    var path_buf: [512]u8 = undefined;
    if (homePath(&path_buf, ".nix-profile/bin")) |path| {
        if (countDirEntries(path)) |count| return count;
    }
    return countDirEntries("/nix/var/nix/profiles/default/bin");
}

pub fn countHomeDirEntries(relative_path: []const u8) ?usize {
    var path_buf: [512]u8 = undefined;
    const path = homePath(&path_buf, relative_path) orelse return null;
    return countDirEntries(path);
}

pub fn homePath(buf: []u8, relative_path: []const u8) ?[]const u8 {
    var home_buf: [256]u8 = undefined;
    const home = envInto(&home_buf, "HOME") orelse return null;
    return std.fmt.bufPrint(buf, "{s}/{s}", .{ home, relative_path }) catch null;
}

pub fn envInto(buf: []u8, name: []const u8) ?[]const u8 {
    const allocator = std.heap.page_allocator;
    const owned = std.process.getEnvVarOwned(allocator, name) catch return null;
    defer allocator.free(owned);
    const n = @min(buf.len, owned.len);
    @memcpy(buf[0..n], owned[0..n]);
    return buf[0..n];
}

pub fn hostname(buf: *[64]u8) ?[]const u8 {
    if (builtin.os.tag == .linux) {
        const name = std.posix.gethostname(buf) catch return null;
        return trim(name);
    }
    return null;
}

pub fn setDefault(buf: []u8, len: *usize, value: []const u8) void {
    const n = @min(buf.len, value.len);
    @memcpy(buf[0..n], value[0..n]);
    len.* = n;
}

pub fn trim(value: []const u8) []const u8 {
    return std.mem.trim(u8, value, " \t\r\n");
}

pub fn unquote(value: []const u8) []const u8 {
    if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') return value[1 .. value.len - 1];
    return value;
}

pub fn basename(path: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '/')) |idx| return path[idx + 1 ..];
    return path;
}

pub fn writePadding(writer: anytype, count: usize) !void {
    for (0..count) |_| try writer.writeByte(' ');
}

pub fn displayWidth(text: []const u8) usize {
    var width: usize = 0;
    var i: usize = 0;
    while (i < text.len) {
        const size = std.unicode.utf8ByteSequenceLength(text[i]) catch 1;
        i += @min(size, text.len - i);
        width += 1;
    }
    return width;
}

pub fn formatBytes(bytes: u64) ByteFormat {
    return .{ .bytes = bytes };
}

const ByteFormat = struct {
    bytes: u64,

    pub fn format(self: ByteFormat, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const teb = 1024.0 * 1024.0 * 1024.0 * 1024.0;
        const gib = 1024.0 * 1024.0 * 1024.0;
        const value: f64 = @floatFromInt(self.bytes);
        if (value >= teb) return writer.print("{d:.2} TiB", .{value / teb});
        return writer.print("{d:.2} GiB", .{value / gib});
    }
};
