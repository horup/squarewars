const std = @import("std");
const Platform = @import("platform.zig");
const Game = @import("game.zig");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const RaylibPlatform = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) RaylibPlatform {
        return RaylibPlatform{ .allocator = allocator };
    }

    fn platform(this: *RaylibPlatform) Platform {
        return Platform{ .allocator = this.allocator, .ptr = this, .vtable = .{ .drawText = @ptrCast(&drawText) } };
    }

    fn drawText(_: Self, text: []const u8, posX: f32, posY: f32, height: f32, color: ray.Color) void {
        ray.DrawText(@ptrCast(text), @intFromFloat(posX), @intFromFloat(posY), @intFromFloat(height), color);
    }
};

pub fn main() !void {
    const width = 640;
    const height = 480;

    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT | ray.FLAG_VSYNC_HINT);
    ray.InitWindow(width, height, "SquareWars!");
    defer ray.CloseWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 8 }){};
    const allocator = gpa.allocator();
    defer {
        switch (gpa.deinit()) {
            .leak => @panic("leaked memory"),
            else => {},
        }
    }

    var platform = RaylibPlatform.init(allocator);
    var game = Game.init(platform.platform());

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.BLACK);

        ray.DrawText("Congrats! You created your first window!", 190, 200, 20, ray.BLACK);

        const dt = ray.GetFrameTime();
        //const dynamic = try std.fmt.allocPrintZ(allocator, "running since {d} seconds", .{seconds});
        //defer allocator.free(dynamic);
        game.update(dt);
    }
}
