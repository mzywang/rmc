# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

## Requirements

- Zig 0.16.0

## Configuration

The server reads `config.yaml` from the working directory:

```yaml
port: 5882
```

If `config.yaml` is missing, it defaults to port `5882`.

## Run locally

```bash
zig build run
```

```bash
curl http://localhost:5882/hello
```

## Test

```bash
zig build test
```
