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
    const height = 32.0;
    {
        const s = "Square";
        platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, center_y - height, height, Platform.Color{});
    }
    {
        const s = "Wars!";
        platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, center_y + height - height, height, Platform.Color{});
    }
    self.time_elapsed_sec += dt;
}
