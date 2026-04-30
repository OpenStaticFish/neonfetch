const std = @import("std");
const builtin = @import("builtin");
const types = @import("types.zig");
const util = @import("util.zig");

const FieldSize = types.FieldSize;
const SystemInfo = types.SystemInfo;

const LinuxStatfs = extern struct {
    f_type: isize,
    f_bsize: isize,
    f_blocks: u64,
    f_bfree: u64,
    f_bavail: u64,
    f_files: u64,
    f_ffree: u64,
    f_fsid: [2]i32,
    f_namelen: isize,
    f_frsize: isize,
    f_flags: isize,
    f_spare: [4]isize,
};

pub fn collectSystemInfo() !SystemInfo {
    var info = SystemInfo{};
    util.setDefault(&info.os, &info.os_len, "Unknown Linux");
    util.setDefault(&info.os_id, &info.os_id_len, "linux");
    util.setDefault(&info.host, &info.host_len, "Unknown");
    util.setDefault(&info.kernel, &info.kernel_len, "Unknown");
    util.setDefault(&info.arch, &info.arch_len, @tagName(builtin.cpu.arch));
    util.setDefault(&info.uptime, &info.uptime_len, "Unknown");
    util.setDefault(&info.desktop, &info.desktop_len, "Unknown");
    util.setDefault(&info.wm, &info.wm_len, "Unknown");
    util.setDefault(&info.shell, &info.shell_len, "Unknown");
    util.setDefault(&info.cpu, &info.cpu_len, "Unknown CPU");
    util.setDefault(&info.gpu, &info.gpu_len, "Unknown GPU");
    util.setDefault(&info.gpu2, &info.gpu2_len, "");
    util.setDefault(&info.memory, &info.memory_len, "Unknown");
    util.setDefault(&info.swap, &info.swap_len, "Unknown");
    util.setDefault(&info.display, &info.display_len, "Unknown");
    util.setDefault(&info.display2, &info.display2_len, "");
    util.setDefault(&info.display3, &info.display3_len, "");
    util.setDefault(&info.packages, &info.packages_len, "Unknown");
    util.setDefault(&info.theme, &info.theme_len, "Unknown");
    util.setDefault(&info.icons, &info.icons_len, "Unknown");
    util.setDefault(&info.font, &info.font_len, "Unknown");
    util.setDefault(&info.cursor, &info.cursor_len, "Unknown");
    util.setDefault(&info.terminal, &info.terminal_len, "Unknown");
    util.setDefault(&info.disk, &info.disk_len, "Unknown");
    util.setDefault(&info.disk2, &info.disk2_len, "");
    util.setDefault(&info.disk3, &info.disk3_len, "");
    util.setDefault(&info.local_ip, &info.local_ip_len, "Unknown");
    util.setDefault(&info.locale, &info.locale_len, "Unknown");

    fillUserHost(&info);
    fillOs(&info);
    fillHost(&info);
    fillKernel(&info);
    fillUptime(&info);
    fillDesktop(&info);
    fillWm(&info);
    fillShell(&info);
    fillCpu(&info);
    fillGpu(&info);
    fillMemory(&info);
    fillSwap(&info);
    fillDisplay(&info);
    fillPackages(&info);
    fillGtkSettings(&info);
    fillTerminal(&info);
    fillDisks(&info);
    fillLocalIp(&info);
    fillLocale(&info);
    return info;
}

fn fillUserHost(info: *SystemInfo) void {
    var user_buf: [64]u8 = undefined;
    var host_buf: [64]u8 = undefined;
    const user = util.envInto(&user_buf, "USER") orelse util.envInto(&user_buf, "LOGNAME") orelse "pilot";
    const host = util.hostname(&host_buf) orelse "machine";
    const out = std.fmt.bufPrint(&info.user_host, "{s}@{s}", .{ user, host }) catch "pilot@machine";
    info.user_host_len = out.len;
}

fn fillOs(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = util.readFile("/etc/os-release", &buf) orelse return;

    if (osReleaseValue(data, "PRETTY_NAME") orelse osReleaseValue(data, "NAME")) |pretty| {
        util.setDefault(&info.os, &info.os_len, pretty);
    }

    if (osReleaseValue(data, "ID")) |id| {
        util.setDefault(&info.os_id, &info.os_id_len, id);
    }
}

fn fillHost(info: *SystemInfo) void {
    var buf: [FieldSize]u8 = undefined;
    const product = util.trim(util.readFile("/sys/devices/virtual/dmi/id/product_name", &buf) orelse return);
    if (product.len > 0) util.setDefault(&info.host, &info.host_len, product);
}

fn fillKernel(info: *SystemInfo) void {
    var os_buf: [64]u8 = undefined;
    var rel_buf: [128]u8 = undefined;
    const os_name = util.trim(util.readFile("/proc/sys/kernel/ostype", &os_buf) orelse "Linux");
    const release = util.trim(util.readFile("/proc/sys/kernel/osrelease", &rel_buf) orelse return);
    const out = std.fmt.bufPrint(&info.kernel, "{s} {s}", .{ os_name, release }) catch return;
    info.kernel_len = out.len;
}

fn fillUptime(info: *SystemInfo) void {
    var buf: [128]u8 = undefined;
    const data = util.readFile("/proc/uptime", &buf) orelse return;
    const formatted = formatUptime(data, &info.uptime) catch return;
    info.uptime_len = formatted.len;
}

fn fillDesktop(info: *SystemInfo) void {
    var buf: [160]u8 = undefined;
    const desktop = util.envInto(&buf, "XDG_CURRENT_DESKTOP") orelse util.envInto(&buf, "DESKTOP_SESSION") orelse return;
    util.setDefault(&info.desktop, &info.desktop_len, desktop);
}

fn fillWm(info: *SystemInfo) void {
    if (std.process.hasEnvVarConstant("HYPRLAND_INSTANCE_SIGNATURE")) {
        util.setDefault(&info.wm, &info.wm_len, "Hyprland");
        return;
    }
    if (std.process.hasEnvVarConstant("SWAYSOCK")) {
        util.setDefault(&info.wm, &info.wm_len, "sway");
        return;
    }
    if (std.process.hasEnvVarConstant("WAYLAND_DISPLAY")) {
        var desktop_buf: [160]u8 = undefined;
        const desktop = util.envInto(&desktop_buf, "XDG_CURRENT_DESKTOP") orelse "Wayland compositor";
        util.setDefault(&info.wm, &info.wm_len, desktop);
        return;
    }
    if (std.process.hasEnvVarConstant("DISPLAY")) {
        util.setDefault(&info.wm, &info.wm_len, "X11 session");
    }
}

fn fillShell(info: *SystemInfo) void {
    var buf: [160]u8 = undefined;
    const shell = util.envInto(&buf, "SHELL") orelse return;
    util.setDefault(&info.shell, &info.shell_len, util.basename(shell));
}

fn fillCpu(info: *SystemInfo) void {
    var buf: [65536]u8 = undefined;
    const data = util.readFile("/proc/cpuinfo", &buf) orelse return;
    const model = cpuModel(data) orelse return;
    const clean_model = cleanCpuModel(model);
    const cores = cpuThreadCount(data);
    const mhz = cpuMaxMhz(data);
    const out = if (mhz) |speed|
        std.fmt.bufPrint(&info.cpu, "{s} ({}) @ {d:.2} GHz", .{ clean_model, cores, speed / 1000.0 }) catch return
    else
        std.fmt.bufPrint(&info.cpu, "{s} ({})", .{ clean_model, cores }) catch return;
    info.cpu_len = out.len;
}

fn fillGpu(info: *SystemInfo) void {
    var dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return;
    defer dir.close();

    var iter = dir.iterate();
    var count: usize = 0;
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        if (!std.mem.startsWith(u8, entry.name, "card")) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| continue;

        var path_buf: [256]u8 = undefined;
        const vendor_path = std.fmt.bufPrint(&path_buf, "/sys/class/drm/{s}/device/vendor", .{entry.name}) catch continue;
        var vendor_buf: [32]u8 = undefined;
        const vendor_id = util.trim(util.readFile(vendor_path, &vendor_buf) orelse continue);

        var device_path_buf: [256]u8 = undefined;
        const device_path = std.fmt.bufPrint(&device_path_buf, "/sys/class/drm/{s}/device/device", .{entry.name}) catch continue;
        var device_buf: [32]u8 = undefined;
        const device_id = util.trim(util.readFile(device_path, &device_buf) orelse "");

        var subsystem_vendor_path_buf: [256]u8 = undefined;
        const subsystem_vendor_path = std.fmt.bufPrint(&subsystem_vendor_path_buf, "/sys/class/drm/{s}/device/subsystem_vendor", .{entry.name}) catch continue;
        var subsystem_vendor_buf: [32]u8 = undefined;
        const subsystem_vendor_id = util.trim(util.readFile(subsystem_vendor_path, &subsystem_vendor_buf) orelse "");

        var subsystem_device_path_buf: [256]u8 = undefined;
        const subsystem_device_path = std.fmt.bufPrint(&subsystem_device_path_buf, "/sys/class/drm/{s}/device/subsystem_device", .{entry.name}) catch continue;
        var subsystem_device_buf: [32]u8 = undefined;
        const subsystem_device_id = util.trim(util.readFile(subsystem_device_path, &subsystem_device_buf) orelse "");

        var uevent_path_buf: [256]u8 = undefined;
        const uevent_path = std.fmt.bufPrint(&uevent_path_buf, "/sys/class/drm/{s}/device/uevent", .{entry.name}) catch continue;
        var uevent_buf: [1024]u8 = undefined;
        const uevent = util.readFile(uevent_path, &uevent_buf) orelse "";
        const driver = ueventValue(uevent, "DRIVER") orelse "DRM";

        var model_buf: [FieldSize]u8 = undefined;
        const model = gpuModelName(vendor_id, device_id, subsystem_vendor_id, subsystem_device_id, &model_buf) orelse gpuVendorName(vendor_id);
        const class = if (std.mem.eql(u8, driver, "amdgpu") and !std.mem.eql(u8, device_id, "0x731f")) " [Integrated]" else " [Discrete]";
        var out_buf: [FieldSize]u8 = undefined;
        const out = std.fmt.bufPrint(&out_buf, "{s}{s}", .{ model, class }) catch return;
        switch (count) {
            0 => util.setDefault(&info.gpu, &info.gpu_len, out),
            1 => util.setDefault(&info.gpu2, &info.gpu2_len, out),
            else => break,
        }
        count += 1;
    }
}

fn fillMemory(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = util.readFile("/proc/meminfo", &buf) orelse return;
    const formatted = formatMemory(data, &info.memory) catch return;
    info.memory_len = formatted.len;
}

fn fillSwap(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = util.readFile("/proc/meminfo", &buf) orelse return;
    const total = meminfoKb(data, "SwapTotal") orelse return;
    const free = meminfoKb(data, "SwapFree") orelse return;
    const used = total - free;
    const pct = if (total == 0) 0 else (used * 100) / total;
    const used_gib: f64 = @as(f64, @floatFromInt(used)) / 1048576.0;
    const total_gib: f64 = @as(f64, @floatFromInt(total)) / 1048576.0;
    const out = std.fmt.bufPrint(&info.swap, "{d:.2} GiB / {d:.2} GiB ({}%)", .{ used_gib, total_gib, pct }) catch return;
    info.swap_len = out.len;
}

fn fillDisplay(info: *SystemInfo) void {
    var dir = std.fs.openDirAbsolute("/sys/class/drm", .{ .iterate = true }) catch return;
    defer dir.close();

    var iter = dir.iterate();
    var count: usize = 0;
    while (iter.next() catch null) |entry| {
        if (entry.kind != .directory and entry.kind != .sym_link) continue;
        if (std.mem.indexOfScalar(u8, entry.name, '-')) |_| {} else continue;

        var status_path_buf: [256]u8 = undefined;
        const status_path = std.fmt.bufPrint(&status_path_buf, "/sys/class/drm/{s}/status", .{entry.name}) catch continue;
        var status_buf: [32]u8 = undefined;
        if (!std.mem.eql(u8, util.trim(util.readFile(status_path, &status_buf) orelse continue), "connected")) continue;

        var modes_path_buf: [256]u8 = undefined;
        const modes_path = std.fmt.bufPrint(&modes_path_buf, "/sys/class/drm/{s}/modes", .{entry.name}) catch continue;
        var modes_buf: [256]u8 = undefined;
        const modes = util.trim(util.readFile(modes_path, &modes_buf) orelse continue);
        const first_line_end = std.mem.indexOfScalar(u8, modes, '\n') orelse modes.len;
        const mode = modes[0..first_line_end];
        var edid_path_buf: [256]u8 = undefined;
        const edid_path = std.fmt.bufPrint(&edid_path_buf, "/sys/class/drm/{s}/edid", .{entry.name}) catch continue;
        var edid_buf: [512]u8 = undefined;
        const edid = util.readFile(edid_path, &edid_buf) orelse "";
        var name_buf: [32]u8 = undefined;
        const name = edidDisplayName(edid, &name_buf) orelse entry.name;
        const inches = edidDiagonalInches(edid);
        const hz = edidRefreshRate(edid);
        var out_buf: [FieldSize]u8 = undefined;
        const out = if (inches != null and hz != null)
            std.fmt.bufPrint(&out_buf, "({s}): {s} in {}\", {} Hz [External]", .{ name, mode, inches.?, hz.? }) catch return
        else
            std.fmt.bufPrint(&out_buf, "({s}): {s} [External]", .{ name, mode }) catch return;
        switch (count) {
            0 => util.setDefault(&info.display, &info.display_len, out),
            1 => util.setDefault(&info.display2, &info.display2_len, out),
            2 => util.setDefault(&info.display3, &info.display3_len, out),
            else => break,
        }
        count += 1;
    }
}

fn fillPackages(info: *SystemInfo) void {
    const nix_system = util.countDirEntries("/run/current-system/sw/bin") orelse 0;
    const nix_user = util.countUserProfileBins() orelse 0;
    const flatpak_system = util.countDirEntries("/var/lib/flatpak/app") orelse 0;
    const flatpak_user = util.countHomeDirEntries(".local/share/flatpak/app") orelse 0;

    if (nix_system + nix_user + flatpak_system + flatpak_user > 0) {
        const out = std.fmt.bufPrint(&info.packages, "{} (nix-system), {} (nix-user), {} (flatpak-system), {} (flatpak-user)", .{ nix_system, nix_user, flatpak_system, flatpak_user }) catch return;
        info.packages_len = out.len;
        return;
    }

    const usr_bins = util.countDirEntries("/usr/bin") orelse return;
    const out = std.fmt.bufPrint(&info.packages, "{} usr binaries", .{usr_bins}) catch return;
    info.packages_len = out.len;
}

fn fillGtkSettings(info: *SystemInfo) void {
    var path_buf: [512]u8 = undefined;
    const path = util.homePath(&path_buf, ".config/gtk-3.0/settings.ini") orelse return;
    var buf: [4096]u8 = undefined;
    const data = util.readFile(path, &buf) orelse return;

    if (iniValue(data, "gtk-theme-name")) |value| {
        const out = std.fmt.bufPrint(&info.theme, "{s} [GTK3]", .{value}) catch return;
        info.theme_len = out.len;
    }
    if (iniValue(data, "gtk-icon-theme-name")) |value| {
        const out = std.fmt.bufPrint(&info.icons, "{s} [GTK3]", .{value}) catch return;
        info.icons_len = out.len;
    }
    if (iniValue(data, "gtk-font-name")) |value| {
        const out = std.fmt.bufPrint(&info.font, "{s} [GTK3]", .{value}) catch return;
        info.font_len = out.len;
    }
    if (iniValue(data, "gtk-cursor-theme-name")) |theme| {
        if (iniValue(data, "gtk-cursor-theme-size")) |size| {
            const out = std.fmt.bufPrint(&info.cursor, "{s} ({s}px)", .{ theme, size }) catch return;
            info.cursor_len = out.len;
        } else {
            util.setDefault(&info.cursor, &info.cursor_len, theme);
        }
    }
}

fn fillTerminal(info: *SystemInfo) void {
    var term_buf: [64]u8 = undefined;
    if (util.envInto(&term_buf, "TERM_PROGRAM")) |term| {
        util.setDefault(&info.terminal, &info.terminal_len, term);
        return;
    }
    if (std.process.hasEnvVarConstant("ZELLIJ")) {
        util.setDefault(&info.terminal, &info.terminal_len, "zellij");
        return;
    }
    const term = util.envInto(&term_buf, "TERM") orelse "tty";
    util.setDefault(&info.terminal, &info.terminal_len, term);
}

fn fillDisks(info: *SystemInfo) void {
    fillDiskPath("/", &info.disk, &info.disk_len);
    fillDiskPath("/mnt/ssd2", &info.disk2, &info.disk2_len);
    fillDiskPath("/nix", &info.disk3, &info.disk3_len);
}

fn fillLocalIp(info: *SystemInfo) void {
    var buf: [65536]u8 = undefined;
    const data = util.readFile("/proc/net/fib_trie", &buf) orelse return;
    const ip = localIpFromFibTrie(data) orelse return;
    const out = std.fmt.bufPrint(&info.local_ip, "{s}", .{ip}) catch return;
    info.local_ip_len = out.len;
}

fn fillLocale(info: *SystemInfo) void {
    var buf: [FieldSize]u8 = undefined;
    const locale = util.envInto(&buf, "LC_ALL") orelse util.envInto(&buf, "LC_CTYPE") orelse util.envInto(&buf, "LANG") orelse return;
    util.setDefault(&info.locale, &info.locale_len, locale);
}

fn osReleaseValue(data: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (line.len <= key.len or line[key.len] != '=') continue;
        return util.unquote(util.trim(line[key.len + 1 ..]));
    }
    return null;
}

fn ueventValue(data: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (line.len <= key.len or line[key.len] != '=') continue;
        return util.trim(line[key.len + 1 ..]);
    }
    return null;
}

fn iniValue(data: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        const trimmed = util.trim(line);
        if (!std.mem.startsWith(u8, trimmed, key)) continue;
        if (trimmed.len <= key.len or trimmed[key.len] != '=') continue;
        return util.trim(trimmed[key.len + 1 ..]);
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
            if (in_device) device_name = util.trim(line[5..]);
            continue;
        }

        if (!in_device or line.len < 11 or line[1] != '\t') continue;
        if (asciiIdEql(line[2..6], &subsystem_vendor) and asciiIdEql(line[7..11], &subsystem_device)) {
            const sub_name = util.trim(line[11..]);
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
    const trimmed = util.trim(value);
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
            if (std.mem.indexOfScalar(u8, line, ':')) |idx| return util.trim(line[idx + 1 ..]);
        }
        if (std.mem.startsWith(u8, line, "Hardware")) {
            if (std.mem.indexOfScalar(u8, line, ':')) |idx| return util.trim(line[idx + 1 ..]);
        }
    }
    return null;
}

fn cleanCpuModel(model: []const u8) []const u8 {
    const suffixes = [_][]const u8{
        " 8-Core Processor",
        " 6-Core Processor",
        " 4-Core Processor",
        " Processor",
    };

    for (suffixes) |suffix| {
        if (std.mem.endsWith(u8, model, suffix)) return model[0 .. model.len - suffix.len];
    }
    return model;
}

fn cpuThreadCount(data: []const u8) usize {
    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "processor")) count += 1;
    }
    return if (count == 0) 1 else count;
}

fn cpuMaxMhz(data: []const u8) ?f64 {
    var max: f64 = 0;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "cpu MHz")) continue;
        const idx = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const mhz = std.fmt.parseFloat(f64, util.trim(line[idx + 1 ..])) catch continue;
        if (mhz > max) max = mhz;
    }
    return if (max == 0) null else max;
}

fn formatMemory(data: []const u8, buf: []u8) ![]const u8 {
    const total_kb = meminfoKb(data, "MemTotal") orelse return error.MissingMemory;
    const available_kb = meminfoKb(data, "MemAvailable") orelse return error.MissingMemory;
    const used_gib: f64 = @as(f64, @floatFromInt(total_kb - available_kb)) / 1048576.0;
    const total_gib: f64 = @as(f64, @floatFromInt(total_kb)) / 1048576.0;
    const pct = if (total_kb == 0) 0 else ((total_kb - available_kb) * 100) / total_kb;
    return std.fmt.bufPrint(buf, "{d:.2} GiB / {d:.2} GiB ({}%)", .{ used_gib, total_gib, pct });
}

fn meminfoKb(data: []const u8, key: []const u8) ?u64 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, key)) continue;
        if (std.mem.indexOfScalar(u8, line, ':')) |idx| {
            const rest = util.trim(line[idx + 1 ..]);
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

fn edidDisplayName(edid: []const u8, buf: []u8) ?[]const u8 {
    if (edid.len < 128) return null;
    var offset: usize = 54;
    while (offset + 18 <= 126) : (offset += 18) {
        if (edid[offset] == 0 and edid[offset + 1] == 0 and edid[offset + 2] == 0 and edid[offset + 3] == 0xfc) {
            const raw = util.trim(edid[offset + 5 .. offset + 18]);
            const n = @min(buf.len, raw.len);
            @memcpy(buf[0..n], raw[0..n]);
            return buf[0..n];
        }
    }
    return null;
}

fn edidDiagonalInches(edid: []const u8) ?u32 {
    if (edid.len < 23 or edid[21] == 0 or edid[22] == 0) return null;
    const width_cm: f64 = @floatFromInt(edid[21]);
    const height_cm: f64 = @floatFromInt(edid[22]);
    const diagonal_cm = std.math.sqrt(width_cm * width_cm + height_cm * height_cm);
    return @intFromFloat((diagonal_cm / 2.54) + 0.5);
}

fn edidRefreshRate(edid: []const u8) ?u32 {
    if (edid.len < 72) return null;
    const offset = 54;
    const pixel_clock: u32 = (@as(u32, edid[offset + 1]) << 8 | edid[offset]) * 10000;
    if (pixel_clock == 0) return null;
    const hactive: u32 = @as(u32, edid[offset + 2]) | ((@as(u32, edid[offset + 4]) & 0xf0) << 4);
    const hblank: u32 = @as(u32, edid[offset + 3]) | ((@as(u32, edid[offset + 4]) & 0x0f) << 8);
    const vactive: u32 = @as(u32, edid[offset + 5]) | ((@as(u32, edid[offset + 7]) & 0xf0) << 4);
    const vblank: u32 = @as(u32, edid[offset + 6]) | ((@as(u32, edid[offset + 7]) & 0x0f) << 8);
    const total = (hactive + hblank) * (vactive + vblank);
    if (total == 0) return null;
    return (pixel_clock + total / 2) / total;
}

fn fillDiskPath(path: []const u8, buf: *[FieldSize]u8, len: *usize) void {
    var path_buf: [std.fs.max_path_bytes:0]u8 = undefined;
    if (path.len >= path_buf.len) return;
    @memcpy(path_buf[0..path.len], path);
    path_buf[path.len] = 0;

    var stat: LinuxStatfs = undefined;
    const rc = std.os.linux.syscall2(.statfs, @intFromPtr(&path_buf), @intFromPtr(&stat));
    if (std.os.linux.E.init(rc) != .SUCCESS) return;
    const block_size: u64 = @intCast(if (stat.f_frsize > 0) stat.f_frsize else stat.f_bsize);
    const total: u64 = stat.f_blocks * block_size;
    const available: u64 = stat.f_bavail * block_size;
    const used = total - available;
    const pct = if (total == 0) 0 else (used * 100) / total;
    const out = std.fmt.bufPrint(buf, "({s}): {f} / {f} ({}%)", .{ path, util.formatBytes(used), util.formatBytes(total), pct }) catch return;
    len.* = out.len;
}

fn localIpFromFibTrie(data: []const u8) ?[]const u8 {
    var candidate: ?[]const u8 = null;
    var fallback: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        const trimmed = util.trim(line);
        if (std.mem.startsWith(u8, trimmed, "|-- ") or std.mem.startsWith(u8, trimmed, "+-- ")) {
            const ip = trimmed[4..];
            if (isUsableIpv4(ip)) candidate = ip;
            continue;
        }
        if (candidate != null and std.mem.indexOf(u8, trimmed, "host LOCAL") != null) {
            if (isPreferredLanIpv4(candidate.?)) return candidate.?;
            if (fallback == null) fallback = candidate;
        }
    }
    return fallback;
}

fn isUsableIpv4(ip: []const u8) bool {
    return std.mem.indexOfScalar(u8, ip, '.') != null and
        !std.mem.startsWith(u8, ip, "127.") and
        !std.mem.startsWith(u8, ip, "0.") and
        !std.mem.startsWith(u8, ip, "224.") and
        !std.mem.startsWith(u8, ip, "255.");
}

fn isPreferredLanIpv4(ip: []const u8) bool {
    return std.mem.startsWith(u8, ip, "192.168.") or
        std.mem.startsWith(u8, ip, "10.") or
        (std.mem.startsWith(u8, ip, "172.") and ip.len > 6 and blk: {
            var parts = std.mem.splitScalar(u8, ip, '.');
            _ = parts.next();
            const second = std.fmt.parseInt(u8, parts.next() orelse break :blk false, 10) catch break :blk false;
            break :blk second >= 16 and second <= 31;
        });
}

test "parse os-release quoted value" {
    const data = "ID=arcade\nNAME=ArcadeOS\nPRETTY_NAME=\"ArcadeOS Neon 1.0\"\n";
    try std.testing.expectEqualStrings("ArcadeOS Neon 1.0", osReleaseValue(data, "PRETTY_NAME").?);
    try std.testing.expectEqualStrings("arcade", osReleaseValue(data, "ID").?);
}

test "format meminfo usage" {
    const data = "MemTotal:       8192000 kB\nMemAvailable:   4096000 kB\n";
    var buf: [FieldSize]u8 = undefined;
    try std.testing.expectEqualStrings("3.91 GiB / 7.81 GiB (50%)", try formatMemory(data, &buf));
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
