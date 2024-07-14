const Vec2 = @import("Vec2.zig");
const Game = @import("Game.zig");
const Thing = @This();
const Key = @import("arena.zig").Key;
const Platform = @import("Platform.zig");
pos: Vec2 = .{},
vel: Vec2 = .{},
size: f32 = 16.0,
update: ?*const fn (game: *Game, me: Key, dt: f32) void = null,

pub fn playerUpdate(game: *Game, me: Key, dt: f32) void {
    const thing = game.things.get(me).?;
    var platform = game.platform;
    var v: Vec2 = .{};
    if (platform.isKeyDown(Platform.Key.w)) {
        v.y = -1.0;
    } else if (platform.isKeyDown(Platform.Key.s)) {
        v.y = 1.0;
    }
    const speed = 240.0;
    v = v.mul_scalar(speed).mul_scalar(dt);
    thing.pos = thing.pos.add(v);
}

pub fn enemyUpdate(game: *Game, me: Key, dt: f32) void {
    const thing = game.things.get(me).?;
    thing.pos.x -= dt * Game.WIDTH / 2.0;

    if (thing.pos.x < 0.0) {
        // despawn
    }
}
