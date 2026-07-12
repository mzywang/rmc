# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

## Requirements

- Zig 0.16.0

## Configuration

By default, the server reads `config.yaml` from the working directory:

```yaml
port: 5882
debug: true
```

- `port` is required; the server fails to start if it or the config file itself is missing.
- `debug` is optional (defaults to `false`). When `true`, the server logs every handled request (method, path, status). The default `config.yaml` used for local development has it on.

Override the config path with `--config`:

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
