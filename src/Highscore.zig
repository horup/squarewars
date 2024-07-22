const std = @import("std");
const Self = @This();
score: i32 = 0,
time: f32 = 0.0,

pub fn load(self: *Self, allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile("highscore.json", .{});
    const json = try file.readToEndAlloc(allocator, 1024);
    const parsed = try std.json.parseFromSlice(Self, allocator, json, .{});
    self.score = parsed.value.score;
    self.time = parsed.value.time;
    std.debug.print("TEST", .{});
}

pub fn save(_: *Self) void {}
