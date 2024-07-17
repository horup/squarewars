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

pub fn spawnPlayer(game: *Game, pos: Vec2) Key {
    const player = game.things.insert(.{
        .pos = pos,
        .update = &Thing.playerUpdate,
        .contact = &Thing.playerContact,
    });
    return player;
}
pub fn spawnEnemy(game: *Game, pos: Vec2) Key {
    const enemy = game.things.insert(.{
        .pos = pos,
        .update = Thing.enemyUpdate,
        .contact = Thing.enemyContact,
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

pub fn playerContact(game: *Game, me: Key, other: Key) void {
    thingContact(game, me, other);
    game.player = null;
}

pub fn enemyContact(game: *Game, me: Key, other: Key) void {
    thingContact(game, me, other);
}

pub fn thingContact(game: *Game, me: Key, _: Key) void {
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
            .vel = v.mul_scalar(60.0),
            .update = debrisUpdate,
        });
    }

    game.things.delete(me);
}

pub fn debrisUpdate(game: *Game, me: Key, dt: f32) void {
    if (game.things.get(me)) |thing| {
        thing.size -= dt * 10.0;
        if (thing.size <= 0.0) {
            thing.size = 0.0;
            game.things.delete(me);
        }
    }
}

pub fn thingPostUpdate(game: *Game, me: Key, _: f32) void {
    if (game.things.get(me)) |thing| {
        const min, const max = .{ 16.0, Game.HEIGHT - 16.0 };
        if (thing.pos.y < min) {
            thing.pos.y = min;
        } else if (thing.pos.y > max) {
            thing.pos.y = max;
        }
    }
}

pub fn playerUpdate(game: *Game, me: Key, _: f32) void {
    const thing = game.things.get(me).?;
    var platform = game.platform;
    var v: Vec2 = .{};
    if (platform.isKeyDown(Platform.Key.w)) {
        v.y = -1.0;
    } else if (platform.isKeyDown(Platform.Key.s)) {
        v.y = 1.0;
    }
    const speed = 200.0;
    v = v.mul_scalar(speed);
    thing.vel = v;
}

pub fn enemyUpdate(game: *Game, me: Key, _: f32) void {
    const thing = game.things.get(me).?;
    thing.vel.x = -160.0;
    if (thing.pos.x < 0.0) {
        game.things.delete(me);
    }
}
