# Endpoints

## `GET /choices`

Looks at all recorded companies and applies a function to the full set to produce a list of choices. The current function generates every possible pair of two companies.

Results are cursor-paginated: only the requested page is generated, not the full list.

**Request**

- Query parameters (all optional):
  - `cursor` — opaque position to resume from; omit to start from the beginning
  - `limit` — maximum number of choices to return in this page

**Response**

- Status: `200 OK`
- Body: JSON object:
  - `choices` — page of choices, each with `id`, `option_a`, `option_b`
  - `next_cursor` — cursor for the next page, or `null` if this is the last page

**Example**

```bash
curl -i "http://localhost:5882/choices?limit=1"
```

```
HTTP/1.1 200 OK
content-type: application/json

{
  "choices": [
    {
      "id": "acme:globex",
      "option_a": "acme",
      "option_b": "globex"
    }
  ],
  "next_cursor": 1
}
```

Fetch the next page by passing the returned `next_cursor` back in:

```bash
curl -i "http://localhost:5882/choices?limit=1&cursor=1"
```

## `POST /choices`

Records a selection for a choice previously returned by `GET /choices`. Every submission is recorded independently — posting the same `id` again does not overwrite or reject the earlier one.

**Request**

- Body: JSON object:
  - `id` — a choice id, e.g. `"acme:globex"`
  - `selection` — must be exactly `"option_a"` or `"option_b"`

**Response**

- Status: `201 Created`
- Body: JSON object:
  - `id`
  - `selection`
  - `company_id` — the company_id `selection` resolved to
  - `created_at`

**Example**

```bash
curl -i -X POST -d '{"id":"acme:globex","selection":"option_a"}' http://localhost:5882/choices
```

```
HTTP/1.1 201 Created
content-type: application/json

{
  "id": "acme:globex",
  "selection": "option_a",
  "company_id": "acme",
  "created_at": "2026-07-12T18:32:00Z"
}
```

If `selection` isn't exactly `"option_a"` or `"option_b"`:

- Status: `400 Bad Request`

```
HTTP/1.1 400 Bad Request
content-type: application/json

{
  "error": "selection must be option_a or option_b"
}
```

If `id` doesn't resolve to two recorded companies (malformed, or referencing a company that doesn't exist):

- Status: `404 Not Found`

```
HTTP/1.1 404 Not Found
content-type: application/json

{
  "error": "id does not reference two existing companies"
}
```

## `POST /companies`

Records a company submission, storing the given `company_id` alongside a server-assigned creation timestamp.

**Request**

- Body: JSON object:
  - `company_id`

**Response**

- Status: `201 Created`
- Body: JSON object:
  - `company_id`
  - `created_at`

**Example**

```bash
curl -i -X POST -d '{"company_id":"acme"}' http://localhost:5882/companies
```

```
HTTP/1.1 201 Created
content-type: application/json

{
  "company_id": "acme",
  "created_at": "2026-07-12T18:32:00Z"
}
```

If `company_id` has already been recorded, the request is rejected rather than overwriting or duplicating the existing record:

- Status: `409 Conflict`

```
HTTP/1.1 409 Conflict
content-type: application/json

{
  "error": "company_id already exists"
}
```

## `GET /companies`

Returns the list of recorded companies.

**Request**

No parameters, headers, or body required.

**Response**

- Status: `200 OK`

**Example**

```bash
curl -i http://localhost:5882/companies
```

```
HTTP/1.1 200 OK
content-type: application/json

[
  {
    "company_id": "acme",
    "created_at": "2026-07-12T18:32:00Z"
  }
]
```

## Unmatched routes

Any request to a path that isn't registered above returns `404 Not Found`.
