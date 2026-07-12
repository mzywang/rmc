const std = @import("std");
const httpz = @import("httpz");
const config = @import("config.zig");
const Logger = @import("logger.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const cfg = try config.load(.cwd(), init.io, allocator, "config.yaml");

    var server = try httpz.Server(void).init(init.io, allocator, .{
        .address = .localhost(cfg.port),
    }, {});
    defer {
        server.stop();
        server.deinit();
    }

    const logger = try server.middleware(Logger, .{});

    var router = try server.router(.{ .middlewares = &.{logger} });
    router.get("/hello", hello, .{});

    std.log.info("listening on http://localhost:{d}", .{cfg.port});
    try server.listen();
}

fn hello(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = "Hello, world!";
}
