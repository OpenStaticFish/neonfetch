const std = @import("std");
const types = @import("types.zig");
const util = @import("util.zig");

const ArtWidth = types.ArtWidth;
const FieldId = types.FieldId;
const FieldKind = types.FieldKind;
const Filter = types.Filter;
const InfoField = types.InfoField;
const Options = types.Options;
const OutputFormat = types.OutputFormat;
const Style = types.Style;
const SystemInfo = types.SystemInfo;

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

pub fn render(writer: anytype, info: *const SystemInfo, options: Options, use_color: bool) !void {
    switch (options.format) {
        .pretty => try renderPretty(writer, info, options, use_color),
        .raw => try renderRaw(writer, info, options),
        .json => try renderJson(writer, info, options),
        .csv => try renderCsv(writer, info, options),
    }
}

fn collectVisible(info: *const SystemInfo, options: Options, out: []InfoField) usize {
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
    var count: usize = 0;
    for (fields) |field| {
        if (!shouldShowField(field, options)) continue;
        out[count] = field;
        count += 1;
    }
    return count;
}

fn renderPretty(writer: anytype, info: *const SystemInfo, options: Options, use_color: bool) !void {
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

fn renderRaw(writer: anytype, info: *const SystemInfo, options: Options) !void {
    var visible: [25]InfoField = undefined;
    const count = collectVisible(info, options, &visible);
    for (visible[0..count]) |field| {
        try writer.print("{s}  {s}\n", .{ field.label, field.value });
    }
}

fn renderJson(writer: anytype, info: *const SystemInfo, options: Options) !void {
    var visible: [25]InfoField = undefined;
    const count = collectVisible(info, options, &visible);
    try writer.writeAll("{\n");
    var seen = std.EnumMap(FieldId, usize){};
    for (visible[0..count], 0..) |field, i| {
        const idx = seen.get(field.id) orelse 0;
        seen.put(field.id, idx + 1);
        const total = countFieldId(visible[0..count], field.id);
        if (total > 1) {
            try writer.print("  \"{s}_{}\": ", .{ @tagName(field.id), idx + 1 });
        } else {
            try writer.print("  \"{s}\": ", .{@tagName(field.id)});
        }
        try writeJsonString(writer, field.value);
        if (i + 1 < count) try writer.writeAll(",");
        try writer.writeByte('\n');
    }
    try writer.writeAll("}\n");
}

fn countFieldId(fields: []const InfoField, id: FieldId) usize {
    var n: usize = 0;
    for (fields) |f| {
        if (f.id == id) n += 1;
    }
    return n;
}

fn writeJsonString(writer: anytype, value: []const u8) !void {
    try writer.writeByte('"');
    for (value) |char| {
        switch (char) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(char),
        }
    }
    try writer.writeByte('"');
}

fn renderCsv(writer: anytype, info: *const SystemInfo, options: Options) !void {
    var visible: [25]InfoField = undefined;
    const count = collectVisible(info, options, &visible);
    try writer.writeAll("field,value\n");
    for (visible[0..count]) |field| {
        try writeCsvValue(writer, field.label);
        try writer.writeByte(',');
        try writeCsvValue(writer, field.value);
        try writer.writeByte('\n');
    }
}

fn writeCsvValue(writer: anytype, value: []const u8) !void {
    const needs_quote = std.mem.indexOfAny(u8, value, ",\"\n") != null;
    if (!needs_quote) {
        try writer.writeAll(value);
        return;
    }
    try writer.writeByte('"');
    for (value) |char| {
        if (char == '"') try writer.writeByte('"');
        try writer.writeByte(char);
    }
    try writer.writeByte('"');
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
        try util.writePadding(writer, ArtWidth + 2 -| util.displayWidth(art));
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

fn osLogo(os_id: []const u8) []const []const u8 {
    for (DistroLogos) |logo| {
        if (std.ascii.eqlIgnoreCase(os_id, logo.id)) return logo.art;
    }

    return LinuxArt[0..];
}

pub fn wantsColor() bool {
    if (std.process.hasEnvVarConstant("NO_COLOR")) return false;
    if (std.process.hasEnvVarConstant("CLICOLOR_FORCE")) return true;
    return true;
}

test "select nixos logo" {
    try std.testing.expectEqualStrings(NixosArt[0], osLogo("nixos")[0]);
    try std.testing.expectEqualStrings(NixosArt[0], osLogo("NIXOS")[0]);
    try std.testing.expectEqualStrings(LinuxArt[0], osLogo("Unknown Linux")[0]);
}
