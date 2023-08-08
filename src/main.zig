const std = @import("std");
const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");

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

    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    var viewport_width = viewport_height * (image_width_f / image_height_f);
    _ = viewport_width;
    var camera_center = vec3.Point3.init(0, 0, 0);

    var viewport_u = vec3.Point3.init(image_width_f, 0, 0);
    var viewport_v = vec3.Point3.init(0, -image_height_f, 0);

    var pixel_delta_u = viewport_u.fraction(image_width_f);
    var pixel_delta_v = viewport_v.fraction(image_height_f);

    var viewport_upper_left = camera_center
        .sub(vec3.Vec3.init(0, 0, focal_length))
        .sub(viewport_u.scale(0.5))
        .sub(viewport_v.scale(0.5));
    var pixel00_loc = viewport_upper_left
        .add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    for (0..image_width) |y| {
        const y_f = @as(f64, @floatFromInt(y));

        for (0..image_height) |x| {
            const x_f = @as(f64, @floatFromInt(x));
            var pixel_center = pixel00_loc
                .add(pixel_delta_u.scale(x_f))
                .add(pixel_delta_v.scale(y_f));
            var ray_direction = pixel_center.sub(camera_center);
            var r = raytracer.Ray.init(camera_center, ray_direction);

            var pixel_color = ray_color(r);

            try stdout.print("{}", .{pixel_color});
        }

        try stdlog.print("{d} %\n", .{(y_f / (image_height_f - 1.0)) * 100});
    }

    try bw.flush(); // don't forget to flush!
}

fn ray_color(r: raytracer.Ray) vec3.Color {
    _ = r;
    return vec3.Color.init(0, 0, 0);
}
