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

This blocks the terminal. In a separate terminal:

```bash
curl http://localhost:5882/hello
```

## Test

```bash
zig build e2e
```

Builds the binary, runs it as a real subprocess against `tests/config.yaml` (debug logging off by default, independent of the root `config.yaml` used for local development), then runs every test case in `tests/` against it over real HTTP, reporting pass/fail per case.

To add a test case, drop a new executable `*_test.sh` script in `tests/` (see `server_test.sh` for an example). It runs with `$PORT` set to the server's port and can use the assertion helpers in `tests/lib.sh`. To remove one, delete the file.

## Formatting

CI checks `zig fmt --check` on every PR. Running `zig build` (in any form — `run`, `e2e`, or plain) automatically enables the repo's git hooks (`git config core.hooksPath .githooks`), which blocks commits that would fail the formatting check.
