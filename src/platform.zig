const std = @import("std");

ptr: *anyopaque,
vtable: struct { drawText: *const fn (ptr: *anyopaque, text: *const u8, posX: f32, posY: f32, height: f32, color: i32) void },
allocator: std.mem.Allocator,

pub fn drawText(self: @This(), text: *const u8, posX: f32, posY: f32, height: f32, color: i32) void {
    self.vtable.drawText(self.ptr, text, posX, posY, height, color);
}
