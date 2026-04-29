const std = @import("std");
const builtin = @import("builtin");

const FieldSize = 160;
const ArtWidth = 30;

const Art = [_][]const u8{
    "        .            .        ",
    "      .:;:.        .:;:.      ",
    "    .:;;;;:.    .:;;;;:.    ",
    "  .:;;;;;;;;:..:;;;;;;;;:.  ",
    " .:;;;;;;'        ';;;;;;:. ",
    " :;;;;;'   .-==-.   ';;;;;: ",
    " :;;;;   .'  __  '.   ;;;;: ",
    " ';;;;.  |  (__)  |  .;;;;' ",
    "  ';;;;:. '._/ _.' .:;;;;'  ",
    "    ';;;;:..____..:;;;;'    ",
    "      ';;;;;;;;;;;;;;'      ",
    "        '::;;;;;;::'        ",
};

const Style = struct {
    reset: []const u8,
    bold: []const u8,
    dim: []const u8,
    pink: []const u8,
    purple: []const u8,
    cyan: []const u8,
    blue: []const u8,
    orange: []const u8,
};

const neon = Style{
    .reset = "\x1b[0m",
    .bold = "\x1b[1m",
    .dim = "\x1b[2m",
    .pink = "\x1b[38;2;255;45;149m",
    .purple = "\x1b[38;2;157;78;221m",
    .cyan = "\x1b[38;2;0;245;255m",
    .blue = "\x1b[38;2;44;113;255m",
    .orange = "\x1b[38;2;255;176;59m",
};

const plain = Style{
    .reset = "",
    .bold = "",
    .dim = "",
    .pink = "",
    .purple = "",
    .cyan = "",
    .blue = "",
    .orange = "",
};

pub const SystemInfo = struct {
    user_host: [FieldSize]u8 = undefined,
    user_host_len: usize = 0,
    os: [FieldSize]u8 = undefined,
    os_len: usize = 0,
    kernel: [FieldSize]u8 = undefined,
    kernel_len: usize = 0,
    arch: [FieldSize]u8 = undefined,
    arch_len: usize = 0,
    uptime: [FieldSize]u8 = undefined,
    uptime_len: usize = 0,
    desktop: [FieldSize]u8 = undefined,
    desktop_len: usize = 0,
    wm: [FieldSize]u8 = undefined,
    wm_len: usize = 0,
    shell: [FieldSize]u8 = undefined,
    shell_len: usize = 0,
    cpu: [FieldSize]u8 = undefined,
    cpu_len: usize = 0,
    gpu: [FieldSize]u8 = undefined,
    gpu_len: usize = 0,
    memory: [FieldSize]u8 = undefined,
    memory_len: usize = 0,
    display: [FieldSize]u8 = undefined,
    display_len: usize = 0,
    packages: [FieldSize]u8 = undefined,
    packages_len: usize = 0,
    terminal: [FieldSize]u8 = undefined,
    terminal_len: usize = 0,

    fn userHost(self: *const SystemInfo) []const u8 {
        return self.user_host[0..self.user_host_len];
    }

    fn field(self: *const SystemInfo, comptime name: []const u8) []const u8 {
        return switch (std.meta.stringToEnum(enum { os, kernel, arch, uptime, desktop, wm, shell, cpu, gpu, memory, display, packages, terminal }, name).?) {
            .os => self.os[0..self.os_len],
            .kernel => self.kernel[0..self.kernel_len],
            .arch => self.arch[0..self.arch_len],
            .uptime => self.uptime[0..self.uptime_len],
            .desktop => self.desktop[0..self.desktop_len],
            .wm => self.wm[0..self.wm_len],
            .shell => self.shell[0..self.shell_len],
            .cpu => self.cpu[0..self.cpu_len],
            .gpu => self.gpu[0..self.gpu_len],
            .memory => self.memory[0..self.memory_len],
            .display => self.display[0..self.display_len],
            .packages => self.packages[0..self.packages_len],
            .terminal => self.terminal[0..self.terminal_len],
        };
    }
};

pub fn run() !void {
    var stdout_buffer: [8192]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var info = try collectSystemInfo();
    const use_color = wantsColor();
    try render(stdout, &info, use_color);
    try stdout.flush();
}

pub fn collectSystemInfo() !SystemInfo {
    var info = SystemInfo{};
    setDefault(&info.os, &info.os_len, "Unknown Linux");
    setDefault(&info.kernel, &info.kernel_len, "Unknown");
    setDefault(&info.arch, &info.arch_len, @tagName(builtin.cpu.arch));
    setDefault(&info.uptime, &info.uptime_len, "Unknown");
    setDefault(&info.desktop, &info.desktop_len, "Unknown");
    setDefault(&info.wm, &info.wm_len, "Unknown");
    setDefault(&info.shell, &info.shell_len, "Unknown");
    setDefault(&info.cpu, &info.cpu_len, "Unknown CPU");
    setDefault(&info.gpu, &info.gpu_len, "Unknown GPU");
    setDefault(&info.memory, &info.memory_len, "Unknown");
    setDefault(&info.display, &info.display_len, "Unknown");
    setDefault(&info.packages, &info.packages_len, "Unknown");
    setDefault(&info.terminal, &info.terminal_len, "Unknown");

    fillUserHost(&info);
    fillOs(&info);
    fillKernel(&info);
    fillUptime(&info);
    fillDesktop(&info);
    fillWm(&info);
    fillShell(&info);
    fillCpu(&info);
    fillGpu(&info);
    fillMemory(&info);
    fillDisplay(&info);
    fillPackages(&info);
    fillTerminal(&info);
    return info;
}

fn render(writer: anytype, info: *const SystemInfo, use_color: bool) !void {
    const s = if (use_color) neon else plain;
    const colors = [_][]const u8{ s.pink, s.purple, s.blue, s.cyan, s.blue, s.purple };

    try writer.print("\n{s}{s}{s}\n", .{ s.bold, s.pink, info.userHost() });
    try writer.print("{s}{s}\n\n", .{ s.dim, "retro terminal telemetry" });

    try row(writer, colors[0], Art[0], s, "OS", info.field("os"));
    try row(writer, colors[1], Art[1], s, "Kernel", info.field("kernel"));
    try row(writer, colors[2], Art[2], s, "Arch", info.field("arch"));
    try row(writer, colors[3], Art[3], s, "Uptime", info.field("uptime"));
    try row(writer, colors[4], Art[4], s, "Desktop", info.field("desktop"));
    try row(writer, colors[5], Art[5], s, "WM", info.field("wm"));
    try row(writer, colors[0], Art[6], s, "Shell", info.field("shell"));
    try row(writer, colors[1], Art[7], s, "CPU", info.field("cpu"));
    try row(writer, colors[2], Art[8], s, "GPU", info.field("gpu"));
    try row(writer, colors[3], Art[9], s, "Memory", info.field("memory"));
    try row(writer, colors[4], Art[10], s, "Display", info.field("display"));
    try row(writer, colors[5], Art[11], s, "Packages", info.field("packages"));
    try row(writer, colors[0], "", s, "Terminal", info.field("terminal"));

    if (use_color) {
        try writer.print("\n{s}palette {s}██{s}██{s}██{s}██{s}██{s}\n", .{ s.dim, s.pink, s.purple, s.blue, s.cyan, s.orange, s.reset });
    } else {
        try writer.writeAll("\npalette [pink] [purple] [blue] [cyan] [orange]\n");
    }
}

fn row(writer: anytype, art_color: []const u8, art: []const u8, s: Style, label: []const u8, value: []const u8) !void {
    try writer.print("{s}{s: <30}{s}  {s}{s: <10}{s} {s}\n", .{ art_color, art, s.reset, s.cyan, label, s.reset, value });
}

fn wantsColor() bool {
    if (std.process.hasEnvVarConstant("NO_COLOR")) return false;
    if (std.process.hasEnvVarConstant("CLICOLOR_FORCE")) return true;
    return true;
}

fn fillUserHost(info: *SystemInfo) void {
    var user_buf: [64]u8 = undefined;
    var host_buf: [64]u8 = undefined;
    const user = envInto(&user_buf, "USER") orelse envInto(&user_buf, "LOGNAME") orelse "pilot";
    const host = hostname(&host_buf) orelse "machine";
    const out = std.fmt.bufPrint(&info.user_host, "{s}@{s}", .{ user, host }) catch "pilot@machine";
    info.user_host_len = out.len;
}

fn fillOs(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = readFile("/etc/os-release", &buf) orelse return;
    const pretty = osReleaseValue(data, "PRETTY_NAME") orelse osReleaseValue(data, "NAME") orelse return;
    setDefault(&info.os, &info.os_len, pretty);
}

fn fillKernel(info: *SystemInfo) void {
    var os_buf: [64]u8 = undefined;
    var rel_buf: [128]u8 = undefined;
    const os_name = trim(readFile("/proc/sys/kernel/ostype", &os_buf) orelse "Linux");
    const release = trim(readFile("/proc/sys/kernel/osrelease", &rel_buf) orelse return);
    const out = std.fmt.bufPrint(&info.kernel, "{s} {s}", .{ os_name, release }) catch return;
    info.kernel_len = out.len;
}

fn fillUptime(info: *SystemInfo) void {
    var buf: [128]u8 = undefined;
    const data = readFile("/proc/uptime", &buf) orelse return;
    const formatted = formatUptime(data, &info.uptime) catch return;
    info.uptime_len = formatted.len;
}

fn fillDesktop(info: *SystemInfo) void {
    var buf: [160]u8 = undefined;
    const desktop = envInto(&buf, "XDG_CURRENT_DESKTOP") orelse envInto(&buf, "DESKTOP_SESSION") orelse return;
    setDefault(&info.desktop, &info.desktop_len, desktop);
}

fn fillWm(info: *SystemInfo) void {
    if (std.process.hasEnvVarConstant("HYPRLAND_INSTANCE_SIGNATURE")) {
        setDefault(&info.wm, &info.wm_len, "Hyprland");
        return;
    }
    if (std.process.hasEnvVarConstant("SWAYSOCK")) {
        setDefault(&info.wm, &info.wm_len, "sway");
        return;
    }
    if (std.process.hasEnvVarConstant("WAYLAND_DISPLAY")) {
        var desktop_buf: [160]u8 = undefined;
        const desktop = envInto(&desktop_buf, "XDG_CURRENT_DESKTOP") orelse "Wayland compositor";
        setDefault(&info.wm, &info.wm_len, desktop);
        return;
    }
    if (std.process.hasEnvVarConstant("DISPLAY")) {
        setDefault(&info.wm, &info.wm_len, "X11 session");
    }
}

fn fillShell(info: *SystemInfo) void {
    var buf: [160]u8 = undefined;
    const shell = envInto(&buf, "SHELL") orelse return;
    setDefault(&info.shell, &info.shell_len, basename(shell));
}

fn fillCpu(info: *SystemInfo) void {
    var buf: [16384]u8 = undefined;
    const data = readFile("/proc/cpuinfo", &buf) orelse return;
    const model = cpuModel(data) orelse return;
    setDefault(&info.cpu, &info.cpu_len, model);
}

fn fillGpu(info: *SystemInfo) void {
    var dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return;
    defer dir.close();

    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        if (!std.mem.startsWith(u8, entry.name, "card")) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| continue;

        var path_buf: [256]u8 = undefined;
        const vendor_path = std.fmt.bufPrint(&path_buf, "/sys/class/drm/{s}/device/vendor", .{entry.name}) catch continue;
        var vendor_buf: [32]u8 = undefined;
        const vendor_id = trim(readFile(vendor_path, &vendor_buf) orelse continue);

        var device_path_buf: [256]u8 = undefined;
        const device_path = std.fmt.bufPrint(&device_path_buf, "/sys/class/drm/{s}/device/device", .{entry.name}) catch continue;
        var device_buf: [32]u8 = undefined;
        const device_id = trim(readFile(device_path, &device_buf) orelse "");

        var subsystem_vendor_path_buf: [256]u8 = undefined;
        const subsystem_vendor_path = std.fmt.bufPrint(&subsystem_vendor_path_buf, "/sys/class/drm/{s}/device/subsystem_vendor", .{entry.name}) catch continue;
        var subsystem_vendor_buf: [32]u8 = undefined;
        const subsystem_vendor_id = trim(readFile(subsystem_vendor_path, &subsystem_vendor_buf) orelse "");

        var subsystem_device_path_buf: [256]u8 = undefined;
        const subsystem_device_path = std.fmt.bufPrint(&subsystem_device_path_buf, "/sys/class/drm/{s}/device/subsystem_device", .{entry.name}) catch continue;
        var subsystem_device_buf: [32]u8 = undefined;
        const subsystem_device_id = trim(readFile(subsystem_device_path, &subsystem_device_buf) orelse "");

        var uevent_path_buf: [256]u8 = undefined;
        const uevent_path = std.fmt.bufPrint(&uevent_path_buf, "/sys/class/drm/{s}/device/uevent", .{entry.name}) catch continue;
        var uevent_buf: [1024]u8 = undefined;
        const uevent = readFile(uevent_path, &uevent_buf) orelse "";
        const driver = ueventValue(uevent, "DRIVER") orelse "DRM";

        var model_buf: [FieldSize]u8 = undefined;
        const model = gpuModelName(vendor_id, device_id, subsystem_vendor_id, subsystem_device_id, &model_buf) orelse gpuVendorName(vendor_id);
        const out = std.fmt.bufPrint(&info.gpu, "{s} ({s})", .{ model, driver }) catch return;
        info.gpu_len = out.len;
        return;
    }
}

fn fillMemory(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = readFile("/proc/meminfo", &buf) orelse return;
    const formatted = formatMemory(data, &info.memory) catch return;
    info.memory_len = formatted.len;
}

fn fillDisplay(info: *SystemInfo) void {
    var dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return;
    defer dir.close();

    var iter = dir.iterate();
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| {} else continue;

        var status_path_buf: [256]u8 = undefined;
        const status_path = std.fmt.bufPrint(&status_path_buf, "/sys/class/drm/{s}/status", .{entry.name}) catch continue;
        var status_buf: [32]u8 = undefined;
        if (!std.mem.eql(u8, trim(readFile(status_path, &status_buf) orelse continue), "connected")) continue;

        var modes_path_buf: [256]u8 = undefined;
        const modes_path = std.fmt.bufPrint(&modes_path_buf, "/sys/class/drm/{s}/modes", .{entry.name}) catch continue;
        var modes_buf: [256]u8 = undefined;
        const modes = trim(readFile(modes_path, &modes_buf) orelse continue);
        const first_line_end = std.mem.indexOfScalar(u8, modes, '\n') orelse modes.len;
        const mode = modes[0..first_line_end];
        const out = std.fmt.bufPrint(&info.display, "{s} @ {s}", .{ mode, entry.name }) catch return;
        info.display_len = out.len;
        return;
    }
}

fn fillPackages(info: *SystemInfo) void {
    if (countDirEntries("/run/current-system/sw/bin") orelse countDirEntries("/nix/var/nix/profiles/default/bin")) |count| {
        const out = std.fmt.bufPrint(&info.packages, "{} system binaries", .{count}) catch return;
        info.packages_len = out.len;
        return;
    }

    const usr_bins = countDirEntries("/usr/bin") orelse return;
    const out = std.fmt.bufPrint(&info.packages, "{} usr binaries", .{usr_bins}) catch return;
    info.packages_len = out.len;
}

fn fillTerminal(info: *SystemInfo) void {
    var term_buf: [64]u8 = undefined;
    var session_buf: [64]u8 = undefined;
    const term = envInto(&term_buf, "TERM") orelse "tty";
    const session = envInto(&session_buf, "XDG_SESSION_TYPE") orelse "console";
    const out = std.fmt.bufPrint(&info.terminal, "{s} / {s}", .{ term, session }) catch return;
    info.terminal_len = out.len;
}

fn readFile(path: []const u8, buf: []u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();
    const len = file.readAll(buf) catch return null;
    return buf[0..len];
}

fn countDirEntries(path: []const u8) ?usize {
    var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch return null;
    defer dir.close();

    var count: usize = 0;
    var iter = dir.iterate();
    while (iter.next() catch return null) |entry| {
        if (entry.name.len > 0 and entry.name[0] != '.') count += 1;
    }
    return count;
}

fn envInto(buf: []u8, name: []const u8) ?[]const u8 {
    const allocator = std.heap.page_allocator;
    const owned = std.process.getEnvVarOwned(allocator, name) catch return null;
    defer allocator.free(owned);
    const n = @min(buf.len, owned.len);
    @memcpy(buf[0..n], owned[0..n]);
    return buf[0..n];
}

fn hostname(buf: *[64]u8) ?[]const u8 {
    if (builtin.os.tag == .linux) {
        const name = std.posix.gethostname(buf) catch return null;
        return trim(name);
    }
    return null;
}

fn osReleaseValue(data: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (line.len <= key.len or line[key.len] != '=') continue;
        return unquote(trim(line[key.len + 1 ..]));
    }
    return null;
}

fn ueventValue(data: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (line.len <= key.len or line[key.len] != '=') continue;
        return trim(line[key.len + 1 ..]);
    }
    return null;
}

fn gpuVendorName(vendor_id: []const u8) []const u8 {
    if (std.mem.eql(u8, vendor_id, "0x1002")) return "AMD Radeon";
    if (std.mem.eql(u8, vendor_id, "0x10de")) return "NVIDIA GeForce";
    if (std.mem.eql(u8, vendor_id, "0x8086")) return "Intel Graphics";
    if (std.mem.eql(u8, vendor_id, "0x1a03")) return "ASPEED Graphics";
    if (std.mem.eql(u8, vendor_id, "0x1234")) return "QEMU Virtual GPU";
    return "PCI GPU";
}

fn gpuModelName(vendor_id: []const u8, device_id: []const u8, subsystem_vendor_id: []const u8, subsystem_device_id: []const u8, buf: []u8) ?[]const u8 {
    const vendor = normalizePciId(vendor_id);
    const device = normalizePciId(device_id);
    const subsystem_vendor = normalizePciId(subsystem_vendor_id);
    const subsystem_device = normalizePciId(subsystem_device_id);

    const paths = [_][]const u8{
        "/usr/share/hwdata/pci.ids",
        "/usr/share/misc/pci.ids",
        "/usr/share/pci.ids",
        "/run/current-system/sw/share/hwdata/pci.ids",
        "/run/current-system/sw/share/pci.ids",
    };

    for (paths) |path| {
        if (pciIdsLookup(path, vendor, device, subsystem_vendor, subsystem_device, buf)) |model| return model;
    }

    return builtinGpuModel(vendor, device, subsystem_vendor, subsystem_device, buf);
}

fn pciIdsLookup(path: []const u8, vendor: [4]u8, device: [4]u8, subsystem_vendor: [4]u8, subsystem_device: [4]u8, buf: []u8) ?[]const u8 {
    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();

    var read_buf: [2 * 1024 * 1024]u8 = undefined;
    const len = file.readAll(&read_buf) catch return null;
    return parsePciIds(read_buf[0..len], vendor, device, subsystem_vendor, subsystem_device, buf);
}

fn parsePciIds(data: []const u8, vendor: [4]u8, device: [4]u8, subsystem_vendor: [4]u8, subsystem_device: [4]u8, buf: []u8) ?[]const u8 {
    var in_vendor = false;
    var in_device = false;
    var device_name: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, data, '\n');

    while (lines.next()) |line| {
        if (line.len == 0 or line[0] == '#') continue;

        if (line[0] != '\t') {
            in_vendor = line.len >= 4 and asciiIdEql(line[0..4], &vendor);
            in_device = false;
            if (device_name != null and !in_vendor) break;
            continue;
        }

        if (!in_vendor) continue;

        if (line.len >= 6 and line[1] != '\t') {
            in_device = asciiIdEql(line[1..5], &device);
            if (in_device) device_name = trim(line[5..]);
            continue;
        }

        if (!in_device or line.len < 11 or line[1] != '\t') continue;
        if (asciiIdEql(line[2..6], &subsystem_vendor) and asciiIdEql(line[7..11], &subsystem_device)) {
            const sub_name = trim(line[11..]);
            const out = std.fmt.bufPrint(buf, "{s}", .{sub_name}) catch return null;
            return out;
        }
    }

    if (device_name) |name| {
        const out = std.fmt.bufPrint(buf, "{s}", .{name}) catch return null;
        return out;
    }
    return null;
}

fn builtinGpuModel(vendor: [4]u8, device: [4]u8, subsystem_vendor: [4]u8, subsystem_device: [4]u8, buf: []u8) ?[]const u8 {
    if (asciiIdEql(&vendor, "1002") and asciiIdEql(&device, "731f")) {
        if (asciiIdEql(&subsystem_vendor, "1682") and asciiIdEql(&subsystem_device, "5701")) {
            return std.fmt.bufPrint(buf, "XFX RX 5700 XT RAW II", .{}) catch null;
        }
        return std.fmt.bufPrint(buf, "Navi 10 [Radeon RX 5600 OEM/5600 XT / 5700/5700 XT]", .{}) catch null;
    }
    return null;
}

fn normalizePciId(value: []const u8) [4]u8 {
    var out = [_]u8{ '0', '0', '0', '0' };
    const trimmed = trim(value);
    const id = if (std.mem.startsWith(u8, trimmed, "0x") or std.mem.startsWith(u8, trimmed, "0X")) trimmed[2..] else trimmed;
    const n = @min(out.len, id.len);
    for (0..n) |i| out[i] = std.ascii.toLower(id[i]);
    return out;
}

fn asciiIdEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        if (std.ascii.toLower(left) != std.ascii.toLower(right)) return false;
    }
    return true;
}

fn cpuModel(data: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "model name")) {
            if (std.mem.indexOfScalar(u8, line, ':')) |idx| return trim(line[idx + 1 ..]);
        }
        if (std.mem.startsWith(u8, line, "Hardware")) {
            if (std.mem.indexOfScalar(u8, line, ':')) |idx| return trim(line[idx + 1 ..]);
        }
    }
    return null;
}

fn formatMemory(data: []const u8, buf: []u8) ![]const u8 {
    const total_kb = meminfoKb(data, "MemTotal") orelse return error.MissingMemory;
    const available_kb = meminfoKb(data, "MemAvailable") orelse return error.MissingMemory;
    const used_mib = (total_kb - available_kb) / 1024;
    const total_mib = total_kb / 1024;
    const pct = if (total_kb == 0) 0 else ((total_kb - available_kb) * 100) / total_kb;
    return std.fmt.bufPrint(buf, "{} MiB / {} MiB ({}%)", .{ used_mib, total_mib, pct });
}

fn meminfoKb(data: []const u8, key: []const u8) ?u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (std.mem.indexOfScalar(u8, line, ':')) |idx| {
            const rest = trim(line[idx + 1 ..]);
            const end = std.mem.indexOfScalar(u8, rest, ' ') orelse rest.len;
            return std.fmt.parseInt(u64, rest[0..end], 10) catch null;
        }
    }
    return null;
}

fn formatUptime(data: []const u8, buf: []u8) ![]const u8 {
    const first = data[0 .. std.mem.indexOfScalar(u8, data, ' ') orelse data.len];
    const dot = std.mem.indexOfScalar(u8, first, '.') orelse first.len;
    var seconds = try std.fmt.parseInt(u64, first[0..dot], 10);
    const days = seconds / 86400;
    seconds %= 86400;
    const hours = seconds / 3600;
    seconds %= 3600;
    const minutes = seconds / 60;

    if (days > 0) return std.fmt.bufPrint(buf, "{}d {}h {}m", .{ days, hours, minutes });
    if (hours > 0) return std.fmt.bufPrint(buf, "{}h {}m", .{ hours, minutes });
    return std.fmt.bufPrint(buf, "{}m", .{minutes});
}

fn setDefault(buf: []u8, len: *usize, value: []const u8) void {
    const n = @min(buf.len, value.len);
    @memcpy(buf[0..n], value[0..n]);
    len.* = n;
}

fn trim(value: []const u8) []const u8 {
    return std.mem.trim(u8, value, " \t\r\n");
}

fn unquote(value: []const u8) []const u8 {
    if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') return value[1 .. value.len - 1];
    return value;
}

fn basename(path: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '/')) |idx| return path[idx + 1 ..];
    return path;
}

test "parse os-release quoted value" {
    const data = "NAME=ArcadeOS\nPRETTY_NAME=\"ArcadeOS Neon 1.0\"\n";
    try std.testing.expectEqualStrings("ArcadeOS Neon 1.0", osReleaseValue(data, "PRETTY_NAME").?);
}

test "format meminfo usage" {
    const data = "MemTotal:       8192000 kB\nMemAvailable:   4096000 kB\n";
    var buf: [FieldSize]u8 = undefined;
    try std.testing.expectEqualStrings("4000 MiB / 8000 MiB (50%)", try formatMemory(data, &buf));
}

test "format uptime" {
    var buf: [FieldSize]u8 = undefined;
    try std.testing.expectEqualStrings("1d 1h 1m", try formatUptime("90060.42 0.00", &buf));
}

test "parse cpu model" {
    const data = "processor   : 0\nmodel name  : Neon Turbo 9000\n";
    try std.testing.expectEqualStrings("Neon Turbo 9000", cpuModel(data).?);
}

test "parse pci ids subsystem gpu model" {
    const data = "1002  Advanced Micro Devices, Inc. [AMD/ATI]\n\t731f  Navi 10 [Radeon RX 5600 OEM/5600 XT / 5700/5700 XT]\n\t\t1682 5701  RX 5700 XT RAW II\n10de  NVIDIA Corporation\n";
    var buf: [FieldSize]u8 = undefined;
    try std.testing.expectEqualStrings("RX 5700 XT RAW II", parsePciIds(data, normalizePciId("0x1002"), normalizePciId("0x731f"), normalizePciId("0x1682"), normalizePciId("0x5701"), &buf).?);
}
