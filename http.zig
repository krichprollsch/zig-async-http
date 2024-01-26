const std = @import("std");
const http = std.http;
const stdcli = @import("Client.zig");

pub const IO = @import("tigerbeetle-io/io.zig").IO;

pub const Client = struct {
    cli: stdcli,

    pub fn init(alloc: std.mem.Allocator, io: *IO) Client {
        return .{ .cli = .{
            .allocator = alloc,
            .io = io,
        } };
    }

    pub fn deinit(self: *Client) void {
        self.cli.deinit();
    }

    pub fn create(self: *Client, uri: std.Uri) Request {
        return .{
            .cli = &self.cli,
            .uri = uri,
            .headers = .{ .allocator = self.cli.allocator, .owned = false },
        };
    }
};

pub const Request = struct {
    cli: *stdcli,
    uri: std.Uri,
    headers: std.http.Headers,

    completion: IO.Completion = undefined,
    done: bool = false,
    err: ?anyerror = null,

    pub fn deinit(self: *Request) void {
        self.headers.deinit();
    }

    pub fn fetch(self: *Request) !void {
        self.cli.io.timeout(*Request, self, callback, &self.completion, 0);
    }

    fn onerr(self: *Request, err: anyerror) void {
        self.err = err;
    }

    fn callback(self: *Request, _: *IO.Completion, _: IO.TimeoutError!void) void {
        defer self.done = true;
        var req = self.cli.open(.GET, self.uri, self.headers, .{}) catch |err| return self.onerr(err);
        defer req.deinit();

        req.send(.{}) catch |err| return self.onerr(err);
        req.finish() catch |err| return self.onerr(err);
        req.wait() catch |err| return self.onerr(err);
    }

    pub fn wait(self: *Request) !void {
        while (!self.done) try self.cli.io.tick();
        if (self.err) |err| return err;
    }
};
