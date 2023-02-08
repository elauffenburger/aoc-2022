const std = @import("std");
const fmt = std.fmt;

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

    var moves = std.ArrayList(Move).init(allocator);
    while (true) {
        if (stdin.reader().readUntilDelimiterAlloc(allocator, '\n', 1000)) |line| {
            const move = try Move.fromLine(line);

            try moves.append(move);
        } else |err| switch (err) {
            error.EndOfStream => break,
            else => unreachable,
        }
    }

    try one(allocator, moves.items);
}

fn one(allocator: std.mem.Allocator, moves: []const Move) !void {
    var state = State.init();
    var tail_locations = std.AutoHashMap(Vec2, bool).init(allocator);

    for (moves) |move| {
        try state.moveHead(move);

        try tail_locations.put(state.tail, true);
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
};

const State = struct {
    start: Vec2 = .{ .x = 0, .y = 0 },
    head: Vec2 = .{ .x = 0, .y = 0 },
    tail: Vec2 = .{ .x = 0, .y = 0 },

    fn init() @This() {
        return .{};
    }

    fn moveHead(self: *@This(), move: Move) !void {
        switch (move.direction) {
            .up => self.head.y += 1,
            .right => self.head.x += 1,
            .down => self.head.y -= 1,
            .left => self.head.x -= 1,
        }

        try self.correctTail();
    }

    fn correctTail(self: *@This()) !void {
        const distance = self.head.distance(self.tail);
        const abs_distance = try distance.abs();

        // If the tail is touching the head, nothing to do.
        if (abs_distance.x <= 1 and abs_distance.y <= 1) {
            return;
        }

        // If the tail is behind or ahead of the head, move it towards the head.
        if (std.meta.eql(abs_distance, .{ .x = 1, .y = 0 })) {
            self.tail.x += distance.x;
        }

        // If the tail is above or below the head, move it towards the head.
        if (std.meta.eql(abs_distance, .{ .x = 0, .y = 1 })) {
            self.tail.y += distance.y;
        }

        // If the tail is above or below and behind or ahead the head, move it towards the head.
        if (std.meta.eql(abs_distance, .{ .x = 1, .y = 1 })) {
            self.tail.x += distance.x;
            self.tail.y += distance.y;
        }

        unreachable;
    }
};
