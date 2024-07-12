const Game = @This();
const std = @import("std");
const Platform = @import("platform.zig").Platform;
const Thing = @import("Thing.zig");
const arena = @import("arena.zig");
const Arena = arena.Arena;
const Key = arena.Key;
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
player: ?Key = null,
game_time: f32 = 0.0,
timer_1hz: f32 = 0.0,
delay_countdown: f32 = 0.5,

pub fn init(platform: Platform) Game {
    return Game{
        .platform = platform,
        .things = Arena(Thing).init(platform.allocator),
    };
}

pub fn deinit(self: *Game) void {
    self.things.deinit();
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

fn set_state(self: *Game, state: State) void {
    if (self.state != state) {
        self.state = state;
        self.delay_countdown = 1.0;
    }

    if (state == State.gaming) {
        // reset game
        self.score = 0;
        self.things.clear();
        self.game_time = 0.0;

        const player = self.things.insert(.{
            .pos = .{ .x = 64.0, .y = Game.HEIGHT / 2.0 },
            .update = &Thing.playerUpdate,
        });

        self.player = player;
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
            self.set_state(State.gaming);
        }
    }
}

fn update_gaming(self: *Game, dt: f32) void {
    var platform = self.platform;
    self.game_time += dt;
    var things = self.things.iter();
    while (things.next()) |thing| {
        const x = thing.pos.x;
        const y = thing.pos.y;
        const size = thing.size;
        const color = .{ .g = 255 };
        if (thing.update) |f| {
            f(@ptrCast(self), thing);
        }
        platform.drawSquare(x, y, size, color);
    }
}

pub fn update(self: *Game, dt: f32) void {
    switch (self.state) {
        State.title => {
            self.update_title(dt);
        },
        State.gaming => {
            self.update_gaming(dt);
        },
    }

    self.timer_1hz += dt;
    if (self.timer_1hz > 1.0) {
        self.timer_1hz = 0.0;
    }
    self.delay_countdown -= dt;
    if (self.delay_countdown < 0.0) {
        self.delay_countdown = 0.0;
    }
}
