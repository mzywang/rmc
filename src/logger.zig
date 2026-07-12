const std = @import("std");
const httpz = @import("httpz");

const Logger = @This();

pub fn init(_: Config) !Logger {
    return .{};
}

pub fn execute(_: *const Logger, req: *httpz.Request, res: *httpz.Response, executor: anytype) !void {
    defer std.log.info("{s} {s} {d}", .{ @tagName(req.method), req.url.path, res.status });
    try executor.next();
}

pub const Config = struct {};
