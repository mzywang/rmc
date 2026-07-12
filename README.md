# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

## Requirements

- Zig 0.16.0

## Configuration

By default, the server reads `config.yaml` from the working directory:

```yaml
port: 5882
```

The config path is required to exist; the server fails to start if it's missing. Override the path with `--config`:

```bash
zig build run -- --config /etc/rmc/config.yaml
# or
./zig-out/bin/rmc --config=/etc/rmc/config.yaml
```

## Run locally

```bash
zig build run
```

```bash
curl http://localhost:5882/hello
```

## Test

```bash
zig build e2e
```

Builds the binary, runs it as a real subprocess, hits `/hello` over HTTP, and checks the response.
