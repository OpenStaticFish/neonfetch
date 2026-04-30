const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");

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

const FieldSize = 256;
const ArtWidth = 43;
const MaxFilters = 32;

const NixosArt = [_][]const u8{
    "          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖",
    "          ▜███▙       ▜███▙  ▟███▛",
    "           ▜███▙       ▜███▙▟███▛",
    "            ▜███▙       ▜██████▛",
    "     ▟█████████████████▙ ▜████▛     ▟▙",
    "    ▟███████████████████▙ ▜███▙    ▟██▙",
    "           ▄▄▄▄▖           ▜███▙  ▟███▛",
    "          ▟███▛             ▜██▛ ▟███▛",
    "         ▟███▛               ▜▛ ▟███▛",
    "▟███████████▛                  ▟██████████▙",
    "▜██████████▛                  ▟███████████▛",
    "      ▟███▛ ▟▙               ▟███▛",
    "     ▟███▛ ▟██▙             ▟███▛",
    "    ▟███▛  ▜███▙           ▝▀▀▀▀",
    "    ▜██▛    ▜███▙ ▜██████████████████▛",
    "     ▜▛     ▟████▙ ▜████████████████▛",
    "           ▟██████▙       ▜███▙",
    "          ▟███▛▜███▙       ▜███▙",
    "         ▟███▛  ▜███▙       ▜███▙",
    "         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘",
};

const LinuxArt = [_][]const u8{
    "                            ",
    "           .--.             ",
    "          |o_o |            ",
    "          |:_/ |            ",
    "         //   \\ \\           ",
    "        (|     | )          ",
    "       /'\\_   _/`\\         ",
    "       \\___)=(___/         ",
    "                            ",
    "                            ",
    "                            ",
    "                            ",
};

const DistroLogo = struct {
    id: []const u8,
    art: []const []const u8,
};

const DistroLogos = [_]DistroLogo{
    .{ .id = "nixos", .art = NixosArt[0..] },
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
    ok: []const u8,
    warn: []const u8,
    danger: []const u8,
};

const InfoField = struct {
    id: FieldId,
    label: []const u8,
    value: []const u8,
    kind: FieldKind,
};

const FieldId = enum {
    os,
    host,
    kernel,
    uptime,
    packages,
    shell,
    display,
    wm,
    theme,
    icons,
    font,
    cursor,
    terminal,
    cpu,
    gpu,
    memory,
    swap,
    disk,
    local_ip,
    locale,
};

const FieldKind = enum {
    identity,
    system,
    desktop,
    hardware,
    package,
    usage,
    storage,
    network,
};

const Filter = union(enum) {
    field: FieldId,
    category: FieldKind,
};

const CliAction = enum {
    render,
    help,
    version,
    fields,
    categories,
};

const Options = struct {
    action: CliAction = .render,
    show_logo: bool = true,
    show_header: bool = true,
    show_palette: bool = true,
    color: ?bool = null,
    only: [MaxFilters]Filter = undefined,
    only_len: usize = 0,
    hide: [MaxFilters]Filter = undefined,
    hide_len: usize = 0,
};

const neon = Style{
    .reset = "\x1b[0m",
    .bold = "\x1b[1m",
    .dim = "\x1b[2m",
    .pink = "\x1b[38;2;126;200;227m",
    .purple = "\x1b[38;2;90;150;190m",
    .cyan = "\x1b[38;2;136;220;205m",
    .blue = "\x1b[38;2;74;144;226m",
    .orange = "\x1b[38;2;170;190;205m",
    .ok = "\x1b[38;2;92;255;138m",
    .warn = "\x1b[38;2;249;199;74m",
    .danger = "\x1b[38;2;255;82;82m",
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
    .ok = "",
    .warn = "",
    .danger = "",
};

pub const SystemInfo = struct {
    user_host: [FieldSize]u8 = undefined,
    user_host_len: usize = 0,
    os: [FieldSize]u8 = undefined,
    os_len: usize = 0,
    os_id: [FieldSize]u8 = undefined,
    os_id_len: usize = 0,
    host: [FieldSize]u8 = undefined,
    host_len: usize = 0,
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
    gpu2: [FieldSize]u8 = undefined,
    gpu2_len: usize = 0,
    memory: [FieldSize]u8 = undefined,
    memory_len: usize = 0,
    swap: [FieldSize]u8 = undefined,
    swap_len: usize = 0,
    display: [FieldSize]u8 = undefined,
    display_len: usize = 0,
    display2: [FieldSize]u8 = undefined,
    display2_len: usize = 0,
    display3: [FieldSize]u8 = undefined,
    display3_len: usize = 0,
    packages: [FieldSize]u8 = undefined,
    packages_len: usize = 0,
    theme: [FieldSize]u8 = undefined,
    theme_len: usize = 0,
    icons: [FieldSize]u8 = undefined,
    icons_len: usize = 0,
    font: [FieldSize]u8 = undefined,
    font_len: usize = 0,
    cursor: [FieldSize]u8 = undefined,
    cursor_len: usize = 0,
    terminal: [FieldSize]u8 = undefined,
    terminal_len: usize = 0,
    disk: [FieldSize]u8 = undefined,
    disk_len: usize = 0,
    disk2: [FieldSize]u8 = undefined,
    disk2_len: usize = 0,
    disk3: [FieldSize]u8 = undefined,
    disk3_len: usize = 0,
    local_ip: [FieldSize]u8 = undefined,
    local_ip_len: usize = 0,
    locale: [FieldSize]u8 = undefined,
    locale_len: usize = 0,

    fn userHost(self: *const SystemInfo) []const u8 {
        return self.user_host[0..self.user_host_len];
    }

    fn osId(self: *const SystemInfo) []const u8 {
        return self.os_id[0..self.os_id_len];
    }

    fn field(self: *const SystemInfo, comptime name: []const u8) []const u8 {
        return switch (std.meta.stringToEnum(enum { os, host, kernel, arch, uptime, desktop, wm, shell, cpu, gpu, gpu2, memory, swap, display, display2, display3, packages, theme, icons, font, cursor, terminal, disk, disk2, disk3, local_ip, locale }, name).?) {
            .os => self.os[0..self.os_len],
            .host => self.host[0..self.host_len],
            .kernel => self.kernel[0..self.kernel_len],
            .arch => self.arch[0..self.arch_len],
            .uptime => self.uptime[0..self.uptime_len],
            .desktop => self.desktop[0..self.desktop_len],
            .wm => self.wm[0..self.wm_len],
            .shell => self.shell[0..self.shell_len],
            .cpu => self.cpu[0..self.cpu_len],
            .gpu => self.gpu[0..self.gpu_len],
            .gpu2 => self.gpu2[0..self.gpu2_len],
            .memory => self.memory[0..self.memory_len],
            .swap => self.swap[0..self.swap_len],
            .display => self.display[0..self.display_len],
            .display2 => self.display2[0..self.display2_len],
            .display3 => self.display3[0..self.display3_len],
            .packages => self.packages[0..self.packages_len],
            .theme => self.theme[0..self.theme_len],
            .icons => self.icons[0..self.icons_len],
            .font => self.font[0..self.font_len],
            .cursor => self.cursor[0..self.cursor_len],
            .terminal => self.terminal[0..self.terminal_len],
            .disk => self.disk[0..self.disk_len],
            .disk2 => self.disk2[0..self.disk2_len],
            .disk3 => self.disk3[0..self.disk3_len],
            .local_ip => self.local_ip[0..self.local_ip_len],
            .locale => self.locale[0..self.locale_len],
        };
    }
};

pub fn run() !void {
    var stdout_buffer: [8192]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const options = try parseOptions();
    if (options.action == .help) {
        try writeHelp(stdout);
        try stdout.flush();
        return;
    }
    if (options.action == .version) {
        try writeVersion(stdout);
        try stdout.flush();
        return;
    }
    if (options.action == .fields) {
        try writeFields(stdout);
        try stdout.flush();
        return;
    }
    if (options.action == .categories) {
        try writeCategories(stdout);
        try stdout.flush();
        return;
    }

    var info = try collectSystemInfo();
    const use_color = options.color orelse wantsColor();
    try render(stdout, &info, options, use_color);
    try stdout.flush();
}

fn parseOptions() !Options {
    var options = Options{};
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (i == 1 and std.mem.eql(u8, arg, "help")) {
            options.action = .help;
            ensureNoTrailingArgs(args, i);
            return options;
        } else if (i == 1 and std.mem.eql(u8, arg, "version")) {
            options.action = .version;
            ensureNoTrailingArgs(args, i);
            return options;
        } else if (i == 1 and (std.mem.eql(u8, arg, "fields") or std.mem.eql(u8, arg, "list-fields"))) {
            options.action = .fields;
            ensureNoTrailingArgs(args, i);
            return options;
        } else if (i == 1 and (std.mem.eql(u8, arg, "categories") or std.mem.eql(u8, arg, "list-categories"))) {
            options.action = .categories;
            ensureNoTrailingArgs(args, i);
            return options;
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            options.action = .help;
            return options;
        } else if (std.mem.eql(u8, arg, "-V") or std.mem.eql(u8, arg, "--version")) {
            options.action = .version;
            return options;
        } else if (std.mem.eql(u8, arg, "--list-fields")) {
            options.action = .fields;
            return options;
        } else if (std.mem.eql(u8, arg, "--list-categories")) {
            options.action = .categories;
            return options;
        } else if (std.mem.eql(u8, arg, "--")) {
            ensureNoTrailingArgs(args, i);
            return options;
        } else if (std.mem.eql(u8, arg, "--no-logo")) {
            options.show_logo = false;
        } else if (std.mem.eql(u8, arg, "--no-header")) {
            options.show_header = false;
        } else if (std.mem.eql(u8, arg, "--no-palette")) {
            options.show_palette = false;
        } else if (std.mem.eql(u8, arg, "--plain") or std.mem.eql(u8, arg, "--no-color")) {
            options.color = false;
        } else if (std.mem.eql(u8, arg, "--color")) {
            options.color = true;
        } else if (std.mem.eql(u8, arg, "--only")) {
            i += 1;
            if (i >= args.len) failArgument("missing value for --only", .{});
            parseFilterList(args[i], &options.only, &options.only_len);
        } else if (std.mem.startsWith(u8, arg, "--only=")) {
            parseFilterList(arg["--only=".len..], &options.only, &options.only_len);
        } else if (std.mem.eql(u8, arg, "--hide")) {
            i += 1;
            if (i >= args.len) failArgument("missing value for --hide", .{});
            parseFilterList(args[i], &options.hide, &options.hide_len);
        } else if (std.mem.startsWith(u8, arg, "--hide=")) {
            parseFilterList(arg["--hide=".len..], &options.hide, &options.hide_len);
        } else {
            failArgument("unknown option: {s}", .{arg});
        }
    }

    return options;
}

fn ensureNoTrailingArgs(args: []const []const u8, index: usize) void {
    if (index + 1 < args.len) failArgument("unexpected positional argument: {s}", .{args[index + 1]});
}

fn writeVersion(writer: anytype) !void {
    try writer.print("neonfetch {s}\n", .{build_options.version});
}

fn writeFields(writer: anytype) !void {
    try writer.writeAll(
        \\os
        \\host
        \\kernel
        \\uptime
        \\packages
        \\shell
        \\display
        \\wm
        \\theme
        \\icons
        \\font
        \\cursor
        \\terminal
        \\cpu
        \\gpu
        \\memory
        \\swap
        \\disk
        \\local_ip
        \\locale
        \\
    );
}

fn writeCategories(writer: anytype) !void {
    try writer.writeAll(
        \\identity
        \\system
        \\desktop
        \\hardware
        \\package
        \\usage
        \\storage
        \\network
        \\
    );
}

fn writeHelp(writer: anytype) !void {
    try writer.writeAll(
        \\Usage: neonfetch [command] [options]
        \\
        \\Commands:
        \\  help                       Show this help text
        \\  version                    Show version information
        \\  fields                     List filterable fields
        \\  categories                 List filterable categories
        \\
        \\Options:
        \\  -h, --help                 Show this help text
        \\  -V, --version              Show version information
        \\      --no-logo              Hide the distro logo
        \\      --no-header            Hide the user@host header
        \\      --no-palette           Hide the color palette footer
        \\      --plain, --no-color    Disable ANSI styling
        \\      --color                Force ANSI styling
        \\      --only <list>          Show only fields/categories in a comma list
        \\      --hide <list>          Hide fields/categories in a comma list
        \\      --list-fields          List filterable fields
        \\      --list-categories      List filterable categories
        \\
        \\Fields: os, host, kernel, uptime, packages, shell, display, wm, theme,
        \\        icons, font, cursor, terminal, cpu, gpu, memory, swap, disk,
        \\        local_ip, locale
        \\Categories: identity, system, desktop, hardware, package, usage,
        \\            storage, network
        \\Aliases: ip=local_ip, displays=display, gpus=gpu, disks=disk
        \\Names are case-insensitive. Hyphens and spaces are treated like underscores.
        \\
        \\Examples:
        \\  neonfetch --version
        \\  neonfetch fields
        \\  neonfetch --no-logo --only cpu,gpu,memory,disk
        \\  neonfetch --hide packages,local_ip --no-palette
        \\
    );
}

fn failArgument(comptime message: []const u8, args: anytype) noreturn {
    var stderr_buffer: [512]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;
    stderr.print("neonfetch: " ++ message ++ "\nTry 'neonfetch --help' for usage.\n", args) catch {};
    stderr.flush() catch {};
    std.process.exit(2);
}

fn parseFilterList(value: []const u8, filters: *[MaxFilters]Filter, len: *usize) void {
    if (value.len == 0) failArgument("empty filter list", .{});

    var parts = std.mem.splitScalar(u8, value, ',');
    while (parts.next()) |part| {
        const name = trim(part);
        if (name.len == 0) failArgument("empty filter name in list: {s}", .{value});
        if (len.* >= filters.len) failArgument("too many filters, maximum is {}", .{filters.len});
        filters[len.*] = parseFilter(name) orelse failArgument("unknown field or category: {s}", .{name});
        len.* += 1;
    }
}

fn parseFilter(name: []const u8) ?Filter {
    if (parseFieldId(name)) |field| return .{ .field = field };
    if (parseFieldKind(name)) |category| return .{ .category = category };
    return null;
}

fn parseFieldId(name: []const u8) ?FieldId {
    inline for (std.meta.fields(FieldId)) |field| {
        if (eqlName(name, field.name)) return @field(FieldId, field.name);
    }

    if (eqlName(name, "ip")) return .local_ip;
    if (eqlName(name, "displays")) return .display;
    if (eqlName(name, "gpus")) return .gpu;
    if (eqlName(name, "disks")) return .disk;
    return null;
}

fn parseFieldKind(name: []const u8) ?FieldKind {
    inline for (std.meta.fields(FieldKind)) |field| {
        if (eqlName(name, field.name)) return @field(FieldKind, field.name);
    }
    return null;
}

fn eqlName(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        if (normalizeNameChar(left) != normalizeNameChar(right)) return false;
    }
    return true;
}

fn normalizeNameChar(char: u8) u8 {
    return switch (char) {
        '-', ' ' => '_',
        else => std.ascii.toLower(char),
    };
}

pub fn collectSystemInfo() !SystemInfo {
    var info = SystemInfo{};
    setDefault(&info.os, &info.os_len, "Unknown Linux");
    setDefault(&info.os_id, &info.os_id_len, "linux");
    setDefault(&info.host, &info.host_len, "Unknown");
    setDefault(&info.kernel, &info.kernel_len, "Unknown");
    setDefault(&info.arch, &info.arch_len, @tagName(builtin.cpu.arch));
    setDefault(&info.uptime, &info.uptime_len, "Unknown");
    setDefault(&info.desktop, &info.desktop_len, "Unknown");
    setDefault(&info.wm, &info.wm_len, "Unknown");
    setDefault(&info.shell, &info.shell_len, "Unknown");
    setDefault(&info.cpu, &info.cpu_len, "Unknown CPU");
    setDefault(&info.gpu, &info.gpu_len, "Unknown GPU");
    setDefault(&info.gpu2, &info.gpu2_len, "");
    setDefault(&info.memory, &info.memory_len, "Unknown");
    setDefault(&info.swap, &info.swap_len, "Unknown");
    setDefault(&info.display, &info.display_len, "Unknown");
    setDefault(&info.display2, &info.display2_len, "");
    setDefault(&info.display3, &info.display3_len, "");
    setDefault(&info.packages, &info.packages_len, "Unknown");
    setDefault(&info.theme, &info.theme_len, "Unknown");
    setDefault(&info.icons, &info.icons_len, "Unknown");
    setDefault(&info.font, &info.font_len, "Unknown");
    setDefault(&info.cursor, &info.cursor_len, "Unknown");
    setDefault(&info.terminal, &info.terminal_len, "Unknown");
    setDefault(&info.disk, &info.disk_len, "Unknown");
    setDefault(&info.disk2, &info.disk2_len, "");
    setDefault(&info.disk3, &info.disk3_len, "");
    setDefault(&info.local_ip, &info.local_ip_len, "Unknown");
    setDefault(&info.locale, &info.locale_len, "Unknown");

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

fn render(writer: anytype, info: *const SystemInfo, options: Options, use_color: bool) !void {
    const s = if (use_color) neon else plain;
    const colors = [_][]const u8{ s.pink, s.purple, s.blue, s.cyan, s.blue, s.purple };
    const art = osLogo(info.osId());
    const fields = [_]InfoField{
        .{ .id = .os, .label = "OS", .value = info.field("os"), .kind = .identity },
        .{ .id = .host, .label = "Host", .value = info.field("host"), .kind = .identity },
        .{ .id = .kernel, .label = "Kernel", .value = info.field("kernel"), .kind = .system },
        .{ .id = .uptime, .label = "Uptime", .value = info.field("uptime"), .kind = .system },
        .{ .id = .packages, .label = "Packages", .value = info.field("packages"), .kind = .package },
        .{ .id = .shell, .label = "Shell", .value = info.field("shell"), .kind = .system },
        .{ .id = .display, .label = "Display", .value = info.field("display"), .kind = .hardware },
        .{ .id = .display, .label = "Display", .value = info.field("display2"), .kind = .hardware },
        .{ .id = .display, .label = "Display", .value = info.field("display3"), .kind = .hardware },
        .{ .id = .wm, .label = "WM", .value = info.field("wm"), .kind = .desktop },
        .{ .id = .theme, .label = "Theme", .value = info.field("theme"), .kind = .desktop },
        .{ .id = .icons, .label = "Icons", .value = info.field("icons"), .kind = .desktop },
        .{ .id = .font, .label = "Font", .value = info.field("font"), .kind = .desktop },
        .{ .id = .cursor, .label = "Cursor", .value = info.field("cursor"), .kind = .desktop },
        .{ .id = .terminal, .label = "Terminal", .value = info.field("terminal"), .kind = .system },
        .{ .id = .cpu, .label = "CPU", .value = info.field("cpu"), .kind = .hardware },
        .{ .id = .gpu, .label = "GPU", .value = info.field("gpu"), .kind = .hardware },
        .{ .id = .gpu, .label = "GPU", .value = info.field("gpu2"), .kind = .hardware },
        .{ .id = .memory, .label = "Memory", .value = info.field("memory"), .kind = .usage },
        .{ .id = .swap, .label = "Swap", .value = info.field("swap"), .kind = .usage },
        .{ .id = .disk, .label = "Disk", .value = info.field("disk"), .kind = .storage },
        .{ .id = .disk, .label = "Disk", .value = info.field("disk2"), .kind = .storage },
        .{ .id = .disk, .label = "Disk", .value = info.field("disk3"), .kind = .storage },
        .{ .id = .local_ip, .label = "Local IP", .value = info.field("local_ip"), .kind = .network },
        .{ .id = .locale, .label = "Locale", .value = info.field("locale"), .kind = .system },
    };

    var visible_fields: [fields.len]InfoField = undefined;
    var visible_field_count: usize = 0;
    for (fields) |field| {
        if (!shouldShowField(field, options)) continue;
        visible_fields[visible_field_count] = field;
        visible_field_count += 1;
    }

    const row_count = if (options.show_logo) @max(art.len, visible_field_count) else visible_field_count;

    if (options.show_header) {
        try writer.print("\n{s}{s}{s}\n", .{ s.bold, s.pink, info.userHost() });
        try writer.print("{s}{s}\n\n", .{ s.dim, "retro terminal telemetry" });
    } else if (options.show_logo) {
        try writer.writeByte('\n');
    }

    for (0..row_count) |i| {
        const art_line = if (options.show_logo and i < art.len) art[i] else "";
        const field = if (i < visible_field_count) visible_fields[i] else null;
        try row(writer, colors[i % colors.len], art_line, s, field, options.show_logo);
    }

    if (options.show_palette) {
        if (use_color) {
            try writer.print("\n{s}palette {s}██{s}██{s}██{s}██{s}██{s}\n", .{ s.dim, s.pink, s.purple, s.blue, s.cyan, s.orange, s.reset });
        } else {
            try writer.writeAll("\npalette [ice] [steel] [blue] [teal] [slate]\n");
        }
    }
}

fn shouldShowField(field: InfoField, options: Options) bool {
    if (field.value.len == 0) return false;
    if (options.only_len > 0) {
        var matched = false;
        for (options.only[0..options.only_len]) |filter| {
            if (filterMatchesField(filter, field)) {
                matched = true;
                break;
            }
        }
        if (!matched) return false;
    }

    for (options.hide[0..options.hide_len]) |filter| {
        if (filterMatchesField(filter, field)) return false;
    }

    return true;
}

fn filterMatchesField(filter: Filter, field: InfoField) bool {
    return switch (filter) {
        .field => |id| id == field.id,
        .category => |kind| kind == field.kind,
    };
}

fn row(writer: anytype, art_color: []const u8, art: []const u8, s: Style, field: ?InfoField, show_logo: bool) !void {
    if (show_logo) {
        try writer.print("{s}{s}", .{ art_color, art });
        try writePadding(writer, ArtWidth + 2 -| displayWidth(art));
        try writer.writeAll(s.reset);
    }

    if (field) |f| {
        try writer.print("{s}{s: <10}{s} ", .{ s.cyan, f.label, s.reset });
        try writeValue(writer, s, f);
    }

    try writer.writeByte('\n');
}

fn writeValue(writer: anytype, s: Style, field: InfoField) !void {
    switch (field.kind) {
        .usage, .storage => try writeUsageValue(writer, s, field.value),
        else => try writer.writeAll(field.value),
    }
}

fn writeUsageValue(writer: anytype, s: Style, value: []const u8) !void {
    const percent = percentSpan(value) orelse {
        try writer.writeAll(value);
        return;
    };

    try writer.writeAll(value[0..percent.start]);
    try writer.print("{s}{s}{s}", .{ percentColor(s, percent.value), value[percent.start..percent.end], s.reset });
    try writer.writeAll(value[percent.end..]);
}

fn percentColor(s: Style, pct: u8) []const u8 {
    if (pct >= 85) return s.danger;
    if (pct >= 70) return s.warn;
    return s.ok;
}

const PercentSpan = struct {
    start: usize,
    end: usize,
    value: u8,
};

fn percentSpan(value: []const u8) ?PercentSpan {
    const close = std.mem.indexOfScalar(u8, value, '%') orelse return null;
    if (close == 0) return null;

    var start = close;
    while (start > 0 and std.ascii.isDigit(value[start - 1])) start -= 1;
    if (start == close) return null;
    const parsed = std.fmt.parseInt(u8, value[start..close], 10) catch return null;
    return .{ .start = start, .end = close + 1, .value = parsed };
}

fn writePadding(writer: anytype, count: usize) !void {
    for (0..count) |_| try writer.writeByte(' ');
}

fn displayWidth(text: []const u8) usize {
    var width: usize = 0;
    var i: usize = 0;
    while (i < text.len) {
        const size = std.unicode.utf8ByteSequenceLength(text[i]) catch 1;
        i += @min(size, text.len - i);
        width += 1;
    }
    return width;
}

fn osLogo(os_id: []const u8) []const []const u8 {
    for (DistroLogos) |logo| {
        if (std.ascii.eqlIgnoreCase(os_id, logo.id)) return logo.art;
    }

    return LinuxArt[0..];
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

    if (osReleaseValue(data, "PRETTY_NAME") orelse osReleaseValue(data, "NAME")) |pretty| {
        setDefault(&info.os, &info.os_len, pretty);
    }

    if (osReleaseValue(data, "ID")) |id| {
        setDefault(&info.os_id, &info.os_id_len, id);
    }
}

fn fillHost(info: *SystemInfo) void {
    var buf: [FieldSize]u8 = undefined;
    const product = trim(readFile("/sys/devices/virtual/dmi/id/product_name", &buf) orelse return);
    if (product.len > 0) setDefault(&info.host, &info.host_len, product);
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
    var buf: [65536]u8 = undefined;
    const data = readFile("/proc/cpuinfo", &buf) orelse return;
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
        const class = if (std.mem.eql(u8, driver, "amdgpu") and !std.mem.eql(u8, device_id, "0x731f")) " [Integrated]" else " [Discrete]";
        var out_buf: [FieldSize]u8 = undefined;
        const out = std.fmt.bufPrint(&out_buf, "{s}{s}", .{ model, class }) catch return;
        switch (count) {
            0 => setDefault(&info.gpu, &info.gpu_len, out),
            1 => setDefault(&info.gpu2, &info.gpu2_len, out),
            else => break,
        }
        count += 1;
    }
}

fn fillMemory(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = readFile("/proc/meminfo", &buf) orelse return;
    const formatted = formatMemory(data, &info.memory) catch return;
    info.memory_len = formatted.len;
}

fn fillSwap(info: *SystemInfo) void {
    var buf: [4096]u8 = undefined;
    const data = readFile("/proc/meminfo", &buf) orelse return;
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
        if (!std.mem.eql(u8, trim(readFile(status_path, &status_buf) orelse continue), "connected")) continue;

        var modes_path_buf: [256]u8 = undefined;
        const modes_path = std.fmt.bufPrint(&modes_path_buf, "/sys/class/drm/{s}/modes", .{entry.name}) catch continue;
        var modes_buf: [256]u8 = undefined;
        const modes = trim(readFile(modes_path, &modes_buf) orelse continue);
        const first_line_end = std.mem.indexOfScalar(u8, modes, '\n') orelse modes.len;
        const mode = modes[0..first_line_end];
        var edid_path_buf: [256]u8 = undefined;
        const edid_path = std.fmt.bufPrint(&edid_path_buf, "/sys/class/drm/{s}/edid", .{entry.name}) catch continue;
        var edid_buf: [512]u8 = undefined;
        const edid = readFile(edid_path, &edid_buf) orelse "";
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
            0 => setDefault(&info.display, &info.display_len, out),
            1 => setDefault(&info.display2, &info.display2_len, out),
            2 => setDefault(&info.display3, &info.display3_len, out),
            else => break,
        }
        count += 1;
    }
}

fn fillPackages(info: *SystemInfo) void {
    const nix_system = countDirEntries("/run/current-system/sw/bin") orelse 0;
    const nix_user = countUserProfileBins() orelse 0;
    const flatpak_system = countDirEntries("/var/lib/flatpak/app") orelse 0;
    const flatpak_user = countHomeDirEntries(".local/share/flatpak/app") orelse 0;

    if (nix_system + nix_user + flatpak_system + flatpak_user > 0) {
        const out = std.fmt.bufPrint(&info.packages, "{} (nix-system), {} (nix-user), {} (flatpak-system), {} (flatpak-user)", .{ nix_system, nix_user, flatpak_system, flatpak_user }) catch return;
        info.packages_len = out.len;
        return;
    }

    const usr_bins = countDirEntries("/usr/bin") orelse return;
    const out = std.fmt.bufPrint(&info.packages, "{} usr binaries", .{usr_bins}) catch return;
    info.packages_len = out.len;
}

fn fillGtkSettings(info: *SystemInfo) void {
    var path_buf: [512]u8 = undefined;
    const path = homePath(&path_buf, ".config/gtk-3.0/settings.ini") orelse return;
    var buf: [4096]u8 = undefined;
    const data = readFile(path, &buf) orelse return;

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
            setDefault(&info.cursor, &info.cursor_len, theme);
        }
    }
}

fn fillTerminal(info: *SystemInfo) void {
    var term_buf: [64]u8 = undefined;
    if (envInto(&term_buf, "TERM_PROGRAM")) |term| {
        setDefault(&info.terminal, &info.terminal_len, term);
        return;
    }
    if (std.process.hasEnvVarConstant("ZELLIJ")) {
        setDefault(&info.terminal, &info.terminal_len, "zellij");
        return;
    }
    const term = envInto(&term_buf, "TERM") orelse "tty";
    setDefault(&info.terminal, &info.terminal_len, term);
}

fn fillDisks(info: *SystemInfo) void {
    fillDiskPath("/", &info.disk, &info.disk_len);
    fillDiskPath("/mnt/ssd2", &info.disk2, &info.disk2_len);
    fillDiskPath("/nix", &info.disk3, &info.disk3_len);
}

fn fillLocalIp(info: *SystemInfo) void {
    var buf: [65536]u8 = undefined;
    const data = readFile("/proc/net/fib_trie", &buf) orelse return;
    const ip = localIpFromFibTrie(data) orelse return;
    const out = std.fmt.bufPrint(&info.local_ip, "{s}", .{ip}) catch return;
    info.local_ip_len = out.len;
}

fn fillLocale(info: *SystemInfo) void {
    var buf: [FieldSize]u8 = undefined;
    const locale = envInto(&buf, "LC_ALL") orelse envInto(&buf, "LC_CTYPE") orelse envInto(&buf, "LANG") orelse return;
    setDefault(&info.locale, &info.locale_len, locale);
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

fn countUserProfileBins() ?usize {
    var path_buf: [512]u8 = undefined;
    if (homePath(&path_buf, ".nix-profile/bin")) |path| {
        if (countDirEntries(path)) |count| return count;
    }
    return countDirEntries("/nix/var/nix/profiles/default/bin");
}

fn countHomeDirEntries(relative_path: []const u8) ?usize {
    var path_buf: [512]u8 = undefined;
    const path = homePath(&path_buf, relative_path) orelse return null;
    return countDirEntries(path);
}

fn homePath(buf: []u8, relative_path: []const u8) ?[]const u8 {
    var home_buf: [256]u8 = undefined;
    const home = envInto(&home_buf, "HOME") orelse return null;
    return std.fmt.bufPrint(buf, "{s}/{s}", .{ home, relative_path }) catch null;
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

fn iniValue(data: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        const trimmed = trim(line);
        if (!std.mem.startsWith(u8, trimmed, key)) continue;
        if (trimmed.len <= key.len or trimmed[key.len] != '=') continue;
        return trim(trimmed[key.len + 1 ..]);
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
        const mhz = std.fmt.parseFloat(f64, trim(line[idx + 1 ..])) catch continue;
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

fn edidDisplayName(edid: []const u8, buf: []u8) ?[]const u8 {
    if (edid.len < 128) return null;
    var offset: usize = 54;
    while (offset + 18 <= 126) : (offset += 18) {
        if (edid[offset] == 0 and edid[offset + 1] == 0 and edid[offset + 2] == 0 and edid[offset + 3] == 0xfc) {
            const raw = trim(edid[offset + 5 .. offset + 18]);
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
    const out = std.fmt.bufPrint(buf, "({s}): {f} / {f} ({}%)", .{ path, formatBytes(used), formatBytes(total), pct }) catch return;
    len.* = out.len;
}

fn formatBytes(bytes: u64) ByteFormat {
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

fn localIpFromFibTrie(data: []const u8) ?[]const u8 {
    var candidate: ?[]const u8 = null;
    var fallback: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        const trimmed = trim(line);
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

test "parse field and category filters" {
    try std.testing.expectEqual(FieldId.local_ip, parseFieldId("local-ip").?);
    try std.testing.expectEqual(FieldId.gpu, parseFieldId("gpus").?);
    try std.testing.expectEqual(FieldKind.hardware, parseFieldKind("hardware").?);
    try std.testing.expect(parseFilter("definitely-missing") == null);
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

test "select nixos logo" {
    try std.testing.expectEqualStrings(NixosArt[0], osLogo("nixos")[0]);
    try std.testing.expectEqualStrings(NixosArt[0], osLogo("NIXOS")[0]);
    try std.testing.expectEqualStrings(LinuxArt[0], osLogo("Unknown Linux")[0]);
}
