const std = @import("std");
const httpz = @import("httpz");
const config = @import("config.zig");
const RequestLogger = @import("middleware/request_logger.zig");
const store = @import("store.zig");
const choices = @import("choices.zig");

const App = struct {
    store: store.Store,
    io: std.Io,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    const config_path = try parseConfigPath(args);

    const cfg = try config.load(.cwd(), init.io, allocator, config_path);

    const app_store = try store.open(allocator, cfg);
    defer app_store.close();

    var app = App{ .store = app_store, .io = init.io };

    var server = try httpz.Server(*App).init(init.io, allocator, .{
        .address = .all(cfg.port),
    }, &app);
    defer {
        server.stop();
        server.deinit();
    }

    const request_logger = try server.middleware(RequestLogger, .{ .enabled = cfg.debug });

    var router = try server.router(.{ .middlewares = &.{request_logger} });
    router.get("/choices", listChoices, .{});
    router.post("/companies", createCompany, .{});
    router.get("/companies", listCompanies, .{});

    std.log.info("listening on http://localhost:{d}", .{cfg.port});
    try server.listen();
}

const default_choices_limit: u64 = 20;
const max_choices_limit: u64 = 100;

fn listChoices(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const entries = try app.store.list(req.arena);

    const company_ids = try req.arena.alloc([]const u8, entries.len);
    for (entries, 0..) |entry, i| company_ids[i] = entry.key;
    std.mem.sort([]const u8, company_ids, {}, lessThanString);

    const query = try req.query();
    const cursor = parseQueryUint(query.get("cursor")) orelse 0;
    const limit = @min(parseQueryUint(query.get("limit")) orelse default_choices_limit, max_choices_limit);

    const generator = choices.all_pairs;
    const page = try generator.page(req.arena, company_ids, cursor, limit);
    const total = generator.total(company_ids);
    const next_cursor: ?u64 = if (cursor + page.len >= total) null else cursor + page.len;

    res.status = 200;
    try res.json(.{ .choices = page, .next_cursor = next_cursor }, .{});
}

fn lessThanString(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}

fn parseQueryUint(value: ?[]const u8) ?u64 {
    const v = value orelse return null;
    return std.fmt.parseUnsigned(u64, v, 10) catch null;
}

const CreateCompanyRequest = struct {
    company_id: []const u8,
};

fn createCompany(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const parsed = (try req.json(CreateCompanyRequest)) orelse {
        res.status = 400;
        try res.json(.{ .@"error" = "missing request body" }, .{});
        return;
    };

    const created_at = try formatTimestamp(req.arena, app.io);

    if (!try app.store.putIfAbsent(parsed.company_id, created_at)) {
        res.status = 409;
        try res.json(.{ .@"error" = "company_id already exists" }, .{});
        return;
    }

    res.status = 201;
    try res.json(.{ .company_id = parsed.company_id, .created_at = created_at }, .{});
}

const Company = struct {
    company_id: []const u8,
    created_at: []const u8,
};

fn listCompanies(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const entries = try app.store.list(req.arena);

    const companies = try req.arena.alloc(Company, entries.len);
    for (entries, 0..) |entry, i| {
        companies[i] = .{ .company_id = entry.key, .created_at = entry.value };
    }

    res.status = 200;
    try res.json(companies, .{});
}

fn formatTimestamp(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    const now = std.Io.Clock.now(.real, io);
    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(now.toSeconds()) };
    const year_day = epoch_seconds.getEpochDay().calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch_seconds.getDaySeconds();

    return std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
        day_seconds.getHoursIntoDay(),
        day_seconds.getMinutesIntoHour(),
        day_seconds.getSecondsIntoMinute(),
    });
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
