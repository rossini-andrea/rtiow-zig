const std = @import("std");

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
        return @sqrt(self.length_squared());
    }

    pub fn length_squared(self: Vec3) f64 {
        return self.x * self.x +
            self.x * self.x +
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
        try writer.print("{} {} {}\n", .{ @as(u8, @intFromFloat(255.999 * self.x)), @as(u8, @intFromFloat(255.999 * self.y)), @as(u8, @intFromFloat(255.999 * self.z)) });
    }
};

pub const Color = Vec3;
