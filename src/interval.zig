const math = @import("std").math;

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

    pub fn clamp(self: Interval, x: f64) f64 {
        if (x < self.min) return self.min;
        if (x > self.max) return self.max;
        return x;
    }
};
