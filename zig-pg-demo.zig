const std = @import("std");
const warn = std.debug.warn;
const process = std.process;
const Allocator = std.mem.Allocator;
var allocator: *Allocator = undefined;

const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("libpq-fe.h");
});

const ArgError = error{
    MissingParameters,
};

const Args = struct { exe: []const u8, host: ?[]const u8, port: ?[]const u8, user: ?[]const u8, password: ?[]const u8, database: ?[]const u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    allocator = &arena.allocator;
    var args = try parseArgs();
    var connection_data = try std.fmt.allocPrint(allocator, "user={s} password={s} port={s} host={s} dbname={s}", .{ args.user, args.password, args.port, args.host, args.database });
    var conn = c.PQconnectdb(@ptrCast([*c]const u8, connection_data));
    defer c.PQfinish(conn);
    if (@enumToInt(c.PQstatus(conn)) == c.CONNECTION_BAD) {
        var message = c.PQerrorMessage(conn);
        warn("Connection failed\n{s}\n", .{message});
        process.exit(1);
    }
    var res = c.PQexec(conn, "SELECT VERSION()");
    defer c.PQclear(res);
    if (@enumToInt(c.PQresultStatus(res)) != c.PGRES_TUPLES_OK) {
        warn("No data retrieved\n", .{});
        process.exit(1);
    }
    var result = c.PQgetvalue(res, 0, 0);
    warn("{s}\n", .{result});
}

fn usage(exe: []const u8) void {
    const str = "{s} <host> <port> <user> <password> <database>";
    warn(str, .{exe});
}

fn parseArgs() !Args {
    var args_iter = process.args();
    var exe = try args_iter.next(allocator).?;
    var parsed_args = Args{
        .exe = exe,
        .host = null,
        .port = null,
        .user = null,
        .password = null,
        .database = null,
    };
    var level: u23 = 1;
    while (args_iter.next(allocator)) |arg_or_err| {
        var arg = arg_or_err catch unreachable;
        if (level == 1) {
            parsed_args.host = arg;
            level += 1;
        } else if (level == 2) {
            parsed_args.port = arg;
            level += 1;
        } else if (level == 3) {
            parsed_args.user = arg;
            level += 1;
        } else if (level == 4) {
            parsed_args.password = arg;
            level += 1;
        } else if (level == 5) {
            parsed_args.database = arg;
            level += 1;
        } else if (level > 5) {
            break;
        }
    }
    if (level == 1) {
        usage(exe);
        return ArgError.MissingParameters;
    }
    return parsed_args;
}
