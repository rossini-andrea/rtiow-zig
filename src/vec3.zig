const std = @import("std");
const random = @import("random.zig");

pub const Vec3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn init(x: f64, y: f64, z: f64) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn initRandom() Vec3 {
        return Vec3{
            .x = random.rand(),
            .y = random.rand(),
            .z = random.rand(),
        };
    }

    pub fn initRandomRanged(min: f64, max: f64) Vec3 {
        return Vec3{
            .x = random.ranged(min, max),
            .y = random.ranged(min, max),
            .z = random.ranged(min, max),
        };
    }

    pub fn initRandomInSphere() Vec3 {
        while (true) {
            const v = initRandomRanged(-1, 1);

            if (v.lengthSquared() <= 1)
                return v;
        }
    }

    pub fn initRandomUnit() Vec3 {
        return initRandomInSphere().unitVector();
    }

    pub fn initRandomOnHemisphere(normal: Vec3) Vec3 {
        const v = initRandomUnit();

        if (v.dot(normal) > 0) {
            return v;
        } else {
            return v.neg();
        }
    }

    pub fn neg(self: Vec3) Vec3 {
        return Vec3{ .x = -self.x, .y = -self.y, .z = -self.z };
    }

    pub fn scale(self: Vec3, factor: f64) Vec3 {
        return Vec3{
            .x = self.x * factor,
            .y = self.y * factor,
            .z = self.z * factor,
        };
    }

    pub fn fraction(self: Vec3, divider: f64) Vec3 {
        return self.scale(1 / divider);
    }

    pub fn length(self: Vec3) f64 {
        return @sqrt(self.lengthSquared());
    }

    pub fn lengthSquared(self: Vec3) f64 {
        return self.x * self.x +
            self.y * self.y +
            self.z * self.z;
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }

    pub fn product(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x * other.x,
            .y = self.y * other.y,
            .z = self.z * other.z,
        };
    }

    pub fn dot(self: Vec3, other: Vec3) f64 {
        return self.x * other.x +
            self.y * other.y +
            self.z * other.z;
    }

    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.y * other.z - self.z * other.y,
            .y = self.z * other.x - self.x * other.z,
            .z = self.x * other.y - self.y * other.x,
        };
    }

    pub fn unitVector(self: Vec3) Vec3 {
        return self.fraction(self.length());
    }

    pub fn format(
        self: Color,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print(
            "{} {} {}\n",
            .{
                @as(u8, @intFromFloat(255.999 * self.x)),
                @as(u8, @intFromFloat(255.999 * self.y)),
                @as(u8, @intFromFloat(255.999 * self.z)),
            },
        );
    }
};

pub const Color = Vec3;
pub const Point3 = Vec3;
