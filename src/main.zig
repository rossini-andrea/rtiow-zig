const std = @import("std");
const json = std.json;
const stdio = @import("stdio.zig");
const stdin_file = stdio.stdin_file;
const stdout = stdio.stdout;
const random = @import("random.zig");
const math = std.math;
const vec3 = @import("vec3.zig");
const raytracer = @import("raytracer.zig");
const infinity = math.inf(f64);
const Scene = @import("scene.zig").Scene;
const SceneInitData = @import("scene.zig").SceneInitData;
const Camera = @import("camera.zig").Camera;
const Material = @import("material.zig").Material;
const Sphere = raytracer.Sphere;
const Color = vec3.Color;
const Vec3 = vec3.Vec3;
const Point3 = vec3.Point3;

test {
    _ = @import("scene.zig");
}

const JsonReader = json.Reader(
    1024,
    std.fs.File.Reader,
);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == std.heap.Check.leak) {
            std.debug.panic("Leak detected.", .{});
        }
    }
    var json_reader = JsonReader.init(
        allocator,
        stdin_file,
    );
    defer json_reader.deinit();
    var init_data = try json.parseFromTokenSource(
        SceneInitData,
        allocator,
        &json_reader,
        .{},
    );
    defer init_data.deinit();
    var scene = try Scene.initFromData(
        allocator,
        init_data.value,
    );
    defer scene.deinit();
    try scene.camera.render(scene.shapes);
    try stdout.context.flush(); // don't forget to flush!
}
