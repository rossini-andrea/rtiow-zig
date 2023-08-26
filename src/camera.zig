const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const math = @import("std").math;
const random = @import("random.zig");
const stdout = @import("stdio.zig").stdout;
const stdlog = @import("stdio.zig").stdlog;
const Interval = @import("interval.zig").Interval;
const Ray = raytracer.Ray;
const Vec3 = vec3.Vec3;
const Color = vec3.Color;

pub const Camera = struct {
    aspect_ratio: f64,
    samples_per_pixel: u32,
    image_width: u32,
    image_height: u32,
    image_width_f: f64,
    image_height_f: f64,
    center: vec3.Point3,
    pixel00_loc: vec3.Point3,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    max_depth: u32 = 10,

    pub fn init(
        aspect_ratio: f64,
        image_width: u32,
        samples_per_pixel: u32,
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
            .sub(Vec3.init(0, 0, focal_length))
            .sub(viewport_u.scale(0.5))
            .sub(viewport_v.scale(0.5));
        var pixel00_loc = viewport_upper_left
            .add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

        return Camera{
            .aspect_ratio = aspect_ratio,
            .samples_per_pixel = samples_per_pixel,
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
                var pixel_color = vec3.Color.init(0, 0, 0);

                for (0..self.samples_per_pixel) |_| {
                    const r = self.getRay(x_f, y_f);
                    pixel_color = pixel_color.add(rayColor(
                        r,
                        world[0..world.len],
                        self.max_depth,
                    ));
                }

                pixel_color = pixel_color
                    .fraction(@as(f64, @floatFromInt(
                    self.samples_per_pixel,
                )));
                const intensity = Interval.init(0, 0.999);
                pixel_color.x = intensity.clamp(pixel_color.x);
                pixel_color.y = intensity.clamp(pixel_color.y);
                pixel_color.z = intensity.clamp(pixel_color.z);

                try stdout.print("{}", .{pixel_color});
            }

            try stdlog.print("\x1B[8D {d:>6.2}%", .{(y_f / (self.image_height_f - 1.0)) * 100});
            try stdlog.context.flush();
        }
    }

    fn getRay(self: Camera, x: f64, y: f64) Ray {
        const pixel_center = self
            .pixel00_loc
            .add(self.pixel_delta_u.scale(x))
            .add(self.pixel_delta_v.scale(y));
        const pixel_sample = pixel_center
            .add(self.pixelSampleSquare());
        const ray_direction = pixel_sample.sub(self.center);
        return raytracer.Ray.init(self.center, ray_direction);
    }

    fn pixelSampleSquare(self: Camera) Vec3 {
        const px = random.rand() - 0.5;
        const py = random.rand() - 0.5;
        return self.pixel_delta_u.scale(px)
            .add(self.pixel_delta_v.scale(py));
    }

    fn rayColor(
        r: Ray,
        world: []const raytracer.Hittable,
        depth: u32,
    ) vec3.Color {
        if (depth == 0) {
            return Color.init(0, 0, 0);
        }

        if (raytracer.hitTestAgainstList(
            world,
            r,
            Interval.init(0, math.inf(f64)),
        )) |hit_record| {
            const diffuse_direction = Vec3.initRandomOnHemisphere(
                hit_record.normal,
            );
            return rayColor(
                Ray.init(hit_record.p, diffuse_direction),
                world,
                depth - 1,
            ).scale(0.5);
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
