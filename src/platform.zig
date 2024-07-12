const std = @import("std");
pub const Color = struct {
    r: u8 = 255,
    g: u8 = 255,
    b: u8 = 255,
    a: u8 = 255,
};

pub const Key = enum(i32) {
    up = 265,
    down = 264,
    left = 3,
    right = 4,
    space = 32,
};

const Self = @This();
ptr: *anyopaque,
vtable: struct {
    isKeyDown: *const fn (ptr: *anyopaque, key: Key) bool,
    isKeyPressed: *const fn (ptr: *anyopaque, key: Key) bool,
    drawText: *const fn (ptr: *anyopaque, text: []const u8, posX: f32, posY: f32, height: f32, color: Color) void,
    measureText: *const fn (ptr: *anyopaque, text: []const u8, height: f32) f32,
    drawSquare: *const fn (ptr: *anyopaque, posX: f32, posY: f32, size: f32, color: Color) void,
},
allocator: std.mem.Allocator,

pub fn drawText(self: *Self, text: []const u8, posX: f32, posY: f32, height: f32, color: Color) void {
    self.vtable.drawText(self.ptr, text, posX, posY, height, color);
}

pub fn measureText(self: *Self, text: []const u8, height: f32) f32 {
    return self.vtable.measureText(self.ptr, text, height);
}

pub fn isKeyDown(self: *Self, key: Key) bool {
    return self.vtable.isKeyDown(self.ptr, key);
}

pub fn isKeyPressed(self: *Self, key: Key) bool {
    return self.vtable.isKeyPressed(self.ptr, key);
}

pub fn drawSquare(self: *Self, posX: f32, posY: f32, size: f32, color: Color) void {
    self.vtable.drawSquare(self.ptr, posX, posY, size, color);
}
