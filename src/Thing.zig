const Vec2 = @import("Vec2.zig");
const Game = @import("Game.zig");
const Thing = @This();
const Platform = @import("Platform.zig");
pos: Vec2 = .{},
vel: Vec2 = .{},
size: f32 = 16.0,
update: ?*const fn (game: *Game, me: *Thing, dt: f32) void = null,

pub fn playerUpdate(game: *Game, me: *Thing, dt: f32) void {
    var platform = game.platform;
    var v: Vec2 = .{};
    if (platform.isKeyDown(Platform.Key.w)) {
        v.y = -1.0;
    } else if (platform.isKeyDown(Platform.Key.s)) {
        v.y = 1.0;
    }
    const speed = 240.0;
    v = v.mul_scalar(speed).mul_scalar(dt);
    me.pos = me.pos.add(v);
}

pub fn enemyUpdate(_: *Game, me: *Thing, dt: f32) void {
    me.pos.x -= dt;
}
