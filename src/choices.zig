const std = @import("std");

pub const Choice = struct {
    id: []const u8,
    option_a: []const u8,
    option_b: []const u8,
};

pub const Generator = struct {
    totalFn: *const fn (company_ids: []const []const u8) u64,
    pageFn: *const fn (allocator: std.mem.Allocator, company_ids: []const []const u8, cursor: u64, limit: u64) anyerror![]Choice,

    pub fn total(self: Generator, company_ids: []const []const u8) u64 {
        return self.totalFn(company_ids);
    }

    pub fn page(self: Generator, allocator: std.mem.Allocator, company_ids: []const []const u8, cursor: u64, limit: u64) ![]Choice {
        return self.pageFn(allocator, company_ids, cursor, limit);
    }
};

pub const all_pairs = Generator{ .totalFn = allPairsTotal, .pageFn = allPairsPage };

fn allPairsTotal(company_ids: []const []const u8) u64 {
    const n: u64 = company_ids.len;
    if (n < 2) return 0;
    return n * (n - 1) / 2;
}

fn allPairsPage(allocator: std.mem.Allocator, company_ids: []const []const u8, cursor: u64, limit: u64) anyerror![]Choice {
    const n: u64 = company_ids.len;
    const total_count = allPairsTotal(company_ids);
    if (cursor >= total_count) return &.{};

    const count: usize = @intCast(@min(limit, total_count - cursor));
    const result = try allocator.alloc(Choice, count);

    var i = rowForRank(n, cursor);
    var j = i + 1 + (cursor - rowStart(n, i));

    for (result) |*choice| {
        const a = company_ids[@intCast(i)];
        const b = company_ids[@intCast(j)];
        choice.* = .{
            .id = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ a, b }),
            .option_a = a,
            .option_b = b,
        };

        j += 1;
        if (j == n) {
            i += 1;
            j = i + 1;
        }
    }

    return result;
}

fn rowStart(n: u64, i: u64) u64 {
    if (i == 0) return 0;
    return i * (n - 1) - i * (i - 1) / 2;
}

fn rowForRank(n: u64, rank: u64) u64 {
    var lo: u64 = 0;
    var hi: u64 = n - 2;
    while (lo < hi) {
        const mid = lo + (hi - lo + 1) / 2;
        if (rowStart(n, mid) <= rank) {
            lo = mid;
        } else {
            hi = mid - 1;
        }
    }
    return lo;
}
