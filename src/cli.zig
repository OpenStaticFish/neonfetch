const std = @import("std");
const build_options = @import("build_options");
const types = @import("types.zig");
const util = @import("util.zig");

const FieldId = types.FieldId;
const FieldKind = types.FieldKind;
const Filter = types.Filter;
const MaxFilters = types.MaxFilters;
const OutputFormat = types.OutputFormat;
pub const Options = types.Options;

pub fn parseOptions() !Options {
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
        } else if (std.mem.eql(u8, arg, "--raw")) {
            options.format = .raw;
        } else if (std.mem.eql(u8, arg, "--format")) {
            i += 1;
            if (i >= args.len) failArgument("missing value for --format", .{});
            options.format = parseFormat(args[i]);
        } else if (std.mem.startsWith(u8, arg, "--format=")) {
            options.format = parseFormat(arg["--format=".len..]);
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

pub fn writeVersion(writer: anytype) !void {
    try writer.print("neonfetch {s}\n", .{build_options.version});
}

pub fn writeFields(writer: anytype) !void {
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

pub fn writeCategories(writer: anytype) !void {
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

fn parseFormat(value: []const u8) OutputFormat {
    if (std.mem.eql(u8, value, "pretty")) return .pretty;
    if (std.mem.eql(u8, value, "raw")) return .raw;
    if (std.mem.eql(u8, value, "json")) return .json;
    if (std.mem.eql(u8, value, "csv")) return .csv;
    failArgument("unknown format: {s} (pretty, raw, json, csv)", .{value});
}

pub fn writeHelp(writer: anytype) !void {
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
        \\      --raw                  Print only field values (no logo, header, palette)
        \\      --format <fmt>         Output format: pretty, raw, json, csv
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
        \\  neonfetch --raw --only cpu,gpu
        \\  neonfetch --format json
        \\  neonfetch --format csv --only os,cpu,memory
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
        const name = util.trim(part);
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

test "parse field and category filters" {
    try std.testing.expectEqual(FieldId.local_ip, parseFieldId("local-ip").?);
    try std.testing.expectEqual(FieldId.gpu, parseFieldId("gpus").?);
    try std.testing.expectEqual(FieldKind.hardware, parseFieldKind("hardware").?);
    try std.testing.expect(parseFilter("definitely-missing") == null);
}
