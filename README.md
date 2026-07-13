# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig).

See [`docs/endpoints.md`](docs/endpoints.md) for the list of HTTP endpoints this service serves.

## Configuration

By default, the server reads `config.yaml` from the working directory:

```yaml
port: 5882
debug: true
```

- `port` is required; the server fails to start if it or the config file itself is missing.
- `debug` is optional (defaults to `false`). When `true`, the server logs every handled request (method, path, status). The default `config.yaml` used for local development has it on.

## Local Development

### Test

```bash
zig build && ./scripts/test_e2e.sh
```

### Run

```bash
zig build run
```

This blocks the terminal. In a separate terminal:

```bash
curl http://localhost:5882/choices
```

Override the config path with `--config`:

```bash
zig build run -- --config /etc/rmc/config.yaml
```

### Pre-commit hook

```bash
zig build fmt
```

## CI

Two checks run on every PR:

- **fmt** (`.github/workflows/fmt.yml`) — `zig fmt --check` on `build.zig`, `build.zig.zon`, and `src/`.
- **e2e** (`.github/workflows/e2e.yml`) — builds and runs the Docker `test` target below.

### Docker

#### Requirements

Two build targets, sharing one `builder` stage. `docker build` fails if a dependency below is missing, so this list doesn't drift from what's really needed.

`builder`:

- Zig 0.16.0
- `jq`
- `git`
- `curl`

#### Test

```bash
docker build --target test -t rmc:test .
docker run --rm rmc:test
```

#### Run

```bash
docker build --target runtime -t rmc:runtime .
docker run --rm -p 5882:5882 rmc:runtime
```

This blocks the terminal. In a separate terminal:

```bash
curl http://localhost:5882/choices
```

