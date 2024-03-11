const std = @import("std");
const math = std.math;
const json = std.json;
const Allocator = std.mem.Allocator;
const raytracer = @import("raytracer.zig");
const vec3 = @import("vec3.zig");
const random = @import("random.zig");
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

pub const MaterialInitData = struct {
    function: []const u8,
    albedo: Color = Color.init(0, 0, 0),
    fuzziness: f64 = 0,
    refraction_index: f64 = 0,
};

pub const MaterialError = error{
    InvalidFunction,
};

pub const Material = struct {
    const Self = @This();
    scatter: scatter_func,
    albedo: Color = Color.init(0, 0, 0),
    fuzziness: f64 = 0,
    refraction_index: f64 = 0,

    pub fn initFromData(data: MaterialInitData) !Self {
        if (std.mem.eql(u8, data.function, "lambertian")) {
            return Self.initLambertian(
                data.albedo,
            );
        }

        if (std.mem.eql(u8, data.function, "metal")) {
            return Self.initMetal(
                data.albedo,
                data.fuzziness,
            );
        }

        if (std.mem.eql(u8, data.function, "dielectric")) {
            return Self.initDielectric(data.refraction_index);
        }

        return MaterialError.InvalidFunction;
    }

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

    pub fn initDielectric(refraction_index: f64) Self {
        return Self{
            .scatter = dielectricScatter,
            .refraction_index = refraction_index,
        };
    }
};

fn lambertianScatter(
    self: *const Material,
    ray: *const Ray,
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
            ray.time,
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
            ray.time,
        ),
        .attenuation = self.albedo,
    };
}

fn dielectricScatter(
    self: *const Material,
    ray: *const Ray,
    hit_record: *const HitRecord,
) ?ScatterResult {
    const refraction_ratio = if (hit_record.front_face)
        1.0 / self.refraction_index
    else
        self.refraction_index;
    const unit_direction = ray.direction.unitVector();
    const cos_theta = @min(
        unit_direction.neg().dot(hit_record.normal),
        1,
    );
    const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

    const can_refract = refraction_ratio * sin_theta <= 1;

    const direction = if (can_refract and !(reflectance(
        cos_theta,
        refraction_ratio,
    ) > random.rand()))
        unit_direction.refract(
            hit_record.normal,
            refraction_ratio,
        )
    else
        unit_direction.reflect(
            hit_record.normal,
        );

    return ScatterResult{
        .ray = Ray.init(
            hit_record.p,
            direction,
            ray.time,
        ),
        .attenuation = Color.init(1, 1, 1),
    };
}

fn reflectance(cosine: f64, reference: f64) f64 {
    // Use Schlick's approximation
    var r0 = (1 - reference) / (1 + reference);
    r0 = r0 * r0;
    return r0 + (1 - r0) * math.pow(
        f64,
        (1 - cosine),
        5,
    );
}
