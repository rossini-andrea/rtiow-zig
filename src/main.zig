const std = @import("std");
const json = std.json;
const mem = std.mem;
const args = @import("args");
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
const camera = @import("camera.zig");
const Camera = camera.Camera;
const CameraInitData = camera.CameraInitData;
const Material = @import("material.zig").Material;
const Allocator = std.mem.Allocator;
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

fn parseArguments(
    comptime T: type,
    allocator: Allocator,
) !T {
    var result = T{};

    switch (@typeInfo(T)) {
        .Struct => |args_typeinfo| {
            var arg_iterator = try std.process.argsWithAllocator(allocator);
            defer arg_iterator.deinit();

            while (arg_iterator.next()) |arg| {
                if (arg[0] != '-') {
                    // just ignore for this first version
                    continue;
                }

                inline for (args_typeinfo.fields) |field| {
                    if (mem.eql(u8, field.name, arg[1..])) {
                        @field(result, field.name) = true;
                    }
                }
            }
        },
        else => @compileError("Arguments type '" ++ @typeName(T) ++ "' must be a struct."),
    }

    return result;
}

const AppArguments = struct {
    @"final-render": bool = false,
    camera: ?[]const u8 = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    defer {
        if (gpa.deinit() == std.heap.Check.leak) {
            std.debug.panic("Leak detected.", .{});
        }
    }

    const options = try args.parseForCurrentProcess(
        AppArguments,
        allocator,
        .print,
    );
    defer options.deinit();
    var scene: Scene = undefined;

    if (options.options.@"final-render") {
        scene = try Scene.initFinalRender(allocator);
    } else {
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
        scene = try Scene.initFromData(
            allocator,
            init_data.value,
        );
    }

    defer scene.deinit();

    if (options.options.camera) |override_camera| {
        var file = try std.fs.cwd().openFile(override_camera, .{});
        defer file.close();
        const reader = file.reader();
        var json_reader = JsonReader.init(
            allocator,
            reader,
        );
        defer json_reader.deinit();

        const camera_init_data = try json.parseFromTokenSource(
            CameraInitData,
            allocator,
            &json_reader,
            .{},
        );
        defer camera_init_data.deinit();

        const new_camera = Camera.initFromData(camera_init_data.value);
        scene.camera = new_camera;
    }

    try scene.camera.render(scene.shapes);
    try stdout.context.flush(); // don't forget to flush!
}
