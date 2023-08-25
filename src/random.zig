const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdlib.h");
});

pub fn rand() f64 {
    return @as(f64, @floatFromInt(c.rand())) /
        (@as(f64, @floatFromInt(c.RAND_MAX)) + 1.0);
}

pub fn ranged(min: f64, max: f64) f64 {
    return min + (max - min) * rand();
}
