const Platform = @import("platform.zig");
const Game = @This();

platform: *Platform,
score: i32,
time_elapsed_sec: f32,
fn update(self: *Game, dt: f32) void {
    self.platform.drawText("SquareWars!", 16.0, 16.0, 16.0, 0xFF0000);
    self.time_elapsed_sec += dt;
}
