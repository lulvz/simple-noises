const std = @import("std");

const default_permutation_table: [256]u8 = .{
    151, 160, 137, 91,  90,  15,  131, 13,  201, 95,  96,  53,  194, 233, 7,   225,
    140, 36,  103, 30,  69,  142, 8,   99,  37,  240, 21,  10,  23,  190, 6,   148,
    247, 120, 234, 75,  0,   26,  197, 62,  94,  252, 219, 203, 117, 35,  11,  32,
    57,  177, 33,  88,  237, 149, 56,  87,  174, 20,  125, 136, 171, 168, 68,  175,
    74,  165, 71,  134, 139, 48,  27,  166, 77,  146, 158, 231, 83,  111, 229, 122,
    60,  211, 133, 230, 220, 105, 92,  41,  55,  46,  245, 40,  244, 102, 143, 54,
    65,  25,  63,  161, 1,   216, 80,  73,  209, 76,  132, 187, 208, 89,  18,  169,
    200, 196, 135, 130, 116, 188, 159, 86,  164, 100, 109, 198, 173, 186, 3,   64,
    52,  217, 226, 250, 124, 123, 5,   202, 38,  147, 118, 126, 255, 82,  85,  212,
    207, 206, 59,  227, 47,  16,  58,  17,  182, 189, 28,  42,  223, 183, 170, 213,
    119, 248, 152, 2,   44,  154, 163, 70,  221, 153, 101, 155, 167, 43,  172, 9,
    129, 22,  39,  253, 19,  98,  108, 110, 79,  113, 224, 232, 178, 185, 112, 104,
    218, 246, 97,  228, 251, 34,  242, 193, 238, 210, 144, 12,  191, 179, 162, 241,
    81,  51,  145, 235, 249, 14,  239, 107, 49,  192, 214, 31,  181, 199, 106, 157,
    184, 84,  204, 176, 115, 121, 50,  45,  127, 4,   150, 254, 138, 236, 205, 93,
    222, 114, 67,  29,  24,  72,  243, 141, 128, 195, 78,  66,  215, 61,  156, 180,
};

inline fn fade(t: anytype) @TypeOf(t) {
    const Type = @TypeOf(t);
    return t*t*t*@mulAdd(Type, t, @mulAdd(Type, 6.0, t, -15.0), 10.0);
}

pub fn PerlinNoise2D(T: type) type {
    if (!(@typeInfo(T) == .Float)) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }

    return struct {
        permutation_table: [512]u8, // the table is duplicated to avoid modulo operations
        frequency: T,

        const Self = @This();
        // seed is optional, pass null to use the default permutation table from the original implementation
        pub fn init(seed: ?u64, frequency: ?T) Self {
            var permutation_table: [512]u8 = undefined;

            if(seed) |s| {
                var rng = std.rand.DefaultPrng.init(s);
                var tmp_permutation_table = default_permutation_table;
                std.rand.shuffle(rng.random(), u8, &tmp_permutation_table);
                @memcpy(permutation_table[0..], &tmp_permutation_table ** 2);
            } else {
                @memcpy(permutation_table[0..], &default_permutation_table ** 2);
            }

            return .{
                .permutation_table = permutation_table,
                .frequency = frequency orelse 1.0,
            };
        }

        // returns a value between -1.0 and 1.0
        pub fn generate(self: *Self, x: T, y: T) T {
            const scaled_x = x * self.frequency;
            const scaled_y = y * self.frequency;

            // depending on the float type T, we use different sized integers to hold the intermediate integer values
            const IntermediateIntType = switch (@typeInfo(T)) {
                .Float => |float| switch (float.bits) {
                    16 => i16,
                    32 => i32,
                    64 => i64,
                    128 => i128,
                    else => @compileError("Unsupported float type"),
                },
                else => unreachable,
            };

            // first we have to find the grid cell, for that we take the floor of the x and y values
            // and we modulo it with 256 (and operation with 255)
            const xi: usize = @intCast(@as(IntermediateIntType, @intFromFloat(@floor(scaled_x))) & 0xFF);
            const yi: usize = @intCast(@as(IntermediateIntType, @intFromFloat(@floor(scaled_y))) & 0xFF);

            // then we calculate the offset
            const xf: T = scaled_x - @floor(scaled_x);
            const yf: T = scaled_y - @floor(scaled_y);

            // now we get the gradient hash values for each corner (0 to 255) from the permutation table
            // which we then use in the gradient function to fetch a random gradient vector
            // here the 512 sized table that is just a repeated 256 sized one comes in
            // handy to avoid modulo operations
            const gh1 = self.permutation_table[self.permutation_table[xi] + yi];
            const gh2 = self.permutation_table[self.permutation_table[xi + 1] + yi];
            const gh3 = self.permutation_table[self.permutation_table[xi] + yi + 1];
            const gh4 = self.permutation_table[self.permutation_table[xi + 1] + yi + 1];

            // we pass the gradient hashes and the vector from every corner to that point to the
            // gradient function, which uses the hash to get a random vector per tile corner,
            // and do a dot product of that random vector with the offset vector
            // the resulting value represents the influence of that point in the point inside the tile,
            const d1 = gradient_dot(gh1, xf, yf); // dot product of the random gradient vector with the vector that goes from (0, 0) to (xf, yf), which is (xf - 0, yf - 0) [THIS IS IN LOCAL COORDINATES INSIDE THE TILE]
            const d2 = gradient_dot(gh2, xf - 1, yf); // dot product of the random gradient vector with the vector that goes from (1, 0) to (xf, yf), which is (xf - 1, yf - 0) [THIS IS IN LOCAL COORDINATES INSIDE THE TILE]
            const d3 = gradient_dot(gh3, xf, yf - 1); // dot product of the random gradient vector with the vector that goes from (0, 1) to (xf, yf), which is (xf - 0, yf - 1) [THIS IS IN LOCAL COORDINATES INSIDE THE TILE]
            const d4 = gradient_dot(gh4, xf - 1, yf - 1); // dot product of the random gradient vector with the vector that goes from (1, 1) to (xf, yf), which is (xf - 1, yf - 1) [THIS IS IN LOCAL COORDINATES INSIDE THE TILE]

            // finally, we use xf and yf to calculate u and v, which kinda act like uv coords in textures, they specify
            // where in the tile we are, so 0.5,0.5 would be exactly in the middle
            // we use a fade function to ease transitions around grid boundaries
            const u = fade(xf);
            const v = fade(yf);

            // now we have to interpolate the values we got from the dot products to blend the values
            // first we do it along the x axis
            const ix1 = std.math.lerp(d1, d2, u);
            const ix2 = std.math.lerp(d3, d4, u);

            // then we do it along the y axis with the already interpolated values form the x axis
            return std.math.lerp(ix1, ix2, v);
        }

        fn gradient_dot(hash: u8, xf: T, yf: T) T {
            // we basically do a modulo operation on the possible 256 hash values,
            // to convert to 8 possible directions
            // then we do a dot product of that direction by the local coordinates (xf, yf)

            // for now we have 4 directions, one in each diagonal, so (1, 1), (1, -1), (-1, 1), (-1, -1)
            // TODO possible improvement make this use more directions
            switch (hash & 0x03) {
                0 => { // (1, 1)
                    return xf + yf; // this (1, 1) . (xf, yf) = xf + yf
                },
                1 => { // (1, -1)
                    return xf - yf;
                },
                2 => { // (-1, 1)
                    return -xf + yf;
                },
                3 => { // (-1, -1)
                    return -xf - yf;
                },
                else => {
                    unreachable;
                }
            }
        }
    };
}

pub fn PerlinNoise3D(T: type) type {
    if (!(@typeInfo(T) == .Float)) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }

    return struct {
        permutation_table: [512]u8,
        frequency: T,

        const Self = @This();
        pub fn init(seed: ?u64, frequency: ?T) Self {
            var permutation_table: [512]u8 = undefined;

            if(seed) |s| {
                var rng = std.rand.DefaultPrng.init(s);
                var tmp_permutation_table = default_permutation_table;
                std.rand.shuffle(rng.random(), u8, &tmp_permutation_table);
                @memcpy(permutation_table[0..], &tmp_permutation_table ** 2);
            } else {
                @memcpy(permutation_table[0..], &default_permutation_table ** 2);
            }

            return .{
                .permutation_table = permutation_table,
                .frequency = frequency orelse 1.0,
            };
        }

        pub fn generate(self: *Self, x: T, y: T, z: T) T {
            const scaled_x = x * self.frequency;
            const scaled_y = y * self.frequency;
            const scaled_z = z * self.frequency;

            const IntermediateIntType = switch (@typeInfo(T)) {
                .Float => |float| switch (float.bits) {
                    16 => i16,
                    32 => i32,
                    64 => i64,
                    128 => i128,
                    else => @compileError("Unsupported float type"),
                },
                else => unreachable,
            };

            const xi: usize = @intCast(@as(IntermediateIntType, @intFromFloat(@floor(scaled_x))) & 0xFF);
            const yi: usize = @intCast(@as(IntermediateIntType, @intFromFloat(@floor(scaled_y))) & 0xFF);
            const zi: usize = @intCast(@as(IntermediateIntType, @intFromFloat(@floor(scaled_z))) & 0xFF);

            const xf: T = scaled_x - @floor(scaled_x);
            const yf: T = scaled_y - @floor(scaled_y);
            const zf: T = scaled_z - @floor(scaled_z);

            const gh1 = self.permutation_table[self.permutation_table[self.permutation_table[xi] + yi] + zi];
            const gh2 = self.permutation_table[self.permutation_table[self.permutation_table[xi + 1] + yi] + zi];
            const gh3 = self.permutation_table[self.permutation_table[self.permutation_table[xi] + yi + 1] + zi];
            const gh4 = self.permutation_table[self.permutation_table[self.permutation_table[xi + 1] + yi + 1] + zi];

            const gh5 = self.permutation_table[self.permutation_table[self.permutation_table[xi] + yi] + zi + 1];
            const gh6 = self.permutation_table[self.permutation_table[self.permutation_table[xi + 1] + yi] + zi + 1];
            const gh7 = self.permutation_table[self.permutation_table[self.permutation_table[xi] + yi + 1] + zi + 1];
            const gh8 = self.permutation_table[self.permutation_table[self.permutation_table[xi + 1] + yi + 1] + zi + 1];

            const d1 = gradient_dot(gh1, xf, yf, zf);
            const d2 = gradient_dot(gh2, xf - 1, yf, zf);
            const d3 = gradient_dot(gh3, xf, yf - 1, zf);
            const d4 = gradient_dot(gh4, xf - 1, yf - 1, zf);

            const d5 = gradient_dot(gh5, xf, yf, zf - 1);
            const d6 = gradient_dot(gh6, xf - 1, yf, zf - 1);
            const d7 = gradient_dot(gh7, xf, yf - 1, zf - 1);
            const d8 = gradient_dot(gh8, xf - 1, yf - 1, zf - 1);

            const u = fade(xf);
            const v = fade(yf);
            const w = fade(zf);

            const ix1 = std.math.lerp(d1, d2, u);
            const ix2 = std.math.lerp(d3, d4, u);
            const ix3 = std.math.lerp(d5, d6, u);
            const ix4 = std.math.lerp(d7, d8, u);

            const iy1 = std.math.lerp(ix1, ix2, v);
            const iy2 = std.math.lerp(ix3, ix4, v);

            return std.math.lerp(iy1, iy2, w);
        }

        fn gradient_dot(hash: u8, xf: T, yf: T, zf: T) T {
            switch (hash & 0x07) {
                0 => return xf + yf + zf,      // (1,1,1)
                1 => return -xf + yf + zf,     // (-1,1,1)
                2 => return xf - yf + zf,      // (1,-1,1)
                3 => return -xf - yf + zf,     // (-1,-1,1)
                4 => return xf + yf - zf,      // (1,1,-1)
                5 => return -xf + yf - zf,     // (-1,1,-1)
                6 => return xf - yf - zf,      // (1,-1,-1)
                7 => return -xf - yf - zf,     // (-1,-1,-1)
                else => unreachable,
            }
        }
    };
}
