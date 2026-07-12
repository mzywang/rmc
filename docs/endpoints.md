# Endpoints

## `GET /choices`

Returns the list of choices.

**Request**

No parameters, headers, or body required.

**Response**

- Status: `200 OK`

**Example**

```bash
curl -i http://localhost:5882/choices
```

```
HTTP/1.1 200 OK
content-type: application/json

[
  {
    "id": "...",
    "option_a": "...",
    "option_b": "..."
  }
]
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

## Unmatched routes

Any request to a path that isn't registered above returns `404 Not Found`.
