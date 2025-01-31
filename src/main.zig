const std = @import("std");
const noise = @import("lib.zig");

const IMAGE_SIZE = 1024;

pub fn main() !void {
    var pn = noise.PerlinNoise2D(f64).init(@intCast(std.time.timestamp()), 0.05); 

    // P5 is the grayscale binary format
    const image_header: []const u8 = std.fmt.comptimePrint("P5\n# pnoise2d\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    var image_data: [IMAGE_SIZE*IMAGE_SIZE]u8 = undefined;

    for(0..IMAGE_SIZE) |x| {
        for(0..IMAGE_SIZE) |y| {
            const generated = pn.generate(@as(f64, @floatFromInt(x)), @as(f64, @floatFromInt(y)));
            // std.debug.print("{d},{d}:{d}\n", .{x, y, generated});

            image_data[x*IMAGE_SIZE + y] = @as(u8, @intFromFloat(((generated+1)/2) * 255.0));
        }
    }

    const ppm_file = try std.fs.cwd().createFile("images/pnoise2d.ppm", .{});
    defer ppm_file.close();

    _ = try ppm_file.write(image_header);
    _ = try ppm_file.write(&image_data);
}

test "test permutation table generation" {
    const pn = noise.PerlinNoise2D(f32).init(@intCast(std.time.timestamp()), null);
    for(0..pn.permutation_table.len) |i| {
        std.debug.print("pn.permutation_table[{d}]: {d}\n", .{i, pn.permutation_table[i]});
    }
}
