const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const math = @import("std").math;
const stdout = @import("stdio.zig").stdout;
const stdlog = @import("stdio.zig").stdlog;

pub const Camera = struct {
    aspect_ratio: f64,
    image_width: u32,
    image_height: u32,
    image_width_f: f64,
    image_height_f: f64,
    center: vec3.Point3,
    pixel00_loc: vec3.Point3,
    pixel_delta_u: vec3.Vec3,
    pixel_delta_v: vec3.Vec3,

    pub fn init(
        aspect_ratio: f64,
        image_width: u32,
    ) Camera {
        var image_width_f = @as(f64, @floatFromInt(image_width));
        var image_height_f = image_width_f / aspect_ratio;
        var image_height: u32 = @intFromFloat(image_height_f);
        image_height = if (image_height < 1) 1 else image_height;
        image_height_f = @as(f64, @floatFromInt(image_height));

        const focal_length: f64 = 1.0;
        const viewport_height: f64 = 2.0;
        var viewport_width = viewport_height * (image_width_f / image_height_f);
        var camera_center = vec3.Point3.init(0, 0, 0);

        var viewport_u = vec3.Point3.init(viewport_width, 0, 0);
        var viewport_v = vec3.Point3.init(0, -viewport_height, 0);

        var pixel_delta_u = viewport_u.fraction(image_width_f);
        var pixel_delta_v = viewport_v.fraction(image_height_f);

        var viewport_upper_left = camera_center
            .sub(vec3.Vec3.init(0, 0, focal_length))
            .sub(viewport_u.scale(0.5))
            .sub(viewport_v.scale(0.5));
        var pixel00_loc = viewport_upper_left
            .add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

        return Camera{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .image_width_f = image_width_f,
            .image_height_f = image_height_f,
            .center = camera_center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
        };
    }

    pub fn render(self: Camera, world: []const raytracer.Hittable) !void {
        try stdout.print("P3\n{} {}\n255\n", .{
            self.image_width,
            self.image_height,
        });

        for (0..self.image_height) |y| {
            const y_f = @as(f64, @floatFromInt(y));

            for (0..self.image_width) |x| {
                const x_f = @as(f64, @floatFromInt(x));
                var pixel_center = self.pixel00_loc
                    .add(self.pixel_delta_u.scale(x_f))
                    .add(self.pixel_delta_v.scale(y_f));
                var ray_direction = pixel_center.sub(self.center);
                var r = raytracer.Ray.init(self.center, ray_direction);

                var pixel_color = rayColor(r, world[0..world.len]);

                try stdout.print("{}", .{pixel_color});
            }

            try stdlog.print("\x1B[8D {d:>6.2}%", .{(y_f / (self.image_height_f - 1.0)) * 100});
            try stdlog.context.flush();
        }
    }

    fn rayColor(r: raytracer.Ray, world: []const raytracer.Hittable) vec3.Color {
        if (raytracer.hitTestAgainstList(
            world,
            r,
            raytracer.Interval.init(0, math.inf(f64)),
        )) |hit_record| {
            return hit_record
                .normal
                .add(vec3.Color.init(1, 1, 1))
                .scale(0.5);
        }

        var unit_direction = r.direction.unitVector();
        var alpha = math.clamp(0.5 * (unit_direction.y + 1.0), 0.0, 1.0);
        return vec3.Color
            .init(1.0, 1.0, 1.0)
            .scale(1.0 - alpha)
            .add(vec3.Color.init(0.5, 0.7, 1.0)
            .scale(alpha));
    }
};
