const std = @import("std");
const expect = std.testing.expect;

const int = i64;

const UnexpectedInput = error {
    OpponentMove,
    PlayerMove,
    DesiredOutcome,
};

const SCORE_LOSS : int = 0;
const SCORE_DRAW : int = 3;
const SCORE_WIN  : int = 6;

fn score_round_p1(opponent_move: u8, player_move: u8) !int {
    switch (player_move) {
        'X' => {
            const base_score: int = 1;
            switch (opponent_move) {
                'A' => return base_score + SCORE_DRAW,   // rock - rock
                'B' => return base_score + SCORE_LOSS,   // rock - paper
                'C' => return base_score + SCORE_WIN,    // rock - scissors
                else => return UnexpectedInput.OpponentMove,
            }
        },
        'Y' => {
            const base_score: int = 2;
            switch (opponent_move) {
                'A' => return base_score + SCORE_WIN,   // paper - rock
                'B' => return base_score + SCORE_DRAW,  // paper - paper
                'C' => return base_score + SCORE_LOSS,  // paper - scissors
                else => return UnexpectedInput.OpponentMove,
            }
        },
        'Z' => {
            const base_score: int = 3;
            switch (opponent_move) {
                'A' => return base_score + SCORE_LOSS,   // scissors - rock
                'B' => return base_score + SCORE_WIN,    // scissors - paper
                'C' => return base_score + SCORE_DRAW,   // scissors - scissors
                else => return UnexpectedInput.OpponentMove,
            }
        },
        else => return UnexpectedInput.PlayerMove,
    }
}

fn score_round_p2(opponent_move: u8, desired_outome: u8) !int {
    switch (opponent_move) {
        'A' => {
            switch (desired_outome) {
                'X' => return score_round_p1('A', 'Z'),
                'Y' => return score_round_p1('A', 'X'),
                'Z' => return score_round_p1('A', 'Y'),
                else => return UnexpectedInput.DesiredOutcome,
            }
        },
        'B' => {
            switch (desired_outome) {
                'X' => return score_round_p1('B', 'X'),
                'Y' => return score_round_p1('B', 'Y'),
                'Z' => return score_round_p1('B', 'Z'),
                else => return UnexpectedInput.DesiredOutcome,
            }
        },
        'C' => {
            switch (desired_outome) {
                'X' => return score_round_p1('C', 'Y'),
                'Y' => return score_round_p1('C', 'Z'),
                'Z' => return score_round_p1('C', 'X'),
                else => return UnexpectedInput.DesiredOutcome,
            }
        },
        else => return UnexpectedInput.OpponentMove,
    }
}

pub fn main() !void {
    var buf : [1024]u8 = .{};
    var score_p1 : int = 0;
    var score_p2 : int = 0;

    while (std.io.getStdIn().reader().readUntilDelimiterOrEof(&buf, '\n')) |raw_data| {
        var data = raw_data orelse break;
        if (data.len > 0 and data[data.len - 1] == 13)
            data = data[0..data.len - 1];
        if (data.len != 3) continue;

        score_p1 += try score_round_p1(data[0], data[2]);
        score_p2 += try score_round_p2(data[0], data[2]);
    } else |err| {
        return err;
    }

    std.debug.print("{}\n{}\n", .{score_p1, score_p2});
}

test "round score" {
    try expect(try score_round_p1('A', 'Y') == 8);
    try expect(try score_round_p1('B', 'X') == 1);
    try expect(try score_round_p1('C', 'Z') == 6);

    try expect(try score_round_p2('A', 'Y') == 4);
    try expect(try score_round_p2('B', 'X') == 1);
    try expect(try score_round_p2('C', 'Z') == 7);
}
