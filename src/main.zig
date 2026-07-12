const std = @import("std");
const httpz = @import("httpz");
const config = @import("config.zig");
const RequestLogger = @import("middleware/request_logger.zig");
const Store = @import("store.zig").Store;
const MemoryStore = @import("memory_store.zig").MemoryStore;

const App = struct {
    store: Store,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const config_path = try parseConfigPath(args);

    const cfg = try config.load(.cwd(), init.io, allocator, config_path);

    var memory_store = MemoryStore.init(allocator);
    defer memory_store.store().close();

    var app = App{ .store = memory_store.store() };

    var server = try httpz.Server(*App).init(init.io, allocator, .{
        .address = .localhost(cfg.port),
    }, &app);
    defer {
        server.stop();
        server.deinit();
    }

    const request_logger = try server.middleware(RequestLogger, .{ .enabled = cfg.debug });

    var router = try server.router(.{ .middlewares = &.{request_logger} });
    router.get("/choices", listChoices, .{});

    std.log.info("listening on http://localhost:{d}", .{cfg.port});
    try server.listen();
}

fn listChoices(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.content_type = .JSON;
    res.body = "[]";
}

fn parseConfigPath(args: []const []const u8) ![]const u8 {
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--config")) {
            i += 1;
            if (i >= args.len) return error.MissingConfigValue;
            return args[i];
        }
        if (std.mem.startsWith(u8, arg, "--config=")) {
            return arg["--config=".len..];
        }
    }
    return "config.yaml";
}
