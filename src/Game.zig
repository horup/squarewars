const std = @import("std");
const Platform = @import("platform.zig");
const Thing = @import("Thing.zig");
const Arena = @import("arena.zig").Arena;
const Game = @This();
const WIDTH: f32 = 320.0;
const HEIGHT: f32 = 240.0;
const State = enum {
    title,
    gaming,
};
things: Arena(Thing),
state: State = State.title,
platform: Platform,
score: i32 = 0.0,
time_elapsed: f32 = 0.0,
timer_1hz: f32 = 0.0,
delay_countdown: f32 = 1.0,

pub fn init(platform: Platform) Game {
    return Game{
        .platform = platform,
        .things = Arena(Thing).init(platform.allocator),
    };
}

pub fn is_signal(self: *Game) bool {
    if (self.timer_1hz > 0.5) {
        return true;
    } else {
        return false;
    }
}

fn is_input_allowed(self: *Game) bool {
    return self.delay_countdown <= 0.0;
}

fn goto_state(self: *Game, state: State) void {
    if (self.state != state) {
        self.state = state;
        self.delay_countdown = 1.0;
    }
}

fn update_title(self: *Game, _: f32) void {
    const center_x = WIDTH / 2.0;
    const center_y = HEIGHT / 2.0;
    const height = 32.0;
    var platform = self.platform;

    {
        const s = "Square";
        platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, center_y - height, height, Platform.Color{});
    }
    {
        const s = "Wars!";
        platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, center_y, height, Platform.Color{});
    }
    if (self.is_signal()) {
        const s = "---- Press Space ----";
        platform.drawText(s, center_x - platform.measureText(s, height / 2.0) / 2.0, center_y + height + height / 2.0, height / 2.0, Platform.Color{});
    }

    if (self.is_input_allowed()) {
        if (platform.isKeyPressed(Platform.Key.space)) {
            self.state = State.gaming;
        }
    }
}

fn update_gaming(_: *Game, _: f32) void {}

pub fn update(self: *Game, dt: f32) void {
    switch (self.state) {
        State.title => {
            self.update_title(dt);
        },
        State.gaming => {
            self.update_gaming(dt);
        },
    }

    self.time_elapsed += dt;
    self.timer_1hz += dt;
    if (self.timer_1hz > 1.0) {
        self.timer_1hz = 0.0;
    }
    self.delay_countdown -= dt;
    if (self.delay_countdown < 0.0) {
        self.delay_countdown = 0.0;
    }
}
