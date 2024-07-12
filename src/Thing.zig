const Vec2 = @import("Vec2.zig");
const Game = @import("Game.zig");
const Thing = @This();
const Platform = @import("Platform.zig");
pos: Vec2 = .{},
vel: Vec2 = .{},
size: f32 = 16.0,
update: ?*const fn (game: *Game, me: *Thing) void = null,

pub fn playerUpdate(game: *Game, me: *Thing) void {
    var platform = game.platform;
    var v: Vec2 = .{};
    if (platform.isKeyDown(Platform.Key.up)) {
        v.y = -1.0;
    } else if (platform.isKeyDown(Platform.Key.down)) {
        v.y = 1.0;
    }

    me.pos = me.pos.add(v);
}
