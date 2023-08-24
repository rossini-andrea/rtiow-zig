const std = @import("std");
const stdout = @import("stdio.zig").stdout;
const math = std.math;
const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const infinity = math.inf(f64);
const Camera = @import("camera.zig").Camera;

pub fn main() !void {
    const aspect_ratio = 16.0 / 9.0;
    var image_width: u32 = 400;
    const world = [_]raytracer.Hittable{ raytracer.Hittable{ .sphere = raytracer.Sphere.init(vec3.Point3.init(0, 0, -1), 0.5) }, raytracer.Hittable{ .sphere = raytracer.Sphere.init(vec3.Point3.init(0, -100.5, -1), 100) } };
    const camera = Camera.init(aspect_ratio, image_width);
    try camera.render(&world);

    try stdout.context.flush(); // don't forget to flush!
}
