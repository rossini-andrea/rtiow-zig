const std = @import("std");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const stdlog_file = std.io.getStdErr().writer();
    var bwl = std.io.bufferedWriter(stdlog_file);
    const stdlog = bwl.writer();

    const width: u32 = 256;
    const height: u32 = 256;

    try stdout.print("P3\n{} {}\n255\n", .{ width, height });

    for (0..width) |y| {
        for (0..height) |x| {
            try stdlog.print("{d} %\n", .{@as(f64, @floatFromInt(y * width + x)) / ((height - 1) * width + width - 1) * 100});

            const r: u8 = @as(u8, @intFromFloat(@as(f64, @floatFromInt(x)) / (width - 1) * 255.999));
            const g: u8 = @as(u8, @intFromFloat(@as(f64, @floatFromInt(y)) / (height - 1) * 255.999));
            const b: u8 = @as(u8, @intFromFloat(@as(f64, @floatFromInt(y * width + x)) / (height * width + width - 1) * 255.999));

            try stdout.print("{} {} {}\n", .{ r, g, b });
        }
    }

    try bw.flush(); // don't forget to flush!
}
