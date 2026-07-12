const std = @import("std");
const httpz = @import("httpz");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var server = try httpz.Server(void).init(init.io, allocator, .{
        .address = .localhost(5882),
    }, {});
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/hello", hello, .{});

    std.log.info("listening on http://localhost:5882", .{});
    try server.listen();
}

fn hello(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = "Hello, world!";
}
