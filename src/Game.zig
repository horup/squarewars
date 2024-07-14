const Game = @This();
const std = @import("std");
const Platform = @import("Platform.zig");
const Thing = @import("Thing.zig");
const arena = @import("arena.zig");
const Arena = arena.Arena;
const Key = arena.Key;
const Contact = struct { Key, Key };
pub const WIDTH: f32 = 320.0;
pub const HEIGHT: f32 = 240.0;
const State = enum {
    title,
    gaming,
};
contacts: std.ArrayList(Contact),
things: Arena(Thing),
state: State = State.title,
platform: Platform,
score: i32 = 0.0,
player: ?Key = null,
game_time: f32 = 0.0,
timer_1hz: f32 = 0.0,
delay_countdown: f32 = 0.5,
spawn_countdown: f32 = 0.0,
xosh: std.rand.DefaultPrng = std.rand.DefaultPrng.init(0),
spawn_pos: f32 = 0.0,

pub fn init(platform: Platform) Game {
    return Game{
        .contacts = std.ArrayList(Contact).init(platform.allocator),
        .platform = platform,
        .things = Arena(Thing).init(platform.allocator),
    };
}

pub fn deinit(self: *Game) void {
    self.things.deinit();
    self.contacts.deinit();
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
        self.spawn_countdown = 0;

        const player = self.things.insert(.{
            .pos = .{ .x = 64.0, .y = Game.HEIGHT / 2.0 },
            .update = &Thing.playerUpdate,
            .contact = &Thing.playerContact,
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

fn physics(self: *Game, dt: f32) void {
    self.contacts.clearRetainingCapacity();
    var things = self.things.iter();

    while (things.next()) |kv| {
        const key, const thing = kv;
        const new_pos = thing.pos.add(thing.vel.mul_scalar(dt));
        thing.pos = new_pos;
        var things2 = self.things.iter();
        while (things2.next()) |kv2| {
            const key2, const thing2 = kv2;
            if (key.equals(key2) == false) {
                const r1 = thing.rect();
                const r2 = thing2.rect();
                if (r1.intersects(r2)) {
                    self.contacts.append(.{ key, key2 }) catch unreachable;
                }
            }
        }
    }
}

fn process_contacts(self: *Game) void {
    for (self.contacts.items, 0..self.contacts.items.len) |contact, _| {
        const key1, const key2 = contact;
        if (self.things.get(key1)) |thing| {
            if (thing.contact) |contact_fn| {
                contact_fn(self, key1, key2);
            }
        }
        if (self.things.get(key2)) |thing| {
            if (thing.contact) |contact_fn| {
                contact_fn(self, key2, key1);
            }
        }
    }
}

fn draw(self: *Game, _: f32) void {
    var platform = self.platform;
    var things = self.things.iter();
    while (things.next()) |kv| {
        _, const thing = kv;
        const x = thing.pos.x - thing.size / 2.0;
        const y = thing.pos.y - thing.size / 2.0;
        const size = thing.size;
        const color = .{ .g = 255 };
        platform.drawSquare(x, y, size, color);
    }
}

fn update_things(self: *Game, dt: f32) void {
    var things = self.things.iter();
    while (things.next()) |kv| {
        const key, const thing = kv;
        if (thing.update) |f| {
            f(self, key, dt);
        }
    }
}

fn update_gaming(self: *Game, dt: f32) void {
    self.update_things(dt);
    self.physics(dt);
    self.process_contacts();
    self.draw(dt);

    self.spawn_countdown -= dt;
    if (self.spawn_countdown <= 0.0) {
        const margin = 16.0;
        const x = Game.WIDTH - margin;
        const y = self.spawn_pos * (Game.HEIGHT - margin * 2.0) + margin;
        _ = self.things.insert(.{
            .pos = .{ .x = x, .y = y },
            .update = Thing.enemyUpdate,
        });
        self.spawn_countdown = 1.0;
        self.spawn_pos += 0.1;
        if (self.spawn_pos > 1.0) {
            self.spawn_pos = 0.0;
        }
    }

    self.game_time += dt;
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
