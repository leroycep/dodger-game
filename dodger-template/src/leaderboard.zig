const std = @import("std");
usingnamespace @import("c.zig");

const TB_CREATE_SQL =
    c\\ CREATE TABLE IF NOT EXISTS scores(
    c\\   id     INT PRIMARY KEY NOT NULL,
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

    pub fn deinit(self: *const LeaderBoard) void {
        _ = sqlite3_finalize(self.tb_select_topten_scores_stmt);
        _ = sqlite3_finalize(self.tb_insert_score_stmt);
        _ = sqlite3_close(self.db);
    }
};
