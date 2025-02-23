const std = @import("std");

pub fn WhiteNoise(T: type) type {
    if (@typeInfo(T) != .Float) {
        @compileError("Expected float type, got " ++ @typeName(T));
    }

    switch (@typeInfo(T)) {
        .Float => |float| switch (float.bits) {
            32, 64 => {},
            else => @compileError("Unsupported float type"),
        },
        else => @compileError("Expected float type, got " ++ @typeName(T)),
    }

    return struct {
        prng: std.rand.Xoshiro256,

        const Self = @This();

        pub fn init(seed: u64) Self {
            const prng = std.rand.DefaultPrng.init(seed);

            return .{
                .prng = prng,
            };
        }

        // default generator uses a uniform distribution, this means every value has the same
        // probability of occurring
        // returns values in the range [0, 1)
        pub fn fill_uniform(self: *Self, target: []T) void {
            const random = self.prng.random();
            for (target) |*t| {
                t.* = random.float(T);
            }
        }
        
        // Fills the target array with normally distributed random values
        // Uses the Box-Muller transform to generate values from a standard normal 
        // distribution (mean = 0, standard deviation = 1)
        // Theoretically, values can range from -infinity to infinity
        // Potential future improvement: switch to the Ziggurat algorithm for performance
        pub fn fill_gaussian(self: *Self, target: []T) void {
            const random = self.prng.random();
            var i: usize = 0;
            // https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
            while(i < target.len) : (i += 2) {
                const u_1 = random.float(T);
                const u_2 = random.float(T);

                const r = @sqrt(-2 * @log(u_1));
                const angle = 2*std.math.pi * u_2;

                const z_0 = r * @cos(angle);
                target[i] = z_0;

                const next = i + 1;
                if(next < target.len) {
                    const z_1 = r * @sin(angle);
                    target[next] = z_1;
                }
            }
        }
    };
}

test "white noise uniform distribution" {
    var wn = WhiteNoise(f64).init(@intCast(std.time.timestamp()));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const buffer = try allocator.alloc(f64, 10*10);
    defer allocator.free(buffer);

    wn.generate_uniform(buffer);

    for(buffer) |b| {
        std.debug.print("{d}\n", .{b});
    }
}
