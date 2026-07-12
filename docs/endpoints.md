# Endpoints

## `GET /hello`

Returns a static greeting.

**Request**

No parameters, headers, or body required.

**Response**

- Status: `200 OK`
- Body: `Hello, world!`

**Example**

```bash
curl http://localhost:5882/hello
```

## Unmatched routes

Any request to a path that isn't registered above returns `404 Not Found`.
