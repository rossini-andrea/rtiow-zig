const std = @import("std");
const stdout = @import("stdio.zig").stdout;
const random = @import("random.zig");
const math = std.math;
const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const infinity = math.inf(f64);
const Camera = @import("camera.zig").Camera;
const Material = @import("material.zig").Material;
const Sphere = raytracer.Sphere;
const Color = vec3.Color;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

pub fn main() !void {
    const material_ground = Material.initLambertian(Color.init(
        0.5,
        0.5,
        0.5,
    ));
    const material1 = Material.initDielectric(1.5);
    const material2 = Material.initLambertian(Color.init(
        0.4,
        0.2,
        0.1,
    ));
    const material3 = Material.initMetal(
        Color.init(
            0.7,
            0.6,
            0.5,
        ),
        0.0,
    );
    var world: [22 * 22 + 4]raytracer.Hittable = undefined;
    var materialcache: [22 * 22]Material = undefined;
    var idx: usize = 0;

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;

        while (b < 11) : (b += 1) {
            const center = Point3.init(
                @as(f64, @floatFromInt(a)) +
                    0.9 * random.rand(),
                0.2,
                @as(f64, @floatFromInt(b)) +
                    0.9 * random.rand(),
            );

            if (center.sub(Point3.init(4, 0.2, 0)).length() > 0.9) {
                const choose_mat = random.rand();

                if (choose_mat < 0.8) {
                    const albedo = Color.product(
                        Color.initRandom(),
                        Color.initRandom(),
                    );
                    materialcache[idx] = Material.initLambertian(albedo);
                } else if (choose_mat < 0.95) {
                    const albedo = Color.initRandomRanged(0.5, 1);
                    const fuzz = random.ranged(0, 0.5);
                    materialcache[idx] = Material.initMetal(
                        albedo,
                        fuzz,
                    );
                } else {
                    materialcache[idx] = Material.initDielectric(1.5);
                }

                world[idx] = raytracer.Hittable{
                    .sphere = Sphere.init(center, 0.2, &materialcache[idx]),
                };
                idx = idx + 1;
            }
        }
    }

    world[idx] = raytracer.Hittable{
        .sphere = Sphere.init(Point3.init(0, -1000, 0), 1000, &material_ground),
    };
    world[idx + 1] = raytracer.Hittable{
        .sphere = Sphere.init(Point3.init(0, 1, 0), 1.0, &material1),
    };
    world[idx + 2] = raytracer.Hittable{
        .sphere = Sphere.init(Point3.init(-4, 1, 0), 1.0, &material2),
    };
    world[idx + 3] = raytracer.Hittable{
        .sphere = Sphere.init(Point3.init(4, 1, 0), 1.0, &material3),
    };
    idx = idx + 4;

    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 1200;
    const samples_per_pixel = 500;
    var camera = Camera.init(
        aspect_ratio,
        image_width,
        samples_per_pixel,
    );
    camera.max_depth = 50;
    camera.vfov = math.degreesToRadians(f64, 20);
    camera.lookAt(
        Vec3.init(13, 2, 3),
        Vec3.init(0, 0, 0),
        Vec3.init(0, 1, 0),
        10,
        math.degreesToRadians(f64, 0.6),
    );
    try camera.render(world[0..idx]);

    try stdout.context.flush(); // don't forget to flush!
}
