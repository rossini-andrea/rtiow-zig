const raytracer = @import("raytracer.zig");
const vec3 = @import("vec3.zig");
const Ray = raytracer.Ray;
const HitRecord = raytracer.HitRecord;
const Vec3 = vec3.Vec3;
const Color = vec3.Color;

pub const ScatterResult = struct {
    ray: Ray,
    attenuation: Color,
};

pub const scatter_func = *const fn (
    self: *const Material,
    ray: *const Ray,
    hit_record: *const HitRecord,
) ?ScatterResult;

pub const Material = struct {
    const Self = @This();
    scatter: scatter_func,
    albedo: Color,
    fuzziness: f64 = 0,

    pub fn initLambertian(albedo: Color) Self {
        return Self{
            .scatter = lambertianScatter,
            .albedo = albedo,
        };
    }

    pub fn initMetal(
        albedo: Color,
        fuzziness: f64,
    ) Self {
        return Self{
            .scatter = metalScatter,
            .albedo = albedo,
            .fuzziness = fuzziness,
        };
    }
};

fn lambertianScatter(
    self: *const Material,
    _: *const Ray,
    hit_record: *const HitRecord,
) ?ScatterResult {
    var diffuse_direction = hit_record.normal.add(
        Vec3.initRandomUnit(),
    );

    if (diffuse_direction.isNearZero()) {
        diffuse_direction = hit_record.normal;
    }

    return ScatterResult{
        .ray = Ray.init(
            hit_record.p,
            diffuse_direction,
        ),
        .attenuation = self.albedo,
    };
}

fn metalScatter(
    self: *const Material,
    ray: *const Ray,
    hit_record: *const HitRecord,
) ?ScatterResult {
    const reflect_direction = ray.direction
        .unitVector()
        .reflect(hit_record.normal);
    const scattered_direction = reflect_direction.add(Vec3.initRandomUnit().scale(self.fuzziness));

    if (scattered_direction.dot(hit_record.normal) <= 0) {
        return null;
    }

    return ScatterResult{
        .ray = Ray.init(
            hit_record.p,
            scattered_direction,
        ),
        .attenuation = self.albedo,
    };
}
