const std = @import("std");
pub const Key = struct { index: u32, generation: u32 };
pub fn Arena(comptime T: type) type {
    const Cell = struct { key: Key, value: T, in_use: bool };
    const KeyValue = struct { key: Key, value: *T };

    const ArenaIterator = struct {
        arena: *Arena(T),
        index: usize,
        pub fn next(self: *@This()) ?KeyValue {
            while (self.index < self.arena.cells.items.len) {
                defer self.index += 1;
                if (self.arena.cells.items[self.index].in_use) {
                    return .{
                        .key = self.arena.cells.items[self.index].key,
                        .value = &self.arena.cells.items[self.index].value,
                    };
                }
            }

            return null;
        }
    };
    return struct {
        cells: std.ArrayList(Cell),
        free: std.ArrayList(usize),
        len: usize,
        pub fn init(allocator: std.mem.Allocator) Arena(T) {
            return Arena(T){ .len = 0, .cells = std.ArrayList(Cell).init(allocator), .free = std.ArrayList(usize).init(allocator) };
        }

        pub fn insert(self: *Arena(T), v: T) Key {
            self.len += 1;
            const free = self.free.popOrNull();
            if (free) |i| {
                var cell = &self.cells.items[i];
                cell.key.generation += 1;
                cell.value = v;
                cell.in_use = true;
                return cell.key;
            } else {
                const new_key = Key{ .index = @intCast(self.cells.items.len), .generation = 0 };
                self.cells.append(.{ .key = new_key, .value = v, .in_use = true }) catch unreachable;
                return new_key;
            }
        }

        pub fn delete(self: *Arena(T), key: Key) void {
            const index: usize = @intCast(key.index);
            var cell = &self.cells.items.ptr[index];
            if (cell.in_use == true) {
                self.len -= 1;
                cell.in_use = false;
                self.free.append(index) catch unreachable;
            }
        }

        pub fn clear(self: *Arena(T)) void {
            self.len = 0;
            for (self.cells.items, 0..self.cells.items.len) |*cell, index| {
                if (cell.in_use) {
                    cell.in_use = false;
                    self.free.append(index) catch unreachable;
                }
            }
        }

        pub fn deinit(self: *Arena(T)) void {
            self.len = 0;
            self.cells.deinit();
            self.free.deinit();
        }

        pub fn get(self: *Arena(T), key: Key) ?*T {
            const index: usize = @intCast(key.index);
            const cell = &self.cells.items.ptr[index];
            if (cell.in_use and cell.key.generation == key.generation) {
                return &cell.value;
            } else {
                return null;
            }
        }

        pub fn iter(self: *Arena(T)) ArenaIterator {
            return ArenaIterator{ .arena = self, .index = 0 };
        }
    };
}

test "arena test" {
    const expect = @import("std").testing.expect;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var arena = Arena(i32).init(allocator);
    {
        const key = arena.insert(1);
        try expect(key.index == 0 and key.generation == 0);
    }
    {
        const key = arena.insert(1);
        try expect(key.index == 1);
    }
    {
        arena.delete(.{ .index = 0, .generation = 0 });
        const key = arena.insert(1);
        try expect(key.index == 0 and key.generation == 1);
    }
    {
        const key = arena.insert(10);
        if (arena.get(key)) |v| {
            try expect(v.* == 10);
        }
        if (arena.get(key)) |v| {
            v.* = 20;
        }
        if (arena.get(key)) |v| {
            try expect(v.* == 20);
        }
        arena.delete(key);
        if (arena.get(key)) |_| {
            unreachable;
        }
    }
    {
        arena.clear();
        _ = arena.insert(1);
        _ = arena.insert(2);
        _ = arena.insert(3);
        try expect(arena.len == 3);
        var len: i32 = 0;
        var iter = arena.iter();
        while (iter.next()) |_| {
            len += 1;
        }
        try expect(len == 3);
    }
    {
        var iter = arena.iter();
        while (iter.next()) |v| {
            try expect(v.* == 1 or v.* == 2 or v.* == 3);
        }
    }
}
