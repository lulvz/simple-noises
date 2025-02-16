const std = @import("std");
const value = @import("value.zig");

pub fn VoronoiNoise2D(T: type) type {
    switch(@typeInfo(T)) {
        .Float => {},
        else => {
            @compileError("Expected float type, got " ++ @typeName(T));
        }
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

        // fn distance() T {
        // }

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
