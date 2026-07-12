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

Builds the binary, runs it as a real subprocess, then runs every test case in `scripts/e2e/` against it over real HTTP, reporting pass/fail per case.

To add a test case, drop a new executable `*_test.sh` script in `scripts/e2e/` (see `hello_test.sh` for an example). It runs with `$PORT` set to the server's port and can use the assertion helpers in `scripts/e2e/lib.sh`. To remove one, delete the file.
