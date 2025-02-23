const std = @import("std");
const noise = @import("lib.zig");

const IMAGE_SIZE = 1024;
const float_T = f128;

pub fn main() !void {
    // try generate2DPerlin(); 
    // try generate3DPerlinCrossSection();
    // try generateVoronoi2D();
    // try generateVoronoi2DV();
    try generateWhiteNoiseUniform();
    try generateWhiteNoiseNormal();
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
    var pn = noise.perlin.PerlinNoise3D(float_T).init(@intCast(std.time.timestamp()), 0.02); 

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

fn generateVoronoi2D() !void {
    var vn = noise.voronoi.VoronoiNoise2D(float_T).init(@intCast(std.time.timestamp()), 0.01); 

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // P5 is the grayscale binary format
    const image_header: []const u8 = std.fmt.comptimePrint("P5\n# vnoise2d\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    var image_data: []u8 = undefined;
    image_data = try allocator.alloc(u8, IMAGE_SIZE*IMAGE_SIZE);
    defer allocator.free(image_data);

    const scale: float_T = std.math.sqrt1_2 * 255.0;
    
    var idx: usize = 0;
    var y: float_T = 0;
    while (y < IMAGE_SIZE) : (y += 1) {
        var x: float_T = 0;
        while (x < IMAGE_SIZE) : (x += 1) {
            const noise_val = 255.0 - (vn.generate(x, y) * scale);
            image_data[idx] = @intFromFloat(noise_val);
            idx += 1;
        }
    }

    const ppm_file = try std.fs.cwd().createFile("images/vnoise2d.ppm", .{});
    defer ppm_file.close();

    _ = try ppm_file.write(image_header);
    _ = try ppm_file.write(image_data);
}

fn generateVoronoi2DV() !void {
    var vn = noise.voronoi.VoronoiNoise2DV(float_T).init(@intCast(std.time.timestamp()), 0.01);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const image_header = std.fmt.comptimePrint("P5\n# vnoise2dv\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    var image_data = try allocator.alloc(u8, IMAGE_SIZE * IMAGE_SIZE);
    defer allocator.free(image_data);

    const scale: float_T = std.math.sqrt1_2 * 255.0;
    
    var idx: usize = 0;
    var y: float_T = 0;
    while (y < IMAGE_SIZE) : (y += 1) {
        var x: float_T = 0;
        while (x < IMAGE_SIZE) : (x += 1) {
            const noise_val = 255.0 - (vn.generate(.{ x, y }) * scale);
            image_data[idx] = @intFromFloat(noise_val);
            idx += 1;
        }
    }

    const ppm_file = try std.fs.cwd().createFile("images/vnoise2dv.ppm", .{});
    defer ppm_file.close();
    try ppm_file.writeAll(image_header);
    try ppm_file.writeAll(image_data);
}

fn generateWhiteNoiseUniform() !void {
    var wn = noise.spectral.WhiteNoise(f64).init(@intCast(std.time.timestamp()));
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const image_header = std.fmt.comptimePrint("P5\n# wnoiseu\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    const image_data_f = try allocator.alloc(f64, IMAGE_SIZE * IMAGE_SIZE);
    defer allocator.free(image_data_f);
    const image_data = try allocator.alloc(u8, IMAGE_SIZE * IMAGE_SIZE);
    defer allocator.free(image_data);

    wn.fill_uniform(image_data_f);
    for(image_data_f, image_data) |*data_f, *data| {
        data.* = @intFromFloat(data_f.* * 255.0);
    }

    const ppm_file = try std.fs.cwd().createFile("images/wnoiseu.ppm", .{});
    defer ppm_file.close();
    try ppm_file.writeAll(image_header);
    try ppm_file.writeAll(image_data);
}

fn generateWhiteNoiseNormal() !void {
    var wn = noise.spectral.WhiteNoise(f64).init(@intCast(std.time.timestamp()));
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const image_header = std.fmt.comptimePrint("P5\n# wnoisen\n{d} {d}\n255\n", .{IMAGE_SIZE, IMAGE_SIZE});
    const image_data_f = try allocator.alloc(f64, IMAGE_SIZE * IMAGE_SIZE);
    defer allocator.free(image_data_f);
    const image_data = try allocator.alloc(u8, IMAGE_SIZE * IMAGE_SIZE);
    defer allocator.free(image_data);

    wn.fill_gaussian(image_data_f);
    var count: usize = 0;
    for(image_data_f, image_data) |*data_f, *data| {
        // we multiply by 0.3 to control the spread of the distribution
        // then we add 0.5 to center it around 0.5, since it's centered at 0 by default
        // standard deviation is being scaled by 0.3
        var value = (data_f.* * 0.3) + 0.5;
        // so then approximately 50% of the samples should fall in this range
        if(value < 0.7 and value > 0.3) count += 1;
        if(value > 1.0) value = 1.0;
        if(value < 0.0) value = 0.0;
        data.* = @intFromFloat(value * 255.0);
        // std.debug.print("{d}\n", .{data_f.*});
    }

    std.debug.print("{d}% of samples in range 0.3-0.7\n", .{@as(f64, @floatFromInt(count))/@as(f64, @floatFromInt(image_data_f.len))});

    const ppm_file = try std.fs.cwd().createFile("images/wnoisen.ppm", .{});
    defer ppm_file.close();
    try ppm_file.writeAll(image_header);
    try ppm_file.writeAll(image_data);
}

test "test permutation table generation" {
    const pn = noise.perlin.PerlinNoise2D(f32).init(@intCast(std.time.timestamp()), null);
    for(0..pn.permutation_table.len) |i| {
        std.debug.print("pn.permutation_table[{d}]: {d}\n", .{i, pn.permutation_table[i]});
    }
}

test "test 3d perlin cross section" {
}
