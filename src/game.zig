const std = @import("std");
const Platform = @import("platform.zig");
const Game = @This();
const WIDTH: f32 = 320.0;
const HEIGHT: f32 = 240.0;

platform: Platform,
score: i32,
time_elapsed_sec: f32,

pub fn init(platform: Platform) Game {
    return Game{
        .platform = platform,
        .score = 0,
        .time_elapsed_sec = 0.0,
    };
}

pub fn update(self: *Game, dt: f32) void {
    var platform = self.platform;
    const center_x = WIDTH / 2.0;
    const center_y = HEIGHT / 2.0;
    platform.drawText("Square", center_x, center_y, 32.0, Platform.Color{});
    platform.drawText("Wars!", center_x, center_y + 32.0, 32.0, Platform.Color{});
    self.time_elapsed_sec += dt;
}
