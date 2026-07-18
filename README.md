# rmc

A minimal HTTP server written in Zig using [http.zig](https://github.com/karlseguin/http.zig), with a [SvelteKit](https://svelte.dev/docs/kit) frontend in [`web/`](web).

See [`docs/endpoints.md`](docs/endpoints.md) for the list of HTTP endpoints this service serves.

## Configuration

By default, the server reads `config.yaml` from the working directory:

```yaml
port: 5882
debug: true
```

- `port` is required; the server fails to start if it or the config file itself is missing.
- `debug` is optional (defaults to `false`). When `true`, the server logs every handled request (method, path, status). The default `config.yaml` used for local development has it on.

## Local Development (Backend)

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

## Local Development (Frontend)

The frontend lives in [`web/`](web) — a [SvelteKit](https://svelte.dev/docs/kit) app (TypeScript, Tailwind CSS, Vitest).

### Setup

Requires Node >= 20. Install pnpm via Corepack (bundled with Node):

```bash
corepack enable
```

Corepack reads the exact pnpm version to use from `web/package.json`'s `packageManager` field — keep that field in place. Without a pin, Corepack's own "latest" pnpm resolution currently hits an unrelated upstream bug ([nodejs/corepack#342](https://github.com/nodejs/corepack/issues/342)).

Then install dependencies:

```bash
cd web && pnpm install
```

### Test

```bash
cd web && pnpm run test
```

### Typecheck & lint

```bash
cd web && pnpm run check
cd web && pnpm run lint
```

### Run

```bash
cd web && pnpm run dev --open
```

### Build

```bash
cd web && pnpm run build
```

## CI

Checks run on every PR:

- **fmt** (`.github/workflows/fmt.yml`) — `zig fmt --check` on `build.zig`, `build.zig.zon`, and `src/`.
- **e2e** (`.github/workflows/e2e.yml`) — runs `zig build && ./scripts/test_e2e.sh` natively on the runner, the same way it's run locally.
- **commit-order** (`.github/workflows/commit-order.yml`) — requires each PR's commits to progress documentation → tests → implementation, without an earlier stage appearing after a later one. Bypass it for a PR that doesn't fit the pattern by applying the `skip-commit-order` label.
- **web** (`.github/workflows/web.yml`) — only runs when `web/` changes; runs lint, typecheck, test, and build for the frontend, the same way they're run locally.

One more check runs after a merge to `main`:

- **docker-e2e** (`.github/workflows/docker-e2e.yml`) — builds and runs the Docker `test` target below, to catch packaging issues the native `e2e` check can't see.

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

