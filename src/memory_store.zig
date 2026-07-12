const std = @import("std");
const Store = @import("store.zig").Store;

const SpinLock = struct {
    locked: std.atomic.Value(bool) = .init(false),

    fn lock(self: *SpinLock) void {
        while (self.locked.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {
            std.atomic.spinLoopHint();
        }
    }

    fn unlock(self: *SpinLock) void {
        self.locked.store(false, .release);
    }
};

pub const MemoryStore = struct {
    allocator: std.mem.Allocator,
    mutex: SpinLock,
    entries: std.StringHashMapUnmanaged([]u8),

    pub fn init(allocator: std.mem.Allocator) MemoryStore {
        return .{
            .allocator = allocator,
            .mutex = .{},
            .entries = .empty,
        };
    }

    pub fn store(self: *MemoryStore) Store {
        return .{ .ptr = self, .vtable = &vtable };
    }

    const vtable = Store.VTable{
        .get = get,
        .put = put,
        .delete = delete,
        .close = close,
    };

    fn get(ptr: *anyopaque, allocator: std.mem.Allocator, key: []const u8) anyerror!?[]u8 {
        const self: *MemoryStore = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        defer self.mutex.unlock();

        const value = self.entries.get(key) orelse return null;
        return try allocator.dupe(u8, value);
    }

    fn put(ptr: *anyopaque, key: []const u8, value: []const u8) anyerror!void {
        const self: *MemoryStore = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        defer self.mutex.unlock();

        const owned_value = try self.allocator.dupe(u8, value);
        errdefer self.allocator.free(owned_value);

        if (self.entries.fetchRemove(key)) |old| {
            self.allocator.free(old.key);
            self.allocator.free(old.value);
        }

        const owned_key = try self.allocator.dupe(u8, key);
        try self.entries.put(self.allocator, owned_key, owned_value);
    }

    fn delete(ptr: *anyopaque, key: []const u8) anyerror!void {
        const self: *MemoryStore = @ptrCast(@alignCast(ptr));
        self.mutex.lock();
        defer self.mutex.unlock();

        if (self.entries.fetchRemove(key)) |old| {
            self.allocator.free(old.key);
            self.allocator.free(old.value);
        }
    }

    fn close(ptr: *anyopaque) void {
        const self: *MemoryStore = @ptrCast(@alignCast(ptr));
        self.mutex.lock();

        var it = self.entries.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.entries.deinit(self.allocator);

        const allocator = self.allocator;
        self.mutex.unlock();
        allocator.destroy(self);
    }
};
