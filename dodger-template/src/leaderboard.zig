const std = @import("std");
usingnamespace @import("c.zig");

pub const LeaderBoard = struct {
    db: *sqlite3,

    pub fn init() !LeaderBoard {
        var raw_db: ?*sqlite3 = undefined;
        if (sqlite3_open(c"scores.db", &raw_db) != 0) {
            return error.CantOpenScoresDB;
        }

        const self = LeaderBoard{
            .db = raw_db orelse return error.CantOpenScoresDB,
        };

        errdefer _ = sqlite3_close(self.db);

        const tb_create_sql =
            c\\ CREATE TABLE IF NOT EXISTS SCORES(
            c\\   ID INT PRIMARY KEY NOT NULL,
            c\\   NAME   TEXT NOT NULL,
            c\\   SCORE  REAL NOT NULL );
        ;
        const tb_create_sql_len = strlen(tb_create_sql);
        var tb_create_stmt: ?*sqlite3_stmt = undefined;
        var rc = sqlite3_prepare_v2(self.db, tb_create_sql, @intCast(c_int, tb_create_sql_len), &tb_create_stmt, null);
        if (rc != SQLITE_OK) {
            return error.CantInitScoresDB;
        }

        rc = sqlite3_step(tb_create_stmt);
        if (rc != SQLITE_DONE) {
            std.debug.warn("sqlite3 error: {}\n", rc);
            return error.CantInitScoresDB;
        }

        _ = sqlite3_finalize(tb_create_stmt);

        return self;
    }

    pub fn deinit(self: *const LeaderBoard) void {
        _ = sqlite3_close(self.db);
    }
};
