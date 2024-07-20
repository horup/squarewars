const std = @import("std");
const Rect = @import("Rect.zig");
const Vec2 = @import("Vec2.zig");
const Game = @import("Game.zig");
const Thing = @This();
const Key = @import("arena.zig").Key;
const Platform = @import("Platform.zig");
pos: Vec2 = .{},
vel: Vec2 = .{},
size: f32 = 16.0,
solid: bool = true,
update: ?*const fn (game: *Game, me: Key, dt: f32) void = null,
post_update: ?*const fn (game: *Game, me: Key, dt: f32) void = null,
contact: ?*const fn (game: *Game, me: Key, other: Key) void = null,
ignore_contact: ?Key = null,
ignore_group: ?u8 = null,
cooldown_gun: f32 = 0.0,
firerate_gun: f32 = 0.33,
trigger_gun: bool = false,
dir_gun: Vec2 = .{ .x = 1.0, .y = 0.0 },

pub fn spawnPlayer(game: *Game, pos: Vec2) Key {
    const player = game.things.insert(.{
        .pos = pos,
        .update = &Thing.updatePlayer,
        .contact = &Thing.contactPlayer,
        .post_update = &Thing.postUpdatePlayer,
    });
    return player;
}
pub fn spawnEnemy(game: *Game, pos: Vec2) Key {
    const enemy = game.things.insert(.{
        .pos = pos,
        .update = Thing.updateEnemy,
        .contact = Thing.contactEnemy,
    });
    return enemy;
}

pub fn rect(self: *const Thing) Rect {
    return .{
        .x = self.pos.x - self.size / 2.0,
        .y = self.pos.y - self.size / 2.0,
        .w = self.size,
        .h = self.size,
    };
}

pub fn contactPlayer(game: *Game, me: Key, other: Key) void {
    contactThing(game, me, other);
    game.player = null;
}

pub fn contactEnemy(game: *Game, me: Key, other: Key) void {
    contactThing(game, me, other);
}

pub fn contactThing(game: *Game, me: Key, _: Key) void {
    var pos: Vec2 = .{};
    if (game.things.get(me)) |thing| {
        pos = thing.pos;
    }
    const l = 16;
    for (0..l) |i| {
        const f: f32 = @floatFromInt(i);
        const a = f / l * std.math.pi * 2.0;
        const v: Vec2 = .{ .x = std.math.cos(a), .y = std.math.sin(a) };
        _ = game.things.insert(.{
            .solid = false,
            .size = 8.0,
            .pos = pos,
            .vel = v.mul(f32, 60.0),
            .update = updateDebris,
        });
    }

    game.things.delete(me);
}

pub fn updateDebris(game: *Game, me: Key, dt: f32) void {
    if (game.things.get(me)) |thing| {
        thing.size -= dt * 10.0;
        if (thing.size <= 0.0) {
            thing.size = 0.0;
            game.things.delete(me);
        }
    }
}

pub fn postUpdatePlayer(game: *Game, me: Key, _: f32) void {
    if (game.things.get(me)) |thing| {
        const min_y, const max_y = .{ 16.0, Game.HEIGHT - 16.0 };
        const min_x, const max_x = .{ 16.0, Game.WIDTH - 64.0 };
        if (thing.pos.y < min_y) {
            thing.pos.y = min_y;
        } else if (thing.pos.y > max_y) {
            thing.pos.y = max_y;
        }
        if (thing.pos.x < min_x) {
            thing.pos.x = min_x;
        } else if (thing.pos.x > max_x) {
            thing.pos.x = max_x;
        }
    }
}

fn contactProjectile(game: *Game, me: Key, _: Key) void {
    game.things.delete(me);
}

fn updateThing(game: *Game, me: Key, dt: f32) void {
    if (game.things.get(me)) |thing| {
        thing.cooldown_gun -= dt;
        if (thing.cooldown_gun < 0.0) {
            thing.cooldown_gun = 0.0;
        }
        const margin = 128.0;
        if (thing.pos.x < -margin or thing.pos.x > Game.WIDTH + margin) {
            game.things.delete(me);
            return;
        }

        if (thing.cooldown_gun == 0.0 and thing.trigger_gun == true) {
            // spawn bullet
            const v = thing.dir_gun.mul(f32, 200.0);
            thing.cooldown_gun = 0.33;
            _ = game.things.insert(.{
                .pos = thing.pos,
                .vel = v,
                .size = 4.0,
                .ignore_contact = me,
                .ignore_group = 1,
                .update = updateThing,
                .contact = contactProjectile,
            });
        }
    }
}

pub fn updatePlayer(game: *Game, me: Key, dt: f32) void {
    const thing = game.things.get(me).?;
    var platform = game.platform;
    var v: Vec2 = .{};
    if (platform.isKeyDown(Platform.Key.w)) {
        v.y = -1.0;
    } else if (platform.isKeyDown(Platform.Key.s)) {
        v.y = 1.0;
    }
    if (platform.isKeyDown(Platform.Key.a)) {
        v.x = -1.0;
    } else if (platform.isKeyDown(Platform.Key.d)) {
        v.x = 1.0;
    }
    thing.trigger_gun = platform.isKeyDown(Platform.Key.space);
    const speed = 200.0;
    v = v.normalize().mul(f32, speed);
    thing.vel = v;
    updateThing(game, me, dt);
}

pub fn updateEnemy(game: *Game, me: Key, dt: f32) void {
    const thing = game.things.get(me).?;
    thing.vel.x = -160.0;
    if (thing.pos.x < Game.WIDTH - 64.0) {
        thing.trigger_gun = true;
    }
    if (thing.pos.x < 64.0) {
        thing.trigger_gun = false;
    }
    if (game.player) |player| {
        if (game.things.get(player)) |thing_player| {
            const n = thing_player.pos.sub(thing.pos).normalize();
            thing.dir_gun = n;
        }
    } else {
        thing.trigger_gun = false;
    }
    updateThing(game, me, dt);
}
