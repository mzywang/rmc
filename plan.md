# Username/password auth for the Zig backend (swappable design)

## Context

The app has no user concept yet — `/choices` votes are global/anonymous. This task builds a standalone username/password auth system (register/login/logout) as the identity foundation, isolated behind a swap boundary so a real auth system (OAuth/SSO) can replace the password mechanism later without touching other route handlers.

Confirmed with the user:
- Backend only (frontend UI is a separate follow-up).
- Not wired into `/choices` yet (separate follow-up).
- Session transport: opaque random bearer token, not JWT — trivially revocable, no signing dependency, fits the existing `Store` interface.
- Register does not auto-login; a separate `POST /login` call is required.
- Docs go into the existing `docs/endpoints.md` (not a new file), matching repo convention.

All signatures below are verified against the installed Zig 0.16.0 stdlib and vendored `httpz` source, not assumed.

## Design

Four new modules, following the existing convention of splitting logic out of `main.zig` (as `choices.zig` does):

- **`src/time.zig`** — extract `main.zig`'s existing `formatTimestamp` body verbatim as `pub fn currentTimestamp(allocator, io) ![]const u8`. Update `createCompany`/`createChoice` call sites. Pure refactor.
- **`src/token.zig`** — `pub fn generate(allocator, io: std.Io) ![]const u8`: 32 random bytes via `std.Io.random(io, &buf)`, base64 url-safe-no-pad encoded → 43-char opaque string. Used for both session tokens and user IDs.
- **`src/users.zig`** — `UserRecord{ user_id, username, password_hash, created_at }`, plus:
  - `hashPassword(allocator, password, io) ![]const u8` → `std.crypto.argon2.strHash(password, .{ .allocator = allocator, .params = .owasp_2id }, &buf, io)`, `buf: [128]u8` (confirmed sufficient per stdlib's own tests), result `allocator.dupe`'d.
  - `verifyPassword(hash, password, allocator, io) !bool` → wraps `std.crypto.argon2.strVerify`, treating `error.PasswordVerificationFailed`/`error.InvalidEncoding` as `false`.
  - Argon2id chosen over bcrypt: OWASP-recommended, memory-hard, in stdlib with a ready preset, and its `io`-threaded signature matches the codebase's existing plumbing (bcrypt's `strVerify` here lacks `io`).
- **`src/auth.zig`** — **the swap boundary**. Takes `store.Store` directly (not `*App`), matching `choices.zig`'s decoupled convention:
  ```zig
  pub const UserId = []const u8;
  const SessionRecord = struct { user_id: []const u8, created_at: []const u8 }; // private to this file

  pub fn createSession(sessions_store: store.Store, allocator, io: std.Io, user_id: UserId) ![]const u8
  pub fn destroySession(sessions_store: store.Store, session_token: []const u8) !void
  pub fn currentUser(sessions_store: store.Store, allocator, req: *httpz.Request) !?UserId
  ```
  `currentUser` reads `req.header("authorization")`, strips `"Bearer "`, looks the token up in `sessions_store`.

  Swappability: `SessionRecord` is private — callers only ever see opaque `UserId`/token strings. A future OAuth handler would call the same `createSession` after resolving identity by its own means; any future protected handler calls the same `currentUser`. Neither signature changes when the mechanism does. `user_id` is its own minted token, not derived from `username`, so a future OAuth user (no username) fits the same shape.

## Changes to `src/main.zig`

- `App` gains `users_store` and `sessions_store` (`store.Store`), opened via `store.open` and `defer`-closed, same as existing `choices_store`.
- New routes: `POST /register`, `POST /login`, `POST /logout`.
- New handlers follow the exact validation/JSON-response style of `createCompany`/`createChoice` (early-return 400 on bad body, `res.status` + `res.json(...)` per branch).

## Endpoint behavior

| | Success | 400 | 401 | 409 |
|---|---|---|---|---|
| `POST /register` | 201, `{user_id, username, created_at}` | empty/missing username or password | — | username already exists |
| `POST /login` | 200, `{token, user_id, username}` | empty/missing username or password | invalid username or password *(same message for unknown user and wrong password — avoids enumeration)* | — |
| `POST /logout` | 200, `{logged_out: true}` | — | missing/malformed `Authorization` header | — |

Key behavior notes:
- **Register**: hashes via `users.hashPassword`, mints `user_id` via `token.generate` (independent of username), stores keyed by `username` via `putIfAbsent` (409 on race/duplicate). Never returns `password_hash`. Does not create a session.
- **Login**: looks up `username`, verifies via `users.verifyPassword`. On success calls `auth.createSession` — each login mints a new independent token (multiple concurrent sessions per user are allowed, no single-session enforcement).
- **Logout**: strips `Bearer ` prefix, calls `auth.destroySession` → `sessions_store.delete`. Always returns 200 even for an unknown/already-invalidated token, since `MemoryStore.delete` no-ops silently on a missing key — this is deliberate (idempotent, and avoids leaking whether a token was ever valid).
- No endpoint added here requires auth to call — `auth.currentUser` is fully implemented but unused until the `/choices` follow-up wires it in.

## Stored record shapes

- `users_store`: key = `username`, value = JSON `UserRecord{ user_id, username, password_hash, created_at }`.
- `sessions_store`: key = opaque session token, value = JSON `{ user_id, created_at }` (private to `auth.zig`).

## Tests

New `tests/auth_test.sh`, same shape as `tests/companies_test.sh` (`tests/lib.sh` helpers, `subtest`/`assert_status`/`assert_body`, auto-picked up by `scripts/test_e2e.sh`). Cases: register success (no `password_hash`/plaintext leaked) and its 400/409 failures; login success and its 400/401 failures (unknown user + wrong password, same message); logout without header (401); full register → login → logout happy path with token extracted via `jq`.

## Docs

Append to `docs/endpoints.md`: an "Authentication" section plus `POST /register`/`POST /login`/`POST /logout` sections in the existing Request/Response/Example format, placed after `POST /companies`/`GET /companies` and before "Unmatched routes". Full drafted markdown, ready to paste in as-is:

---

## Authentication

Registering and logging in issue an opaque bearer token. Send it on subsequent requests as:

```
Authorization: Bearer <token>
```

As of this feature, no other endpoint requires authentication yet — `/choices` and `/companies` remain unauthenticated.

## `POST /register`

Creates a new user account with a username and password. The password is hashed before storage; it is never returned or logged.

**Request**

- Body: JSON object:
  - `username`
  - `password`

**Response**

- Status: `201 Created`
- Body: JSON object:
  - `user_id`
  - `username`
  - `created_at`

**Example**

```bash
curl -i -X POST -d '{"username":"alice","password":"correct horse battery staple"}' http://localhost:5882/register
```

```
HTTP/1.1 201 Created
content-type: application/json

{
  "user_id": "3f9a...",
  "username": "alice",
  "created_at": "2026-07-19T18:32:00Z"
}
```

If `username` or `password` is missing or empty:

- Status: `400 Bad Request`

```
HTTP/1.1 400 Bad Request
content-type: application/json

{
  "error": "username and password are required"
}
```

If `username` has already been registered:

- Status: `409 Conflict`

```
HTTP/1.1 409 Conflict
content-type: application/json

{
  "error": "username already exists"
}
```

Registering does not log you in — call `POST /login` afterward to obtain a session token.

## `POST /login`

Verifies a username and password, and if valid, issues a new session token.

**Request**

- Body: JSON object:
  - `username`
  - `password`

**Response**

- Status: `200 OK`
- Body: JSON object:
  - `token` — opaque bearer token; send as `Authorization: Bearer <token>` on subsequent requests
  - `user_id`
  - `username`

**Example**

```bash
curl -i -X POST -d '{"username":"alice","password":"correct horse battery staple"}' http://localhost:5882/login
```

```
HTTP/1.1 200 OK
content-type: application/json

{
  "token": "kP2m...",
  "user_id": "3f9a...",
  "username": "alice"
}
```

If `username` or `password` is missing or empty:

- Status: `400 Bad Request`

```
HTTP/1.1 400 Bad Request
content-type: application/json

{
  "error": "username and password are required"
}
```

If the username doesn't exist, or the password is incorrect:

- Status: `401 Unauthorized`

```
HTTP/1.1 401 Unauthorized
content-type: application/json

{
  "error": "invalid username or password"
}
```

Both failure cases return the same status and message, so a caller cannot distinguish "unknown username" from "wrong password."

## `POST /logout`

Invalidates a session token.

**Request**

- Header: `Authorization: Bearer <token>`
- No body required.

**Response**

- Status: `200 OK`
- Body: JSON object:
  - `logged_out` — always `true`

**Example**

```bash
curl -i -X POST -H "Authorization: Bearer kP2m..." http://localhost:5882/logout
```

```
HTTP/1.1 200 OK
content-type: application/json

{
  "logged_out": true
}
```

If the `Authorization` header is missing or not a `Bearer` token:

- Status: `401 Unauthorized`

```
HTTP/1.1 401 Unauthorized
content-type: application/json

{
  "error": "missing authorization header"
}
```

Logout is idempotent: calling it again with the same token, or with a token that was never valid, still returns `200 OK`.

---

## Commit order (docs → tests → implementation, per `scripts/check_commit_order.sh`)

1. **docs**: `docs/endpoints.md` additions only.
2. **tests**: `tests/auth_test.sh`.
3. **implementation (refactor)**: extract `src/time.zig`, update existing call sites.
4. **implementation (feature)**: add `src/token.zig`, `src/users.zig`, `src/auth.zig`; wire `App`/routes/handlers in `src/main.zig`.

## Verification

- `zig build && ./scripts/test_e2e.sh` — runs all `tests/*_test.sh` including `auth_test.sh`, same as CI.
- `zig build fmt` before each commit (pre-commit hook enforces `zig fmt --check` and rejects any newly-added `//` comment).
- Manual smoke test via `scripts/dev.sh` + curl: register, login, logout with the returned token, confirm re-logout still returns 200.
