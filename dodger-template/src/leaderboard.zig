const std = @import("std");
const ArrayList = std.ArrayList;
usingnamespace @import("c.zig");
usingnamespace @import("constants.zig");

const TB_CREATE_SQL =
    c\\ CREATE TABLE IF NOT EXISTS scores(
    c\\   id     INTEGER PRIMARY KEY AUTOINCREMENT,
    c\\   name   TEXT NOT NULL,
    c\\   score  REAL NOT NULL );
;

const TB_SELECT_TOPTEN_SCORES =
    c\\ SELECT name, score
    c\\ FROM scores
    c\\ ORDER BY score DESC
    c\\ LIMIT 10;
;

const TB_INSERT_SCORE =
    c\\ INSERT INTO scores
    c\\   (name, score)
    c\\ VALUES
    c\\   (?, ?);
;

pub const LeaderBoard = struct {
    db: *sqlite3,
    tb_select_topten_scores_stmt: *sqlite3_stmt,
    tb_insert_score_stmt: *sqlite3_stmt,

    pub fn init() !LeaderBoard {
        var raw_db: ?*sqlite3 = undefined;
        if (sqlite3_open(c"scores.db", &raw_db) != 0) {
            return error.CantOpenScoresDB;
        }

        const db = raw_db orelse return error.CantOpenScoresDB;

        errdefer _ = sqlite3_close(db);

        const tb_create_sql_len = strlen(TB_CREATE_SQL);
        var tb_create_stmt: ?*sqlite3_stmt = undefined;
        var rc = sqlite3_prepare_v2(db, TB_CREATE_SQL, @intCast(c_int, tb_create_sql_len), &tb_create_stmt, null);
        if (rc != SQLITE_OK) {
            std.debug.warn("sqlite3 error: {}\n", rc);
            return error.CantInitScoresDB;
        }

        rc = sqlite3_step(tb_create_stmt);
        if (rc != SQLITE_DONE) {
            std.debug.warn("sqlite3 error: {}\n", rc);
            return error.CantInitScoresDB;
        }

        _ = sqlite3_finalize(tb_create_stmt);

        // Prepare SELECT_TOPTEN statement
        const tb_select_topten_scores_len = strlen(TB_SELECT_TOPTEN_SCORES);
        var tb_select_topten_scores_stmt: ?*sqlite3_stmt = undefined;
        rc = sqlite3_prepare_v2(db, TB_SELECT_TOPTEN_SCORES, @intCast(c_int, tb_select_topten_scores_len), &tb_select_topten_scores_stmt, null);
        if (rc != SQLITE_OK) {
            return error.CantInitSelectTopTen;
        }
        errdefer _ = sqlite3_finalize(tb_select_topten_scores_stmt);

        // Prepare INSERT_SCORE statement
        const tb_insert_score_len = strlen(TB_INSERT_SCORE);
        var tb_insert_score_stmt: ?*sqlite3_stmt = undefined;
        rc = sqlite3_prepare_v2(db, TB_INSERT_SCORE, @intCast(c_int, tb_insert_score_len), &tb_insert_score_stmt, null);
        if (rc != SQLITE_OK) {
            return error.CantInitInsertScore;
        }
        errdefer _ = sqlite3_finalize(tb_insert_score_stmt);

        return LeaderBoard{
            .db = db,
            .tb_select_topten_scores_stmt = tb_select_topten_scores_stmt orelse return error.CantInitSelectTopTen,
            .tb_insert_score_stmt = tb_insert_score_stmt orelse return error.CantInitInsertScore,
        };
    }

    pub fn get_topten_scores(self: *const LeaderBoard, scores: *ArrayList(Score)) !void {
        _ = sqlite3_reset(self.tb_select_topten_scores_stmt);
        while (true) {
            const rc = sqlite3_step(self.tb_select_topten_scores_stmt);
            switch (rc) {
                SQLITE_DONE => break,
                SQLITE_ROW => {
                    const name: [*]const u8 = sqlite3_column_text(self.tb_select_topten_scores_stmt, 0) orelse return error.LoadingResults;
                    const name_len = std.math.min(strlen(name), NAME_MAX_LENGTH);
                    const score = sqlite3_column_double(self.tb_select_topten_scores_stmt, 1);

                    const score_struct = try scores.addOne();
                    score_struct.name = ArrayList(u8).init(scores.allocator);
                    try score_struct.name.appendSlice(name[0..name_len]);
                    score_struct.score = score;
                },
                else => {
                    std.debug.warn("sqlite3 error: {}\n", rc);
                    return error.SqliteError;
                },
            }
        }
    }

    pub fn add_score(self: *const LeaderBoard, name: []const u8, score: f64) !void {
        var rc: c_int = undefined;
        if (name.len > NAME_MAX_LENGTH) {
            return error.NameTooLong;
        }

        rc = sqlite3_reset(self.tb_insert_score_stmt);
        if (rc != SQLITE_OK) {
            std.debug.warn("sqlite3 error: {}\n", rc);
            return error.SqliteError;
        }

        // Workaround Zig translate-c not being able to translate SQLITE_TRANSIENT into an actual value
        const S: isize = -1;
        const _SQLITE_TRANSIENT: extern fn (?*c_void) void = @intToPtr(extern fn (?*c_void) void, @bitCast(usize, S));

        rc = sqlite3_bind_text(self.tb_insert_score_stmt, 1, name.ptr, @intCast(c_int, name.len), _SQLITE_TRANSIENT);
        if (rc != SQLITE_OK) {
            std.debug.warn("sqlite3 error: {}\n", rc);
            return error.SqliteError;
        }

        rc = sqlite3_bind_double(self.tb_insert_score_stmt, 2, score);
        if (rc != SQLITE_OK) {
            std.debug.warn("sqlite3 error: {}\n", rc);
            return error.SqliteError;
        }

        switch (sqlite3_step(self.tb_insert_score_stmt)) {
            SQLITE_DONE | SQLITE_OK | SQLITE_ROW => {},
            else => |val| {
                std.debug.warn("sqlite3 error: {}\n", val);
                return error.CantInsertScore;
            },
        }
    }

    pub fn deinit(self: *const LeaderBoard) void {
        _ = sqlite3_finalize(self.tb_select_topten_scores_stmt);
        _ = sqlite3_finalize(self.tb_insert_score_stmt);
        _ = sqlite3_close(self.db);
    }
};

pub const Score = struct {
    name: ArrayList(u8),
    score: f64,

    fn deinit(self: *const Score) void {
        self.name.deinit();
    }
};
