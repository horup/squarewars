const std = @import("std");
const Vec2 = @This();
x: f32 = 0.0,
y: f32 = 0.0,
pub fn add(self: Vec2, other: Vec2) Vec2 {
    return Vec2{ .x = self.x + other.x, .y = self.y + other.y };
}
pub fn sub(self: Vec2, other: Vec2) Vec2 {
    return Vec2{ .x = self.x - other.x, .y = self.y - other.y };
}
pub fn length(self: Vec2) f32 {
    return std.math.sqrt(self.x * self.x + self.y * self.y);
}
