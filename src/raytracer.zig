const vec3 = @import("vec3.zig");
const math = @import("std").math;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const Interval = struct {
    min: f64 = math.inf(f64),
    max: f64 = -math.inf(f64),

    pub const empty = Interval{};
    pub const universe = Interval{
        .min = -math.inf(f64),
        .max = math.inf(f64),
    };

    pub fn init(min: f64, max: f64) Interval {
        return Interval{
            .min = min,
            .max = max,
        };
    }

    pub fn contains(self: Interval, x: f64) bool {
        return self.min <= x and x <= self.max;
    }

    pub fn surrounds(self: Interval, x: f64) bool {
        return self.min < x and x < self.max;
    }
};

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
    front_face: bool,

    pub fn init(p: Point3, outward_normal: Vec3, t: f64, ray: Ray) HitRecord {
        var front_face = (ray.direction.dot(outward_normal) < 0.0);
        return HitRecord{
            .p = p,
            .normal = if (front_face) outward_normal else outward_normal.neg(),
            .t = t,
            .front_face = front_face,
        };
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    fn hitTest(
        self: Hittable,
        r: Ray,
        ray_t: Interval,
    ) ?HitRecord {
        return switch (self) {
            .sphere => |s| s.hitTest(r, ray_t),
        };
    }
};

pub fn hitTestAgainstList(
    hittable_list: []const Hittable,
    r: Ray,
    ray_t: Interval,
) ?HitRecord {
    var hit_record: ?HitRecord = null;
    var closest = ray_t.max;

    for (hittable_list) |object| {
        if (object.hitTest(
            r,
            Interval.init(ray_t.min, closest),
        )) |rec| {
            if (closest <= rec.t) {
                continue;
            }

            hit_record = rec;
            closest = rec.t;
        }
    }

    return hit_record;
}

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
        ray_t: Interval,
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

        if (!ray_t.surrounds(root)) {
            root = (-half_b + sqrtd) / a;

            if (!ray_t.surrounds(root)) {
                return null;
            }
        }

        const p = r.at(root);

        return HitRecord.init(p, p.sub(self.center).scale(1 / self.radius), root, r);
    }
};
