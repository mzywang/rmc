const std = @import("std");
const httpz = @import("httpz");

const RequestLogger = @This();

enabled: bool,

pub fn init(config: Config) !RequestLogger {
    return .{ .enabled = config.enabled };
}

pub fn execute(self: *const RequestLogger, req: *httpz.Request, res: *httpz.Response, executor: anytype) !void {
    defer if (self.enabled) std.log.info("{s} {s} {d}", .{ @tagName(req.method), req.url.path, res.status });
    try executor.next();
}

pub const Config = struct {
    enabled: bool = false,
};
