# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

## Requirements

- Zig 0.16.0

## Configuration

The server reads `config.yaml` from the working directory:

```yaml
port: 5882
```

`config.yaml` is required; the server fails to start if it's missing.

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
