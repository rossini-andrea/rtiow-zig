const std = @import("std");
const stdout = @import("stdio.zig").stdout;
const math = std.math;
const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const infinity = math.inf(f64);
const Camera = @import("camera.zig").Camera;
const Material = @import("material.zig").Material;
const Color = vec3.Color;

pub fn main() !void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width: u32 = 400;
    const samples_per_pixel = 100;
    const matte = Material.initLambertian(Color.init(
        0.5,
        0.5,
        0.5,
    ));
    const world = [_]raytracer.Hittable{
        raytracer.Hittable{ .sphere = raytracer.Sphere.init(
            vec3.Point3.init(0, 0, -1),
            0.5,
            &matte,
        ) },
        raytracer.Hittable{ .sphere = raytracer.Sphere.init(
            vec3.Point3.init(0, -100.5, -1),
            100,
            &matte,
        ) },
    };
    var camera = Camera.init(
        aspect_ratio,
        image_width,
        samples_per_pixel,
    );
    camera.max_depth = 50;
    try camera.render(&world);

    try stdout.context.flush(); // don't forget to flush!
}
