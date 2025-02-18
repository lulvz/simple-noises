const std = @import("std");

// TODO add more value noises
// I saw this function in Suboptimal Engineer's video about Voronoi Noise
// https://www.youtube.com/watch?v=vcfIJ5Uu6Qw and it seemed really simple
// so I kinda took it, probably in the future I'll make my own or something
pub fn valueNoiseHash2D(T: type, x: T, y: T) struct {x: T, y: T} {
    if (!(@typeInfo(T) == .Float)) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }

    const xt: T = @mulAdd(T, x, 123.4, (y*234.5));
    const yt: T = @mulAdd(T, x, 345.6, (y*456.7));

    const xs: T = std.math.sin(xt);
    const ys: T = std.math.sin(yt);

    const x_noise = xs * 43758.5453;
    const y_noise = ys * 43758.5453;

    return .{
        .x = x_noise - @floor(x_noise),
        .y = y_noise - @floor(y_noise),
    };
}

pub fn valueNoiseHash2DV(T: type, vec: @Vector(2, T)) @Vector(2, T) {
    if (!(@typeInfo(T) == .Float)) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }

    const rv1 = @Vector(2, T){ 123.4, 234.5 };
    const rv2 = @Vector(2, T){ 345.6, 456.7 };

    const transformed = @Vector(2, T) {
        @reduce(.Add, vec*rv1),
        @reduce(.Add, vec*rv2)
    };

    const sinned = @sin(transformed);
    const noise = sinned * @as(@Vector(2, T), @splat(43758.5453));
    return noise - @floor(noise);
}

test "valueNoiseHash2DV" {
    const vf = @Vector(2, f32){1.0, 2.0};

    const vr = valueNoiseHash2DV(f32, vf);
    const a = valueNoiseHash2D(f32, vf[0], vf[1]);

    std.debug.print("{}\n", .{vr});
    std.debug.print("{}\n", .{a});
}
