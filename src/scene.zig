const std = @import("std");
const material = @import("material.zig");
const raytracer = @import("raytracer.zig");
const vec3 = @import("vec3.zig");
const camera = @import("camera.zig");
const random = @import("random.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const Camera = camera.Camera;
const CameraInitData = camera.CameraInitData;
const json = std.json;
const math = std.math;
const Allocator = std.mem.Allocator;
const Material = material.Material;
const MaterialInitData = material.MaterialInitData;
const Hittable = raytracer.Hittable;
const Sphere = raytracer.Sphere;
const Triangle = raytracer.Triangle;
const Floor = raytracer.Floor;

pub const SceneError = error{
    InvalidShape,
    InvalidMaterial,
};

pub const ShapeInitData = struct {
    material: []const u8,
    sphere: ?struct {
        center: vec3.Point3,
        radius: f64,
    } = null,
    triangle: ?struct {
        verts: [3]vec3.Point3,
    } = null,
    floor: ?struct {} = null,
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

    pub fn initFinalRender(allocator: Allocator) !Self {
        var materialcache = MaterialMap.init(allocator);
        errdefer materialcache.deinit();

        try materialcache.ensureTotalCapacity(22 * 22 + 4);
        materialcache.putAssumeCapacity(
            "material_ground",
            Material.initLambertian(
                Color.init(
                    0.5,
                    0.5,
                    0.5,
                ),
            ),
        );
        materialcache.putAssumeCapacity(
            "material1",
            Material.initDielectric(1.5),
        );
        materialcache.putAssumeCapacity(
            "material2",
            Material.initLambertian(Color.init(
                0.4,
                0.2,
                0.1,
            )),
        );
        materialcache.putAssumeCapacity(
            "material3",
            Material.initMetal(
                Color.init(
                    0.7,
                    0.6,
                    0.5,
                ),
                0.0,
            ),
        );
        var world = try allocator.alloc(raytracer.Hittable, 22 * 22 + 4);
        errdefer allocator.free(world);
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
                    var random_material: Material = undefined;

                    if (choose_mat < 0.8) {
                        const albedo = Color.product(
                            Color.initRandom(),
                            Color.initRandom(),
                        );
                        random_material = Material.initLambertian(albedo);
                    } else if (choose_mat < 0.95) {
                        const albedo = Color.initRandomRanged(0.5, 1);
                        const fuzz = random.ranged(0, 0.5);
                        random_material = Material.initMetal(
                            albedo,
                            fuzz,
                        );
                    } else {
                        random_material = Material.initDielectric(1.5);
                    }

                    materialcache.putAssumeCapacity(
                        std.mem.asBytes(&idx),
                        random_material,
                    );

                    world[idx] = raytracer.Hittable{
                        .sphere = Sphere.init(
                            center,
                            0.2,
                            if (materialcache.getPtr(
                                std.mem.asBytes(&idx),
                            )) |ptr| ptr else unreachable,
                        ),
                    };
                    idx = idx + 1;
                }
            }
        }

        world[idx] = raytracer.Hittable{
            .sphere = Sphere.init(
                Point3.init(0, -1000, 0),
                1000,
                if (materialcache.getPtr(
                    "material_ground",
                )) |ptr| ptr else unreachable,
            ),
        };
        world[idx + 1] = raytracer.Hittable{
            .sphere = Sphere.init(
                Point3.init(0, 1, 0),
                1.0,
                if (materialcache.getPtr(
                    "material1",
                )) |ptr| ptr else unreachable,
            ),
        };
        world[idx + 2] = raytracer.Hittable{
            .sphere = Sphere.init(
                Point3.init(-4, 1, 0),
                1.0,
                if (materialcache.getPtr(
                    "material2",
                )) |ptr| ptr else unreachable,
            ),
        };
        world[idx + 3] = raytracer.Hittable{
            .sphere = Sphere.init(
                Point3.init(4, 1, 0),
                1.0,
                if (materialcache.getPtr(
                    "material3",
                )) |ptr| ptr else unreachable,
            ),
        };
        idx = idx + 4;

        const aspect_ratio = 16.0 / 9.0;
        const image_width: u32 = 1200;
        const samples_per_pixel = 500;
        var scene_camera = Camera.init(
            aspect_ratio,
            image_width,
            samples_per_pixel,
        );
        scene_camera.max_depth = 50;
        scene_camera.vfov = math.degreesToRadians(f64, 20);
        scene_camera.lookAt(
            Vec3.init(13, 2, 3),
            Vec3.init(0, 0, 0),
            Vec3.init(0, 1, 0),
            10,
            math.degreesToRadians(f64, 0.6),
        );

        return Self{
            .camera = scene_camera,
            .allocator = allocator,
            .materials = materialcache,
            .shapes = world,
        };
    }

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
                } else if (shape.triangle) |triangle| {
                    dest_shape.* = Hittable{
                        .triangle = Triangle.init(triangle.verts, material_ptr),
                    };
                } else if (shape.floor) |_| {
                    dest_shape.* = Hittable{
                        .floor = Floor{},
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
