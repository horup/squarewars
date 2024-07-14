const Rect = @import("Rect.zig");
const Vec2 = @import("Vec2.zig");
const Game = @import("Game.zig");
const Thing = @This();
const Key = @import("arena.zig").Key;
const Platform = @import("Platform.zig");
pos: Vec2 = .{},
vel: Vec2 = .{},
size: f32 = 16.0,
update: ?*const fn (game: *Game, me: Key, dt: f32) void = null,
contact: ?*const fn (game: *Game, me: Key, other: Key) void = null,

pub fn rect(self: *const Thing) Rect {
    return .{
        .x = self.pos.x - self.size / 2.0,
        .y = self.pos.y - self.size / 2.0,
        .w = self.size,
        .h = self.size,
    };
}

pub fn playerContact(game: *Game, me: Key, _: Key) void {
    game.things.delete(me);
}

pub fn enemyContact(game: *Game, me: Key, _: Key) void {
    game.things.delete(me);
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
