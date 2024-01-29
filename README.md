# zig-async-http

Attempt to adapt the [Zig standard HTTP
client](https://ziglang.org/documentation/master/std/#A;std:http.Client) to use
the [Tigerbeetle non-blocking
I/O](https://tigerbeetle.com/blog/a-friendly-abstraction-over-iouring-and-kqueue/).

The idea is to change the standard client the little as possible and keep the
existing API.

You can see the diff in the commit
[8fb43df](https://github.com/krichprollsch/zig-async-http/commit/8fb43df580b33888916d9361e6325b06969b22be).

## How to test it?

Tested w/ Zig version 0.12.0-dev.1773+8a8fd47d2

```
zig test test.zig
```
