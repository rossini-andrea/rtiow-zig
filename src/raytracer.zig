const vec3 = @import("vec3.zig");
const Interval = @import("interval.zig").Interval;
const math = @import("std").math;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const Color = vec3.Color;
const Material = @import("material.zig").Material;

pub const Ray = struct {
    origin: vec3.Point3,
    direction: vec3.Vec3,
    time: f64,

    pub fn init(
        origin: vec3.Point3,
        direction: vec3.Vec3,
        time: f64,
    ) Ray {
        return Ray{
            .origin = origin,
            .direction = direction,
            .time = time,
        };
    }

    pub fn at(self: Ray, t: f64) vec3.Point3 {
        return self.origin.add(self.direction.scale(t));
    }

    pub fn planeDistance(self: Ray, plane: Plane) ?f64 {
        const denom = self.direction.dot(plane.normal);

        if (-math.floatEps(f64) <= denom and
            denom <= math.floatEps(f64))
        {
            return null;
        }

        const distance = plane
            .origin
            .sub(self.origin)
            .dot(plane.normal) / denom;
        return distance;
    }
};

pub const Plane = struct {
    origin: Point3,
    normal: Vec3,
};

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    t: f64,
    front_face: bool,
    material: *const Material,

    pub fn init(
        p: Point3,
        outward_normal: Vec3,
        t: f64,
        ray: Ray,
        material: *const Material,
    ) HitRecord {
        const front_face = (ray.direction.dot(outward_normal) < 0.0);
        return HitRecord{
            .p = p,
            .normal = if (front_face) outward_normal else outward_normal.neg(),
            .t = t,
            .front_face = front_face,
            .material = material,
        };
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,
    triangle: Triangle,
    floor: Floor,

    fn hitTest(
        self: Hittable,
        r: Ray,
        ray_t: Interval,
    ) ?HitRecord {
        return switch (self) {
            .sphere => |s| s.hitTest(r, ray_t),
            .triangle => |t| t.hitTest(r, ray_t),
            .floor => |f| f.hitTest(r, ray_t),
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
    material: *const Material,
    velocity: ?Vec3 = null,

    pub fn init(
        center: Point3,
        radius: f64,
        material: *const Material,
        velocity: ?Vec3,
    ) Sphere {
        return Sphere{
            .center = center,
            .radius = radius,
            .material = material,
            .velocity = velocity,
        };
    }

    fn center_at_t(self: *const Sphere, time: f64) Point3 {
        if (self.*.velocity) |velocity| {
            return self.*.center.add(velocity.scale(time));
        } else {
            return self.*.center;
        }
    }

    fn hitTest(
        self: Sphere,
        r: Ray,
        ray_t: Interval,
    ) ?HitRecord {
        const center = self.center_at_t(r.time);
        const oc = r.origin.sub(center);
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

        return HitRecord.init(
            p,
            p.sub(center).scale(1 / self.radius),
            root,
            r,
            self.material,
        );
    }
};

pub const Triangle = struct {
    vertices: [3]Point3,
    normal: Vec3,
    material: *const Material,

    pub fn init(
        vertices: [3]Point3,
        material: *const Material,
    ) Triangle {
        const normal =
            vertices[1].sub(vertices[0])
            .cross(vertices[2].sub(vertices[1])).unitVector();
        return Triangle{
            .vertices = vertices,
            .normal = normal,
            .material = material,
        };
    }

    fn hitTest(
        self: Triangle,
        r: Ray,
        ray_t: Interval,
    ) ?HitRecord {
        const distance = r.planeDistance(Plane{ .origin = self.vertices[0], .normal = self.normal });

        if (distance == null) {
            return null;
        }

        if (!ray_t.surrounds(distance.?)) {
            return null;
        }

        const p = r.at(distance.?);

        // Check if the point is "behind" all three edges at once. If so
        // it is between the edges.
        if (Vec3.dot(self.normal, Vec3.cross(
            self.vertices[1].sub(self.vertices[0]),
            p.sub(self.vertices[1]),
        )) > 0 and
            Vec3.dot(self.normal, Vec3.cross(
            self.vertices[2].sub(self.vertices[1]),
            p.sub(self.vertices[2]),
        )) > 0 and
            Vec3.dot(self.normal, Vec3.cross(
            self.vertices[0].sub(self.vertices[2]),
            p.sub(self.vertices[0]),
        )) > 0) {
            return HitRecord.init(
                p,
                self.normal,
                distance.?,
                r,
                self.material,
            );
        }

        return null;
    }
};

const white: Material = Material.initMetal(Color.init(1, 1, 1), 1);
const black: Material = Material.initMetal(Color.init(0, 0, 0), 1);

// An infinite plane with origin at ZERO and normal (0,0,1)
pub const Floor = struct {
    plane: Plane = Plane{
        .origin = Point3.init(0, 0, 0),
        .normal = Vec3.init(0, 0, 1),
    },

    fn hitTest(
        self: Floor,
        r: Ray,
        ray_t: Interval,
    ) ?HitRecord {
        const distance = r.planeDistance(self.plane);

        if (distance == null) {
            return null;
        }

        if (!ray_t.surrounds(distance.?)) {
            return null;
        }

        const p = r.at(distance.?);
        const is_x_odd = @as(i64, @intFromFloat(@floor(p.x))) & 1;
        const is_y_odd = @as(i64, @intFromFloat(@floor(p.y))) & 1;

        return HitRecord.init(
            p,
            self.plane.normal,
            distance.?,
            r,
            if (is_x_odd == is_y_odd) &white else &black,
        );
    }
};
