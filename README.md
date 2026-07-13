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

## Local development

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
curl http://localhost:5882/hello
```

Override the config path with `--config`:

```bash
zig build run -- --config /etc/rmc/config.yaml
```

### Pre-commit hook

```bash
zig build fmt
```

## Docker

### Requirements

Two build targets, sharing one `builder` stage. `docker build` fails if a dependency below is missing, so these lists don't drift from what's really needed.

`test`:

- Zig 0.16.0
- `jq` (used by `tests/companies_test.sh`)
- `git` (required by `build.zig`'s `install` step)
- `curl` (used by `tests/*.sh`)

`runtime`:

- none — just the compiled binary and `config.yaml`, nothing else.

Both require `--target` explicitly; neither is a default.

Run the same test loop as [Test](#test) — this is also what CI runs, so it's a good pre-push check that doesn't depend on what's installed locally:

```bash
docker build --target test -t rmc:test .
docker run --rm rmc:test
```

Or run the server itself:

```bash
docker build --target runtime -t rmc:runtime .
docker run --rm -p 5882:5882 rmc:runtime
```

then `curl http://localhost:5882/choices` from the host.

