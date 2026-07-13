const std = @import("std");
const config = @import("config.zig");
const MemoryStore = @import("memory_store.zig").MemoryStore;

pub fn open(allocator: std.mem.Allocator, cfg: config.Config) !Store {
    _ = cfg;
    const memory_store = try allocator.create(MemoryStore);
    memory_store.* = MemoryStore.init(allocator);
    return memory_store.store();
}

pub const Store = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const Entry = struct {
        key: []const u8,
        value: []const u8,
    };

    pub const VTable = struct {
        get: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator, key: []const u8) anyerror!?[]u8,
        put: *const fn (ptr: *anyopaque, key: []const u8, value: []const u8) anyerror!void,
        putIfAbsent: *const fn (ptr: *anyopaque, key: []const u8, value: []const u8) anyerror!bool,
        delete: *const fn (ptr: *anyopaque, key: []const u8) anyerror!void,
        list: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) anyerror![]Entry,
        close: *const fn (ptr: *anyopaque) void,
    };

    pub fn get(self: Store, allocator: std.mem.Allocator, key: []const u8) !?[]u8 {
        return self.vtable.get(self.ptr, allocator, key);
    }

    pub fn put(self: Store, key: []const u8, value: []const u8) !void {
        return self.vtable.put(self.ptr, key, value);
    }

    /// Atomically stores `value` under `key` only if `key` is not already
    /// present. Returns `true` if the value was stored, `false` if `key`
    /// already existed (in which case the store is left unchanged).
    pub fn putIfAbsent(self: Store, key: []const u8, value: []const u8) !bool {
        return self.vtable.putIfAbsent(self.ptr, key, value);
    }

    pub fn delete(self: Store, key: []const u8) !void {
        return self.vtable.delete(self.ptr, key);
    }

    /// Returns every entry currently in the store, in unspecified order.
    pub fn list(self: Store, allocator: std.mem.Allocator) ![]Entry {
        return self.vtable.list(self.ptr, allocator);
    }

    pub fn close(self: Store) void {
        self.vtable.close(self.ptr);
    }
};
