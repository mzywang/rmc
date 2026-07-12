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

## Unmatched routes

Any request to a path that isn't registered above returns `404 Not Found`.
