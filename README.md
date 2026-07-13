# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

See [`docs/endpoints.md`](docs/endpoints.md) for the list of HTTP endpoints this service serves.

## Requirements

- Zig 0.16.0
- `jq` (used by `tests/companies_test.sh`)

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
zig build && ./scripts/test_e2e.sh
```

To add a test case, drop a new executable `*_test.sh` script in `tests/` (see `choices_test.sh` for an example). It runs with `$PORT` set to the server's port and can use the assertion helpers in `tests/lib.sh`. To remove one, delete the file.

## Formatting

```bash
zig build fmt
```

## Docker

```bash
docker build -t rmc .
```

Builds an image with this project's actual toolchain (Zig 0.16.0, `jq`, `git`, `curl`) installed, so the [Requirements](#requirements) list above doesn't drift from what's really needed — `docker build` fails if a dependency listed there is missing from the image.

Run the same test loop as [Test](#test):

```bash
docker run --rm rmc ./scripts/test_e2e.sh
```

Or run the server itself:

```bash
docker run --rm -p 5882:5882 rmc ./zig-out/bin/rmc
```

then `curl http://localhost:5882/choices` from the host.

