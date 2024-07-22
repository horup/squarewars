const std = @import("std");
const Self = @This();
const file_path = "highscore.json";
score: i32 = 0,
time: f32 = 0.0,

pub fn load(self: *Self, allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile(file_path, .{});
    const json = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(json);
    const parsed = try std.json.parseFromSlice(Self, allocator, json, .{});
    defer parsed.deinit();
    self.score = parsed.value.score;
    self.time = parsed.value.time;
}

pub fn save(self: *Self, allocator: std.mem.Allocator) !void {
    const json = try std.json.stringifyAlloc(allocator, self, .{});
    defer allocator.free(json);
    try std.fs.cwd().writeFile(.{ .sub_path = file_path, .data = json });
}
