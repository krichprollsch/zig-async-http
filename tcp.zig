const std = @import("std");
const net = std.net;
const Stream = @import("stream.zig").Stream;
const IO = @import("tigerbeetle-io/io.zig").IO;

const ConnectCmd = struct {
    const Self = @This();

    io: *IO,
    socket: std.os.socket_t,
    completion: *IO.Completion,
    done: bool = false,
    res: IO.ConnectError!void = undefined,

    fn run(self: *Self, addr: std.net.Address) !void {
        self.io.connect(*Self, self, callback, self.completion, self.socket, addr);
    }

    fn callback(self: *Self, _: *IO.Completion, result: IO.ConnectError!void) void {
        self.res = result;
        defer self.done = true;
    }

    fn wait(self: *Self) !void {
        while (!self.done) try self.io.tick();
        return self.res;
    }
};

pub fn tcpConnectToHost(alloc: std.mem.Allocator, io: *IO, name: []const u8, port: u16) !Stream {
    // TODO async resolve
    const list = try net.getAddressList(alloc, name, port);
    defer list.deinit();

    if (list.addrs.len == 0) return error.UnknownHostName;

    for (list.addrs) |addr| {
        return tcpConnectToAddress(io, addr) catch |err| switch (err) {
            error.ConnectionRefused => {
                continue;
            },
            else => return err,
        };
    }
    return std.os.ConnectError.ConnectionRefused;
}

pub fn tcpConnectToAddress(io: *IO, addr: net.Address) !Stream {
    const sockfd = try io.open_socket(addr.any.family, std.os.SOCK.STREAM, std.os.IPPROTO.TCP);
    errdefer std.os.closeSocket(sockfd);

    var completion: IO.Completion = undefined;
    var cmd = ConnectCmd{
        .io = io,
        .socket = sockfd,
        .completion = &completion,
    };
    try cmd.run(addr);
    try cmd.wait();

    return Stream{
        .io = io,
        .handle = sockfd,
    };
}
