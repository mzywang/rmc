const std = @import("std");

pub const Store = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        get: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator, key: []const u8) anyerror!?[]u8,
        put: *const fn (ptr: *anyopaque, key: []const u8, value: []const u8) anyerror!void,
        delete: *const fn (ptr: *anyopaque, key: []const u8) anyerror!void,
        close: *const fn (ptr: *anyopaque) void,
    };

    pub fn get(self: Store, allocator: std.mem.Allocator, key: []const u8) !?[]u8 {
        return self.vtable.get(self.ptr, allocator, key);
    }

    pub fn put(self: Store, key: []const u8, value: []const u8) !void {
        return self.vtable.put(self.ptr, key, value);
    }

    pub fn delete(self: Store, key: []const u8) !void {
        return self.vtable.delete(self.ptr, key);
    }

    pub fn close(self: Store) void {
        self.vtable.close(self.ptr);
    }
};
