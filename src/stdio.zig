const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
pub const stdout = bw.writer();

const stdlog_file = std.io.getStdErr().writer();
var bwl = std.io.bufferedWriter(stdlog_file);
pub const stdlog = bwl.writer();
