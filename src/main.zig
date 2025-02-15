const std = @import("std");
const noise = @import("lib.zig");

const IMAGE_SIZE = 1024;
const float_T = f32;

pub fn main() !void {
//    try generate2DPerlin(); 
   try generate3DPerlinCrossSection();
}

fn generate2DPerlin() !void {
    var pn = noise.perlin.PerlinNoise2D(float_T).init(@intCast(std.time.timestamp()), 0.05); 

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // P5 is the grayscale binary format
    const image_header: []const u8 = std.fmt.comptimePrint("P5\n# pnoise2d\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    var image_data: []u8 = undefined;
    image_data = try allocator.alloc(u8, IMAGE_SIZE*IMAGE_SIZE);
    defer allocator.free(image_data);

    for(0..IMAGE_SIZE) |x| {
        for(0..IMAGE_SIZE) |y| {
            const generated = pn.generate(@as(float_T, @floatFromInt(x)), @as(float_T, @floatFromInt(y)));
            // std.debug.print("{d},{d}:{d}\n", .{x, y, generated});

            image_data[x*IMAGE_SIZE + y] = @as(u8, @intFromFloat(((generated+1)/2) * 255.0));
        }
    }

    const ppm_file = try std.fs.cwd().createFile("images/pnoise2d.ppm", .{});
    defer ppm_file.close();

    _ = try ppm_file.write(image_header);
    _ = try ppm_file.write(image_data);
}

fn generate3DPerlinCrossSection() !void {
    var pn = noise.perlin.PerlinNoise3D(float_T).init(@intCast(std.time.timestamp()), 0.05); 

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // P5 is the grayscale binary format
    const image_header: []const u8 = std.fmt.comptimePrint("P5\n# pnoise3d\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    var image_data: []u8 = undefined;
    image_data = try allocator.alloc(u8, IMAGE_SIZE*IMAGE_SIZE);
    defer allocator.free(image_data);

    for(0..IMAGE_SIZE) |x| {
        for(0..IMAGE_SIZE) |z| {
            const generated = pn.generate(@as(float_T, @floatFromInt(x)), 0, @as(float_T, @floatFromInt(z)));
            // std.debug.print("{d},{d}:{d}\n", .{x, y, generated});

            image_data[x*IMAGE_SIZE + z] = @as(u8, @intFromFloat(((generated+1)/2) * 255.0));
        }
    }

    const ppm_file = try std.fs.cwd().createFile("images/pnoise3d.ppm", .{});
    defer ppm_file.close();

    _ = try ppm_file.write(image_header);
    _ = try ppm_file.write(image_data);
}

test "test permutation table generation" {
    const pn = noise.perlin.PerlinNoise2D(f32).init(@intCast(std.time.timestamp()), null);
    for(0..pn.permutation_table.len) |i| {
        std.debug.print("pn.permutation_table[{d}]: {d}\n", .{i, pn.permutation_table[i]});
    }
}

test "test 3d perlin cross section" {
}
