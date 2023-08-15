const vec3 = @import("vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const Ray = struct {
    origin: vec3.Point3,
    direction: vec3.Vec3,

    pub fn init(origin: vec3.Point3, direction: vec3.Vec3) Ray {
        return Ray{
            .origin = origin,
            .direction = direction,
        };
    }

    pub fn at(self: Ray, t: f64) vec3.Point3 {
        return self.origin.add(self.direction.scale(t));
    }
};

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    t: f64,

    pub fn init(p: Point3, normal: Vec3, t: f64) HitRecord {
        return HitRecord{
            .p = p,
            .normal = normal,
            .t = t,
        };
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,

    pub fn init(center: Point3, radius: f64) Sphere {
        return Sphere{
            .center = center,
            .radius = radius,
        };
    }

    fn hitTest(
        self: Sphere,
        r: Ray,
        ray_tmin: f64,
        ray_tmax: f64,
    ) ?HitRecord {
        const oc = r.origin.sub(self.center);
        const a = r.direction.lengthSquared();
        const half_b = oc.dot(r.direction);
        const c = oc.lengthSquared() - self.radius * self.radius;
        const discriminant = half_b * half_b - a * c;

        if (discriminant < 0.0) {
            return null;
        }

        const sqrtd = @sqrt(discriminant);
        var root = (-half_b - sqrtd) / a;

        if ((root <= ray_tmin) || (ray_tmax <= root)) {
            root = (-half_b + sqrtd) / a;

            if ((root <= ray_tmin) || (ray_tmax <= root)) {
                return null;
            }
        }

        const p = r.at(root);

        return HitRecord.init(
            p,
            p.sub(self.center) - self.radius,
            root,
        );
    }
};
