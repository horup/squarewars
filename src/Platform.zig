const std = @import("std");
pub const Color = struct { r: u8 = 255, g: u8 = 255, b: u8 = 255, a: u8 = 255 };
const Self = @This();
ptr: *anyopaque,
vtable: struct { drawText: *const fn (ptr: *anyopaque, text: []const u8, posX: f32, posY: f32, height: f32, color: Color) void, measureText: *const fn (ptr: *anyopaque, text: []const u8, height: f32) f32 },
allocator: std.mem.Allocator,
pub fn drawText(self: *Self, text: []const u8, posX: f32, posY: f32, height: f32, color: Color) void {
    self.vtable.drawText(self.ptr, text, posX, posY, height, color);
}
pub fn measureText(self: *Self, text: []const u8, height: f32) f32 {
    return self.vtable.measureText(self.ptr, text, height);
}
