const Rect = @This();
x: f32,
y: f32,
w: f32,
h: f32,

pub fn intersects(self: Rect, other: Rect) bool {
    const left1 = self.x;
    const left2 = other.x;
    const right1 = self.x + self.w;
    const right2 = other.x + other.w;
    const top1 = self.y;
    const top2 = other.y;
    const bottom1 = self.y + self.h;
    const bottom2 = other.y + other.h;
    if (left1 < right2 and right1 > left2 and top1 < bottom2 and bottom1 > top2) {
        return true;
    }
    return false;
}
