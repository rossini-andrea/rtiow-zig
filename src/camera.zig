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
const Point3 = vec3.Point3;

pub const CameraInitData = struct {
    aspect_ratio: f64,
    image_width: u32,
    samples_per_pixel: u32 = 100,
    max_depth: u32 = 10,
    vfov: f64 = 90,
    lookat: ?struct {
        from: vec3.Point3,
        at: vec3.Point3,
        vup: vec3.Vec3,
        focus_distance: f64,
        defocus_angle: f64 = 0.6,
    },
};

pub const Camera = struct {
    const Self = @This();
    aspect_ratio: f64,
    samples_per_pixel: u32,
    image_width: u32,
    image_height: u32,
    image_width_f: f64,
    image_height_f: f64,
    viewport_width: f64,
    viewport_height: f64,
    vfov: f64,
    center: vec3.Point3,
    pixel00_loc: vec3.Point3,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    defocus_disk: ?struct {
        u: Vec3,
        v: Vec3,
    },
    max_depth: u32 = 10,

    pub fn initFromData(data: CameraInitData) Self {
        var cam = Self.init(
            data.aspect_ratio,
            data.image_width,
            data.samples_per_pixel,
        );
        cam.max_depth = data.max_depth;
        cam.vfov = math.degreesToRadians(f64, data.vfov);

        if (data.lookat) |lookat| {
            cam.lookAt(
                lookat.from,
                lookat.at,
                lookat.vup,
                lookat.focus_distance,
                math.degreesToRadians(f64, lookat.defocus_angle),
            );
        }

        return cam;
    }

    pub fn init(
        aspect_ratio: f64,
        image_width: u32,
        samples_per_pixel: u32,
    ) Self {
        var image_width_f = @as(f64, @floatFromInt(image_width));
        var image_height_f = image_width_f / aspect_ratio;
        var image_height: u32 = @intFromFloat(image_height_f);
        image_height = if (image_height < 1) 1 else image_height;
        image_height_f = @as(f64, @floatFromInt(image_height));

        var camera_center = Point3.init(0, 0, 0);

        return Camera{
            .aspect_ratio = aspect_ratio,
            .samples_per_pixel = samples_per_pixel,
            .image_width = image_width,
            .image_height = image_height,
            .image_width_f = image_width_f,
            .image_height_f = image_height_f,
            .vfov = math.pi * 0.5,
            .viewport_width = 2,
            .viewport_height = 2,
            .center = camera_center,
            .pixel00_loc = Point3.init(0.5, 0.5, -1),
            .pixel_delta_u = Vec3.init(2, 0, 0),
            .pixel_delta_v = Vec3.init(0, 2, 0),
            .defocus_disk = null,
        };
    }

    pub fn lookAt(
        self: *Self,
        from: Vec3,
        at: Vec3,
        vup: Vec3,
        focus_distance: f64,
        defocus_angle: f64,
    ) void {
        const direction = from.sub(at);

        const h = math.tan(self.vfov / 2);
        const viewport_height = 2.0 * h * focus_distance;
        const viewport_width = viewport_height * (self.image_width_f / self.image_height_f);

        const w = direction.unitVector();
        const u = vup.cross(w).unitVector();
        const v = w.cross(u);

        const viewport_u = u.scale(viewport_width);
        const viewport_v = v.scale(-viewport_height);

        const pixel_delta_u = viewport_u.fraction(self.image_width_f);
        const pixel_delta_v = viewport_v.fraction(self.image_height_f);

        const viewport_upper_left = from
            .sub(w.scale(focus_distance))
            .sub(viewport_u.scale(0.5))
            .sub(viewport_v.scale(0.5));
        const pixel00_loc = viewport_upper_left.add(
            pixel_delta_u.add(pixel_delta_v).scale(0.5),
        );

        if (defocus_angle > 0) {
            const defocus_radius = focus_distance *
                math.tan(defocus_angle * 0.5);
            const defocus_disk_u = u.scale(defocus_radius);
            const defocus_disk_v = v.scale(defocus_radius);
            self.defocus_disk = .{
                .u = defocus_disk_u,
                .v = defocus_disk_v,
            };
        } else {
            self.defocus_disk = null;
        }

        self.center = from;
        self.viewport_width = viewport_width;
        self.viewport_height = viewport_height;
        self.pixel_delta_u = pixel_delta_u;
        self.pixel_delta_v = pixel_delta_v;
        self.pixel00_loc = pixel00_loc;
    }

    pub fn defocusDiskSample(self: Camera) Point3 {
        if (self.defocus_disk) |disk| {
            const p = Point3.initRandomInDisk();
            return self.center
                .add(disk.u.scale(p.x))
                .add(disk.v.scale(p.y));
        }

        return self.center;
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

                pixel_color = linearToGamma(pixel_color);

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

    fn linearToGamma(color: Color) Color {
        return Color.init(
            @sqrt(color.x),
            @sqrt(color.y),
            @sqrt(color.z),
        );
    }

    fn getRay(self: Camera, x: f64, y: f64) Ray {
        const pixel_center = self
            .pixel00_loc
            .add(self.pixel_delta_u.scale(x))
            .add(self.pixel_delta_v.scale(y));
        const pixel_sample = pixel_center
            .add(self.pixelSampleSquare());
        const origin =
            self.defocusDiskSample();
        const ray_direction = pixel_sample.sub(origin);
        return raytracer.Ray.init(origin, ray_direction);
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
            Interval.init(0.001, math.inf(f64)),
        )) |hit_record| {
            if (hit_record.material.scatter(
                hit_record.material,
                &r,
                &hit_record,
            )) |scatter| {
                return scatter
                    .attenuation
                    .product(rayColor(
                    scatter.ray,
                    world,
                    depth - 1,
                ));
            }

            return Color.init(0, 0, 0);
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
