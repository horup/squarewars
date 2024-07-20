const Game = @This();
const std = @import("std");
const Vec2 = @import("Vec2.zig");
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
respawn_countdown: f32 = 2.0,

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
    self.delay_countdown = 1.0;
    self.state = state;
    if (state == State.gaming) {
        self.respawn_countdown = 2.0;
        self.score = 0;
        self.things.clear();
        self.game_time = 0.0;
        self.spawn_countdown = 0;
        const player = Thing.spawnPlayer(self, .{ .x = 32.0, .y = Game.HEIGHT / 2.0 });
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
        const new_pos = thing.pos.add(thing.vel.mul(f32, dt));
        thing.pos = new_pos;
        if (!thing.solid) {
            continue;
        }

        var things2 = self.things.iter();
        while (things2.next()) |kv2| {
            const key2, const thing2 = kv2;
            if (key.equals(key2)) {
                continue;
            }
            if (thing.ignore_contact) |ignore1| {
                if (key2.equals(ignore1)) {
                    continue;
                }
            }
            if (thing2.ignore_contact) |ignore2| {
                if (key.equals(ignore2)) {
                    continue;
                }
            }
            if (thing.ignore_group == thing2.ignore_group) {
                continue;
            }
            if (!thing2.solid) {
                continue;
            }
            const r1 = thing.rect();
            const r2 = thing2.rect();
            if (r1.intersects(r2)) {
                self.contacts.append(.{ key, key2 }) catch unreachable;
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

fn draw_star(g: *Game, x: f32, y: f32) void {
    const outer_color = .{ .a = 128 };
    const inner_color = .{ .a = 255 };
    g.platform.drawSquare(x, y, 1.0, inner_color);
    g.platform.drawSquare(x, y + 1.0, 1.0, outer_color);
    g.platform.drawSquare(x + 1.0, y, 1.0, outer_color);
    g.platform.drawSquare(x, y - 1.0, 1.0, outer_color);
    g.platform.drawSquare(x - 1.0, y, 1.0, outer_color);
}

fn draw_stars(g: *Game, _: f32) void {
    var xosh = std.rand.DefaultPrng.init(0);
    const random = &xosh.random();
    for (0..6) |row| {
        for (0..6) |col| {
            const speed = 128.0;
            const col_f: f32 = @floatFromInt(col);
            const row_f: f32 = @floatFromInt(row);
            var x: f32 = col_f / 6.0 * Game.WIDTH - g.game_time * speed + random.float(f32) * 32.0;
            x = @mod(x, Game.WIDTH);
            const y: f32 = row_f / 6.0 * Game.HEIGHT + random.float(f32) * 32.0 + 8.0;
            g.draw_star(x, y);
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

    const score = std.fmt.allocPrintZ(platform.allocator, "SCORE: {d}", .{self.score}) catch unreachable;
    defer platform.allocator.free(score);
    platform.drawText(score, Game.WIDTH / 2.0, 16.0, 16.0, .{});
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

fn post_update_things(self: *Game, dt: f32) void {
    var things = self.things.iter();
    while (things.next()) |kv| {
        const key, const thing = kv;
        if (thing.post_update) |f| {
            f(self, key, dt);
        }
    }
}

fn update_gaming(self: *Game, dt: f32) void {
    var platform = self.platform;
    self.update_things(dt);
    self.physics(dt);
    self.process_contacts();
    self.post_update_things(dt);
    self.draw(dt);

    if (self.game_time > 5.0) {
        // spawn enemeis
        self.spawn_countdown -= dt;
        if (self.spawn_countdown <= 0.0) {
            const margin = 16.0;
            const x = Game.WIDTH + margin;
            const y = self.spawn_pos * (Game.HEIGHT - margin * 2.0) + margin;
            _ = Thing.spawnEnemy(self, .{ .x = x, .y = y });
            self.spawn_countdown = 1.0;
            self.spawn_pos += 0.1;
            if (self.spawn_pos > 1.0) {
                self.spawn_pos = 0.0;
            }
        }
    } else {
        // show instructions
        const center_x = Game.WIDTH / 2.0;
        const text_y = 64.0;
        const height = 16.0;
        {
            const s = "Fly up and down using 'W' and 'S'\n\nShoot using 'Space'\n\nSurvive as long as you can!";
            platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, text_y - height, height, Platform.Color{});
        }
    }

    if (self.player == null) {
        // play is no more, allow respawning after some time
        self.respawn_countdown -= dt;
        if (self.respawn_countdown <= 1.0) {
            const center_x = Game.WIDTH / 2.0;
            const center_y = Game.HEIGHT / 2.0;
            const height = 32.0;
            {
                const s = "YOU WERE";
                platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, center_y - height, height, Platform.Color{});
            }
            {
                const s = "DESTROYED!";
                platform.drawText(s, center_x - platform.measureText(s, height) / 2.0, center_y, height, Platform.Color{});
            }
            if (self.respawn_countdown <= 0.0) {
                if (self.is_signal()) {
                    const s = "---- Press Space ----";
                    platform.drawText(s, center_x - platform.measureText(s, height / 2.0) / 2.0, center_y + height + height / 2.0, height / 2.0, Platform.Color{});
                }
                if (self.is_input_allowed()) {
                    if (platform.isKeyPressed(Platform.Key.space)) {
                        set_state(self, State.gaming);
                    }
                }
            }
        }
    } else {
        // progress game time while alive
        self.game_time += dt;
    }
}

pub fn update(self: *Game, dt: f32) void {
    self.draw_stars(dt);
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
