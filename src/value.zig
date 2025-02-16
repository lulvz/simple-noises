const std = @import("std");

// TODO add more value noises
// I saw this function in Suboptimal Engineer's video about Voronoi Noise
// https://www.youtube.com/watch?v=vcfIJ5Uu6Qw and it seemed really simple
// so I kinda took it, probably in the future I'll make my own or something
pub fn valueNoiseHash2D(T: type, x: T, y: T) struct {x: T, y: T} {
    const xt: T = @mulAdd(T, x, 123.4, (y*234.5));
    const yt: T = @mulAdd(T, y, 345.6, (y*456.7));

    const xs: T = std.math.sin(xt);
    const ys: T = std.math.sin(yt);

    const x_noise = xs * 43758.5453;
    const y_noise = ys * 43758.5453;

    return .{
        .x = x_noise - @floor(x_noise),
        .y = y_noise - @floor(y_noise),
    };
}
