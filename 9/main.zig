const std = @import("std");

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
    const allocator: std.mem.Allocator = std.heap.page_allocator;
    const stdin = std.io.getStdIn();

    var debug = false;
    {
        var args = std.process.args();
        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "-d")) {
                debug = true;

                if (args.next()) |time_str| {
                    const sleep_time = try std.fmt.parseInt(u64, time_str, 10);
                    std.debug.print("waiting...\n", .{});
                    std.time.sleep(sleep_time * 1_000_000_000);
                }
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

    try one(allocator, moves.items, debug);
}

fn one(allocator: std.mem.Allocator, moves: []const Move, debug: bool) !void {
    var state = State.init();
    var tail_locations = std.AutoHashMap(Vec2, u32).init(allocator);

    if (debug) {
        std.debug.print("{}\n", .{state});
    }

    for (moves) |move| {
        if (debug) {
            std.debug.print("{}\n", .{move});
        }

        var i: u32 = 0;
        while (i < move.magnitude) : (i += 1) {
            try state.moveHead(move.direction);

            if (tail_locations.get(state.tail)) |old_val| {
                try tail_locations.put(state.tail, old_val + 1);
            } else {
                try tail_locations.put(state.tail, 1);
            }

            if (debug) {
                std.debug.print("{}\n", .{state});
            }
        }
    }

    var tail_locations_iter = tail_locations.iterator();
    while (tail_locations_iter.next()) |entry| {
        const point = entry.key_ptr.*;
        const count = entry.value_ptr.*;

        try std.fmt.format(std.io.getStdOut().writer(), "{}:{}\n", .{point, count});
    }

    try std.fmt.format(std.io.getStdOut().writer(), "{}\n", .{tail_locations.count()});
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

const State = struct {
    start: Vec2 = .{ .x = 0, .y = 0 },
    head: Vec2 = .{ .x = 0, .y = 0 },
    tail: Vec2 = .{ .x = 0, .y = 0 },

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

        try self.correctTail();
    }

    fn correctTail(self: *@This()) !void {
        const distance = self.tail.distance(self.head);
        const abs_distance = try distance.abs();

        // If the tail is touching the head, nothing to do.
        if (abs_distance.x <= 1 and abs_distance.y <= 1) {
            return;
        }

        const sign_x = std.math.sign(distance.x);
        const sign_y = std.math.sign(distance.y);

        // Check if we just need to move horizontally.
        if (abs_distance.x > 1 and abs_distance.y == 0) {
            self.moveTail(.{ .x = self.tail.x + sign_x, .y = self.tail.y });
            return;
        }

        // Check if we just need to move vertically.
        if (abs_distance.x == 0 and abs_distance.y > 1) {
            self.moveTail(.{ .x = self.tail.x, .y = self.tail.y + sign_y });
            return;
        }

        // Check if we need to move horizontally and vertically.
        {
            if (std.meta.eql(abs_distance, Vec2{ .x = 1, .y = 2 })) {
                self.moveTail(.{ .x = self.head.x, .y = self.head.y - sign_y });
                return;
            }

            if (std.meta.eql(abs_distance, Vec2{ .x = 2, .y = 1 })) {
                self.moveTail(.{ .x = self.head.x - sign_x, .y = self.head.y });
                return;
            }
        }

        std.debug.print("{}", .{self});
        unreachable;
    }

    fn moveTail(self: *@This(), to: Vec2) void {
        self.tail = to;
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        const SPACE = 5;

        var bounds = Vec2.bounds(&[_]Vec2{ self.start, self.head, self.tail });
        bounds.topRight = bounds.topRight.add(.{ .x = SPACE, .y = SPACE });
        bounds.bottomLeft = bounds.bottomLeft.add(.{ .x = -SPACE, .y = -SPACE });

        var y = bounds.topRight.y;
        while (y >= bounds.bottomLeft.y) : (y -= 1) {
            var x = bounds.bottomLeft.x;
            while (x <= bounds.topRight.x) : (x += 1) {
                const point: Vec2 = .{ .x = x, .y = y };

                if (std.meta.eql(point, self.head)) {
                    try writer.print("H ", .{});
                    continue;
                }

                if (std.meta.eql(point, self.tail)) {
                    try writer.print("T ", .{});
                    continue;
                }

                if (std.meta.eql(point, self.start)) {
                    try writer.print("s ", .{});
                    continue;
                }

                try writer.print(". ", .{});
            }

            try writer.writeAll("\n");
        }

        try writer.print("head: {}, tail: {}, start: {}", .{ self.head, self.tail, self.start });
    }
};
