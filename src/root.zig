const std = @import("std");

const cli = @import("cli.zig");
const collect = @import("collect.zig");
const render_output = @import("render.zig");
const types = @import("types.zig");

pub const SystemInfo = types.SystemInfo;
pub const collectSystemInfo = collect.collectSystemInfo;

pub fn run() !void {
    var stdout_buffer: [8192]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const options = try cli.parseOptions();
    switch (options.action) {
        .help => try cli.writeHelp(stdout),
        .version => try cli.writeVersion(stdout),
        .fields => try cli.writeFields(stdout),
        .categories => try cli.writeCategories(stdout),
        .render => {
            var info = try collectSystemInfo();
            const use_color = options.color orelse render_output.wantsColor();
            try render_output.render(stdout, &info, options, use_color);
        },
    }

    try stdout.flush();
}
