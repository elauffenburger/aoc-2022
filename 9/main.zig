const std = @import("std");
const c = @cImport({
    @cInclude("signal.h");
});

pub fn main() void {
    emain() catch |e| {
        std.debug.print("error: {}\n", .{e});
        std.os.exit(1);
    };
}

const Move = struct {
    const Direction = enum {
        up,
        right,
        down,
        left,
    };

    direction: Direction,
    magnitude: u32,

    fn fromLine(line: []const u8) !@This() {
        var line_parts = std.mem.split(u8, line, " ");

        const direction: Move.Direction = blk: {
            const ch = line_parts.next().?[0];
            switch (ch) {
                'U' => break :blk .up,
                'R' => break :blk .right,
                'D' => break :blk .down,
                'L' => break :blk .left,
                else => {
                    std.debug.print("{}\n", .{ch});
                    unreachable;
                },
            }
        };

        const magnitude = try std.fmt.parseInt(u32, std.mem.trimRight(u8, line_parts.next().?, "\n"), 10);

        return .{ .direction = direction, .magnitude = magnitude };
    }
};

fn emain() !void {
    const ParseArgsError = error{
        InvalidDebugArg,
    };

    const allocator: std.mem.Allocator = std.heap.page_allocator;
    const stdin = std.io.getStdIn();

    var debug = false;
    var show_moves = false;
    {
        var args = std.process.args();
        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "-d")) {
                debug = true;

                if (args.next()) |debug_arg| {
                    if (!std.mem.eql(u8, debug_arg, "attach")) {
                        return ParseArgsError.InvalidDebugArg;
                    }

                    std.debug.print("waiting for debugger...\n", .{});

                    var sig: c_int = 1;
                    const sig_set = [_]c.sigset_t{c.SIGINT};
                    _ = c.sigwait(&sig_set, &sig);
                    continue;
                }

                continue;
            }

            if (std.mem.eql(u8, arg, "-m")) {
                show_moves = true;
                continue;
            }
        }
    }

    var moves = std.ArrayList(Move).init(allocator);
    var stdin_rdr = stdin.reader();
    while (true) {
        const line = try stdin_rdr.readUntilDelimiterOrEofAlloc(allocator, '\n', 1000);
        if (line == null) {
            break;
        }

        const move = try Move.fromLine(line.?);
        try moves.append(move);
    }

    try two(allocator, moves.items, .{ .show_moves = show_moves, .debug = debug });
}

fn two(allocator: std.mem.Allocator, moves: []const Move, opts: struct { show_moves: bool, debug: bool }) !void {
    var state = State(9).init();
    var tail_locations = std.AutoHashMap(Vec2, u32).init(allocator);

    if (opts.debug) {
        std.debug.print("{}\n", .{state});
    }

    for (moves) |move| {
        if (opts.debug or opts.show_moves) {
            std.debug.print("{}\n", .{move});
        }

        var i: u32 = 0;
        while (i < move.magnitude) : (i += 1) {
            try state.moveHead(move.direction);

            const tail = state.tail();
            if (tail_locations.get(tail)) |old_val| {
                try tail_locations.put(tail, old_val + 1);
            } else {
                try tail_locations.put(tail, 1);
            }

            if (opts.debug) {
                std.debug.print("{}\n", .{state});
            }
        }
    }

    {
        const writer = std.io.getStdOut().writer();

        const keys = blk: {
            var iter = tail_locations.keyIterator();
            var keys = std.ArrayList(Vec2).init(allocator);
            while (iter.next()) |key| {
                try keys.append(key.*);
            }

            break :blk keys;
        };

        const tailLocationT = @TypeOf(tail_locations);
        const Printer = struct {
            tailLocations: tailLocationT,
            writer: @TypeOf(writer),

            pub fn printPoint(self: @This(), point: Vec2) !void {
                if (self.tailLocations.contains(point)) {
                    try self.writer.writeAll("# ");
                } else {
                    try self.writer.writeAll(". ");
                }
            }

            pub fn writeAll(self: @This(), bytes: []const u8) !void {
                try self.writer.writeAll(bytes);
            }
        };

        try printPoints(keys.items, Printer{
            .writer = writer,
            .tailLocations = tail_locations,
        });

        try std.fmt.format(writer, "{}\n", .{tail_locations.count()});
    }
}

const Vec2 = struct {
    x: i32,
    y: i32,

    fn distance(self: @This(), other: @This()) @This() {
        return .{ .x = other.x - self.x, .y = other.y - self.y };
    }

    fn abs(self: @This()) !@This() {
        return .{
            .x = try std.math.absInt(self.x),
            .y = try std.math.absInt(self.y),
        };
    }

    fn unit(self: @This()) !@This() {
        return .{
            .x = if (self.x == 0) 0 else if (self.x > 0) 1 else -1,
            .y = if (self.y == 0) 0 else if (self.y > 0) 1 else -1,
        };
    }

    fn add(self: @This(), other: @This()) @This() {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    fn bounds(vecs: []const @This()) Bounds {
        var result: Bounds = .{
            .bottomLeft = .{ .x = 0, .y = 0 },
            .topRight = .{ .x = 0, .y = 0 },
        };

        for (vecs) |vec| {
            if (vec.x < result.bottomLeft.x) {
                result.bottomLeft.x = vec.x;
            }

            if (vec.y < result.bottomLeft.y) {
                result.bottomLeft.y = vec.y;
            }

            if (vec.x > result.topRight.x) {
                result.topRight.x = vec.x;
            }

            if (vec.y > result.topRight.y) {
                result.topRight.y = vec.y;
            }
        }

        return result;
    }
};

const Bounds =
    struct { bottomLeft: Vec2, topRight: Vec2 };

fn State(comptime numKnots: u32) type {
    return struct {
        start: Vec2 = .{ .x = 0, .y = 0 },
        head: Vec2 = .{ .x = 0, .y = 0 },
        knots: [numKnots]Vec2 = [_]Vec2{.{ .x = 0, .y = 0 }} ** numKnots,

        fn init() @This() {
            return .{};
        }

        fn moveHead(self: *@This(), direction: Move.Direction) !void {
            switch (direction) {
                .up => self.head.y += 1,
                .right => self.head.x += 1,
                .down => self.head.y -= 1,
                .left => self.head.x -= 1,
            }
            // std.debug.print("{}\n", .{self.*});

            for (self.knots) |*knot, i| {
                const nextKnot = if (i == 0) self.head else self.knots[i - 1];
                const old_knot = knot.*;

                try self.correctKnot(knot, nextKnot);

                if (!std.meta.eql(old_knot, knot.*)) {
                    // std.debug.print("{}\n", .{self.*});
                }
            }
        }

        fn correctKnot(self: *@This(), knot: *Vec2, nextKnot: Vec2) !void {
            const distance = knot.*.distance(nextKnot);
            const abs_distance = try distance.abs();

            // If the knot is touching the next knot, nothing to do.
            if (abs_distance.x <= 1 and abs_distance.y <= 1) {
                return;
            }

            const sign_x = std.math.sign(distance.x);
            const sign_y = std.math.sign(distance.y);

            // Check if we just need to move horizontally.
            if (abs_distance.x > 1 and abs_distance.y == 0) {
                knot.*.x += sign_x;
                return;
            }

            // Check if we just need to move vertically.
            if (abs_distance.x == 0 and abs_distance.y > 1) {
                knot.*.y += sign_y;
                return;
            }

            // Check if we need to move horizontally and vertically.
            {
                knot.*.x += 1 * sign_x;
                knot.*.y += 1 * sign_y;
                return;
            }

            std.debug.print("{}", .{self});
            unreachable;
        }

        fn tail(self: @This()) Vec2 {
            return self.knots[numKnots - 1];
        }

        pub fn format(
            self: @This(),
            comptime _: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            const Printer = struct {
                start: Vec2,
                head: Vec2,
                knots: [numKnots]Vec2,
                writer: @TypeOf(writer),

                pub fn printPoint(printer: @This(), point: Vec2) !void {
                    if (std.meta.eql(point, printer.head)) {
                        try printer.writer.writeAll("H ");
                        return;
                    }

                    for (printer.knots) |knot, i| {
                        if (std.meta.eql(point, knot)) {
                            try printer.writer.print("{} ", .{i + 1});
                            return;
                        }
                    }

                    if (std.meta.eql(point, printer.start)) {
                        try printer.writer.writeAll("s ");
                        return;
                    }

                    try printer.writer.writeAll(". ");
                }

                pub fn writeAll(printer: @This(), bytes: []const u8) !void {
                    try printer.writer.writeAll(bytes);
                }
            };

            try printPoints(&[_]Vec2{ self.start, self.head } ++ &self.knots, Printer{
                .start = self.start,
                .head = self.head,
                .knots = self.knots,
                .writer = writer,
            });
        }
    };
}

fn printPoints(points: []const Vec2, printer: anytype) !void {
    const SPACE = 5;

    var bounds = Vec2.bounds(points);
    bounds.topRight = bounds.topRight.add(.{ .x = SPACE, .y = SPACE });
    bounds.bottomLeft = bounds.bottomLeft.add(.{ .x = -SPACE, .y = -SPACE });

    var y = bounds.topRight.y;
    while (y >= bounds.bottomLeft.y) : (y -= 1) {
        var x = bounds.bottomLeft.x;
        while (x <= bounds.topRight.x) : (x += 1) {
            const point: Vec2 = .{ .x = x, .y = y };

            try printer.printPoint(point);
        }

        try printer.writeAll("\n");
    }
}
