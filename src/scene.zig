const std = @import("std");
const material = @import("material.zig");
const raytracer = @import("raytracer.zig");
const vec3 = @import("vec3.zig");
const camera = @import("camera.zig");
const Camera = camera.Camera;
const CameraInitData = camera.CameraInitData;
const json = std.json;
const Allocator = std.mem.Allocator;
const Material = material.Material;
const MaterialInitData = material.MaterialInitData;
const Hittable = raytracer.Hittable;
const Sphere = raytracer.Sphere;

pub const SceneError = error{
    InvalidShape,
    InvalidMaterial,
};

pub const ShapeInitData = struct {
    material: []const u8,
    sphere: ?struct {
        center: vec3.Point3,
        radius: f64,
    },
};

pub const SceneInitData = struct {
    const Self = @This();
    const MaterialMap = json.ArrayHashMap(MaterialInitData);

    camera: ?CameraInitData = null,
    materials: MaterialMap,
    shapes: []const ShapeInitData,
};

pub const Scene = struct {
    const Self = @This();
    const MaterialMap = std.StringHashMap(Material);

    allocator: Allocator,
    camera: Camera,
    materials: MaterialMap,
    shapes: []const raytracer.Hittable,

    pub fn initFromData(
        allocator: Allocator,
        init_data: SceneInitData,
    ) !Self {
        var materials = MaterialMap.init(allocator);
        errdefer materials.deinit();

        var iter = init_data.materials.map.iterator();

        while (iter.next()) |m| {
            try materials.put(
                m.key_ptr.*,
                try Material.initFromData(m.value_ptr.*),
            );
        }

        var shapes = try allocator.alloc(
            raytracer.Hittable,
            init_data.shapes.len,
        );
        errdefer allocator.free(shapes);

        for (init_data.shapes, shapes) |shape, *dest_shape| {
            if (materials.getPtr(shape.material)) |material_ptr| {
                if (shape.sphere) |sphere| {
                    dest_shape.* = Hittable{
                        .sphere = Sphere.init(
                            sphere.center,
                            sphere.radius,
                            material_ptr,
                        ),
                    };
                } else {
                    return SceneError.InvalidShape;
                }
            } else {
                return SceneError.InvalidMaterial;
            }
        }

        const scene_camera = if (init_data.camera) |init_data_camera|
            Camera.initFromData(init_data_camera)
        else
            Camera.init(
                16 / 9,
                1200,
                100,
            );

        return Self{
            .camera = scene_camera,
            .allocator = allocator,
            .materials = materials,
            .shapes = shapes,
        };
    }

    pub fn deinit(self: *Self) void {
        self.materials.deinit();
        self.allocator.free(self.shapes);
    }
};

test "loads a scene from json" {
    const json_data =
        \\ {
        \\    "materials": {
        \\      "foo": {
        \\          "function": "lambertian",
        \\          "albedo": [1.0, 1.0, 1.0]
        \\      }
        \\    },
        \\    "shapes": [
        \\      {
        \\          "material": "foo",
        \\          "sphere": {
        \\              "center": [0, 0, 0],
        \\              "radius": 1
        \\          }
        \\      }
        \\    ]
        \\ }
    ;

    var init_data = try json.parseFromSlice(
        SceneInitData,
        std.testing.allocator,
        json_data,
        .{},
    );
    defer init_data.deinit();
    var scene = try Scene.initFromData(
        std.testing.allocator,
        init_data.value,
    );
    defer scene.deinit();
    try std.testing.expect(scene.shapes.len == 1);
    try std.testing.expect(scene.shapes[0].sphere.material.albedo.x == 1.0);
}
