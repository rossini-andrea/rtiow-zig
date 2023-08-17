const std = @import("std");
const math = std.math;
const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const infinity = math.inf(f64);

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stdlog_file = std.io.getStdErr().writer();
    var bwl = std.io.bufferedWriter(stdlog_file);
    const stdlog = bwl.writer();

    const aspect_ratio = 16.0 / 9.0;
    var image_width: u32 = 400;
    var image_width_f = @as(f64, @floatFromInt(image_width));
    var image_height_f = image_width_f / aspect_ratio;
    var image_height: u32 = @intFromFloat(image_height_f);
    image_height = if (image_height < 1) 1 else image_height;
    image_height_f = @as(f64, @floatFromInt(image_height));

    const world = [_]raytracer.Hittable{ raytracer.Hittable{ .sphere = raytracer.Sphere.init(vec3.Point3.init(0, 0, -1), 0.5) }, raytracer.Hittable{ .sphere = raytracer.Sphere.init(vec3.Point3.init(0, -100.5, -1), 100) } };

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

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_height) |y| {
        const y_f = @as(f64, @floatFromInt(y));

        for (0..image_width) |x| {
            const x_f = @as(f64, @floatFromInt(x));
            var pixel_center = pixel00_loc
                .add(pixel_delta_u.scale(x_f))
                .add(pixel_delta_v.scale(y_f));
            var ray_direction = pixel_center.sub(camera_center);
            var r = raytracer.Ray.init(camera_center, ray_direction);

            var pixel_color = rayColor(r, world[0..world.len]);

            try stdout.print("{}", .{pixel_color});
        }

        try stdlog.print("\x1B[8D {d:>6.2}%", .{(y_f / (image_height_f - 1.0)) * 100});
        try bwl.flush();
    }

    try bw.flush(); // don't forget to flush!
}

fn rayColor(r: raytracer.Ray, world: []const raytracer.Hittable) vec3.Color {
    if (raytracer.hitTestAgainstList(world, r, 0, infinity)) |hit_record| {
        return hit_record
            .normal
            .add(vec3.Color.init(1, 1, 1))
            .scale(0.5);
    }

    var unit_direction = r.direction.unitVector();
    var alpha = math.clamp(0.5 * (unit_direction.y + 1.0), 0.0, 1.0);
    return vec3.Color.init(1.0, 1.0, 1.0).scale(1.0 - alpha).add(vec3.Color.init(0.5, 0.7, 1.0).scale(alpha));
}
