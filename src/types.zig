const std = @import("std");

pub const FieldSize = 256;
pub const ArtWidth = 43;
pub const MaxFilters = 32;

pub const Style = struct {
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

pub const InfoField = struct {
    id: FieldId,
    label: []const u8,
    value: []const u8,
    kind: FieldKind,
};

pub const FieldId = enum {
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

pub const FieldKind = enum {
    identity,
    system,
    desktop,
    hardware,
    package,
    usage,
    storage,
    network,
};

pub const Filter = union(enum) {
    field: FieldId,
    category: FieldKind,
};

pub const OutputFormat = enum {
    pretty,
    raw,
    json,
    csv,
};

pub const CliAction = enum {
    render,
    help,
    version,
    fields,
    categories,
};

pub const Options = struct {
    action: CliAction = .render,
    format: OutputFormat = .pretty,
    show_logo: bool = true,
    show_header: bool = true,
    show_palette: bool = true,
    color: ?bool = null,
    only: [MaxFilters]Filter = undefined,
    only_len: usize = 0,
    hide: [MaxFilters]Filter = undefined,
    hide_len: usize = 0,
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

    pub fn userHost(self: *const SystemInfo) []const u8 {
        return self.user_host[0..self.user_host_len];
    }

    pub fn osId(self: *const SystemInfo) []const u8 {
        return self.os_id[0..self.os_id_len];
    }

    pub fn field(self: *const SystemInfo, comptime name: []const u8) []const u8 {
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
