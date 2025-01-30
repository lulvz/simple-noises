const std = @import("std");
const noise = @import("noise.zig");

pub fn main() !void {
    var pn = noise.PerlinNoise2D(f64).init(null); 
    for(0..pn.permutation_table.len) |i| {
        std.debug.print("pn.permutation_table[{d}]: {d}\n", .{i, pn.permutation_table[i]});
    }

    const frequency =  0.1;

    for(0..100) |x| {
        for(0..100) |y| {
            const generated = pn.generate(@as(f64, @floatFromInt(x))*frequency, @as(f64, @floatFromInt(y))*frequency);
            if(generated > 1.0) {
                std.debug.print("{d},{d}:{d}\n", .{x, y, generated});
            }
        }
    }
}

test "test permutation table generation" {
    const pn = noise.PerlinNoise2D(f32).init(@intCast(std.time.timestamp()));
    for(0..pn.permutation_table.len) |i| {
        std.debug.print("pn.permutation_table[{d}]: {d}\n", .{i, pn.permutation_table[i]});
    }
}
