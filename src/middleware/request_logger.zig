const std = @import("std");
const httpz = @import("httpz");

const RequestLogger = @This();

pub fn init(_: Config) !RequestLogger {
    return .{};
}

pub fn execute(_: *const RequestLogger, req: *httpz.Request, res: *httpz.Response, executor: anytype) !void {
    defer std.log.info("{s} {s} {d}", .{ @tagName(req.method), req.url.path, res.status });
    try executor.next();
}

pub const Config = struct {};
