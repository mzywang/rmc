const std = @import("std");
const httpz = @import("httpz");
const config = @import("config.zig");

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

    var router = try server.router(.{});
    router.get("/hello", hello, .{});

    std.log.info("listening on http://localhost:{d}", .{cfg.port});
    try server.listen();
}

fn hello(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = "Hello, world!";
}
