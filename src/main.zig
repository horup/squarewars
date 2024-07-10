const std = @import("std");
const Platform = @import("platform.zig");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const RaylibPlatform = struct {
    allocator: std.mem.Allocator,
    fn platform(this: RaylibPlatform) Platform {
        return Platform{ .allocator = this.allocator, .ptr = this, .vtable = .{ .drawText = drawText } };
    }

    fn drawText(_: @This(), text: *const u8, posX: f32, posY: f32, height: f32, color: i32) void {
        ray.DrawText(text, posX, posY, height, color);
    }
};

pub fn main() !void {
    const width = 800;
    const height = 450;

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

    const colors = [_]ray.Color{ ray.GRAY, ray.RED, ray.GOLD, ray.LIME, ray.BLUE, ray.VIOLET, ray.BROWN };
    const colors_len: i32 = @intCast(colors.len);
    var current_color: i32 = 2;
    var hint = true;

    while (!ray.WindowShouldClose()) {
        // input
        var delta: i2 = 0;
        if (ray.IsKeyPressed(ray.KEY_UP)) delta += 1;
        if (ray.IsKeyPressed(ray.KEY_DOWN)) delta -= 1;
        if (delta != 0) {
            current_color = @mod(current_color + delta, colors_len);
            hint = false;
        }

        // draw
        {
            ray.BeginDrawing();
            defer ray.EndDrawing();

            ray.ClearBackground(colors[@intCast(current_color)]);
            if (hint) ray.DrawText("press up or down arrow to change background color", 120, 140, 20, ray.BLUE);
            ray.DrawText("Congrats! You created your first window!", 190, 200, 20, ray.BLACK);

            // now lets use an allocator to create some dynamic text
            // pay attention to the Z in `allocPrintZ` that is a convention
            // for functions that return zero terminated strings
            const seconds: u32 = @intFromFloat(ray.GetTime());
            const dynamic = try std.fmt.allocPrintZ(allocator, "running since {d} seconds", .{seconds});
            defer allocator.free(dynamic);
            ray.DrawText(dynamic, 300, 250, 20, ray.WHITE);

            ray.DrawFPS(width - 100, 10);
        }
    }
}
