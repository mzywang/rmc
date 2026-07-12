const std = @import("std");

pub const Config = struct {
    port: u16 = 5882,
};

pub fn load(dir: std.Io.Dir, io: std.Io, gpa: std.mem.Allocator, path: []const u8) !Config {
    const contents = try dir.readFileAlloc(io, path, gpa, .limited(64 * 1024));
    defer gpa.free(contents);

    var config: Config = .{};
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;

        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const key = std.mem.trim(u8, line[0..colon], " \t");
        const value = std.mem.trim(u8, line[colon + 1 ..], " \t");

        if (std.mem.eql(u8, key, "port")) {
            config.port = try std.fmt.parseInt(u16, value, 10);
        }
    }

    return config;
}
