# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

## Requirements

- Zig 0.16.0

## Run locally

```bash
zig build run
```

The server listens on `http://localhost:5882`.

```bash
curl http://localhost:5882/hello
```

## Test

```bash
zig build test
```
