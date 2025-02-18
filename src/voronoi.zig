const std = @import("std");
const value = @import("value.zig");

pub fn VoronoiNoise2D(T: type) type {
    if (!(@typeInfo(T) == .Float)) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }
    
    return struct {
        frequency: T,

        const Self = @This();

        pub fn init(seed: u64, frequency: T) Self {
            _ = seed;
            return .{
                .frequency = frequency,
            };
        }

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

            // find the grid cell
            const xi: IntermediateIntType = @intFromFloat(@floor(scaled_x));
            const yi: IntermediateIntType = @intFromFloat(@floor(scaled_y));

            // initialize a minimum distance variable to the max of the float type
            var min_dist: T = std.math.floatMax(T);

            // loop over the adjacent squares in the grid
            var yc: IntermediateIntType = yi-1;
            while(yc <= yi + 1) : (yc += 1) {
                var xc: IntermediateIntType = xi-1;
                while(xc <= xi + 1) : (xc += 1) {
                    const a = value.valueNoiseHash2D(T, @as(T, @floatFromInt(xc)), @as(T, @floatFromInt(yc)));

                    const x_center = a.x;
                    const y_center = a.y;

                    const x_center_pos: T = @as(T, @floatFromInt(xc)) + x_center;
                    const y_center_pos: T = @as(T, @floatFromInt(yc)) + y_center;

                    const x_distance: T = x_center_pos - scaled_x;
                    const y_distance: T = y_center_pos - scaled_y;

                    const distance: T = x_distance*x_distance + y_distance*y_distance;
                    if(distance < min_dist) {
                        min_dist = distance;
                    }
                }
            }

            return std.math.sqrt(min_dist);
        }
    };
}

pub fn VoronoiNoise2DV(T: type) type {
    if (!(@typeInfo(T) == .Float)) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }
    
    return struct {
        frequency: T,

        const Self = @This();

        pub fn init(seed: u64, frequency: T) Self {
            _ = seed;
            return .{
                .frequency = frequency,
            };
        }

        pub fn generate(self: *Self, vec: @Vector(2, T)) T {
            const scaled_vec = vec * @as(@Vector(2, T), @splat(self.frequency));

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

            // find the grid cell
            const xi: IntermediateIntType = @intFromFloat(@floor(scaled_vec[0]));
            const yi: IntermediateIntType = @intFromFloat(@floor(scaled_vec[1]));

            // initialize a minimum distance variable to the max of the float type
            var min_dist_squared: T = std.math.floatMax(T);

            // loop over the adjacent squares in the grid
            var yc: IntermediateIntType = yi-1;
            while(yc <= yi + 1) : (yc += 1) {
                var xc: IntermediateIntType = xi-1;
                while(xc <= xi + 1) : (xc += 1) {
                    // float vector representation of the current grid cell
                    const cv = @Vector(2, T) { @as(T, @floatFromInt(xc)), @as(T, @floatFromInt(yc)) };

                    // offset of the seed point in that grid cell calculated by a value noise function
                    const vnoise = value.valueNoiseHash2DV(T, cv);

                    // calculate the final seed point position in the grid
                    const center_pos = cv + vnoise;

                    // direction vector
                    const dv = center_pos - scaled_vec;
                    // pythagoras, without sqrt
                    const dist_squared = @reduce(.Add, dv*dv);

                    if(dist_squared < min_dist_squared) {
                        min_dist_squared = dist_squared;
                    }
                }
            }

            // finally return the sqrt of the minimum squared distance that was found
            return @sqrt(min_dist_squared);
        }
    };
}
