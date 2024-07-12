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

    fn scale(_: *RaylibPlatform) i32 {
        return 2;
    }

    fn init(allocator: std.mem.Allocator) RaylibPlatform {
        return RaylibPlatform{ .allocator = allocator };
    }

    fn platform(this: *RaylibPlatform) Platform {
        return Platform{ .allocator = this.allocator, .ptr = this, .vtable = .{
            .drawText = @ptrCast(&drawText),
            .measureText = @ptrCast(&measureText),
            .isKeyDown = @ptrCast(&isKeyDown),
            .isKeyPressed = @ptrCast(&isKeyPressed),
            .drawSquare = @ptrCast(&drawSquare),
        } };
    }

    fn drawText(self: *Self, text: []const u8, posX: f32, posY: f32, height: f32, color: ray.Color) void {
        const c = self.scale();
        const x: i32 = @intFromFloat(posX);
        const y: i32 = @intFromFloat(posY);
        const h: i32 = @intFromFloat(height);
        ray.DrawText(@ptrCast(text), x * c, y * c, h * c, color);
    }

    fn measureText(_: *Self, text: []const u8, height: f32) f32 {
        const h: i32 = @intFromFloat(height);
        const w = ray.MeasureText(@ptrCast(text), h);
        return @floatFromInt(w);
    }

    fn isKeyDown(_: *Self, key: i32) bool {
        return ray.IsKeyDown(key);
    }

    fn isKeyPressed(_: *Self, key: i32) bool {
        return ray.IsKeyPressed(key);
    }

    fn drawSquare(_: *Self, posX: f32, posY: f32, size: f32, color: ray.Color) void {
        const x: i32 = @intFromFloat(posX);
        const y: i32 = @intFromFloat(posY);
        const s: i32 = @intFromFloat(size);
        ray.DrawRectangle(x, y, s, s, color);
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
        const dt = ray.GetFrameTime();
        game.update(dt);
        ray.DrawRectangle(10, 10, 10, 10, ray.WHITE);

        //const dynamic = try std.fmt.allocPrintZ(allocator, "running since {d} seconds", .{seconds});
        //defer allocator.free(dynamic);
    }
}
