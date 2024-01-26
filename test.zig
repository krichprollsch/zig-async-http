const std = @import("std");
const http = std.http;
const StdClient = @import("Client.zig");
const hasync = @import("http.zig");

pub const IO = @import("tigerbeetle-io/io.zig").IO;

test "blocking mode fetch API" {
    const alloc = std.testing.allocator;

    var io = try IO.init(32, 0);
    defer io.deinit();

    var client: StdClient = .{
        .allocator = alloc,
        .io = &io,
    };
    defer client.deinit();

    // force client's CA cert scan from system.
    try client.ca_bundle.rescan(client.allocator);

    var res = try client.fetch(alloc, .{
        .location = .{ .uri = try std.Uri.parse("https://blg.tch.re") },
        .payload = .none,
    });
    defer res.deinit();

    try std.testing.expect(res.status == .ok);
}

test "blocking mode open/send/wait API" {
    const alloc = std.testing.allocator;

    var io = try IO.init(32, 0);
    defer io.deinit();

    var client: StdClient = .{
        .allocator = alloc,
        .io = &io,
    };
    defer client.deinit();

    // force client's CA cert scan from system.
    try client.ca_bundle.rescan(client.allocator);

    var headers = try std.http.Headers.initList(alloc, &[_]std.http.Field{});
    defer headers.deinit();

    var req = try client.open(.GET, try std.Uri.parse("https://blg.tch.re"), headers, .{});
    defer req.deinit();

    try req.send(.{});
    try req.finish();
    try req.wait();

    try std.testing.expect(req.response.status == .ok);
}

test "non blocking mode API" {
    const alloc = std.testing.allocator;

    var io = try IO.init(32, 0);
    defer io.deinit();

    var client = hasync.Client.init(alloc, &io);
    defer client.deinit();

    var reqs: [10]hasync.Request = undefined;
    for (0..reqs.len) |i| {
        reqs[i] = client.create(try std.Uri.parse("https://up.tch.re"));
        try reqs[i].fetch();
    }

    for (0..reqs.len) |i| {
        try reqs[i].wait();
        reqs[i].deinit();
    }
}
