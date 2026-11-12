# GLASS Sync Worker

A small Cloudflare Worker + Durable Object for one private GLASS sync account.

## Security model

- Every sync request requires `Authorization: Bearer <SYNC_TOKEN>`.
- The Worker stores only an opaque client-encrypted `ciphertext`; it never receives plaintext bookmarks, settings, history, or tabs.
- Durable Object storage serializes writes and enforces optimistic concurrency through `If-Match` / ETags.
- Maximum request body: 512 KiB.
- There is no public account discovery, user directory, or unauthenticated sync endpoint.

The iOS/Android/Windows clients must encrypt and decrypt the payload locally before this service is enabled. Never upload plaintext browser data.

## Deploy

1. Install Wrangler and authenticate with Cloudflare.
2. From this directory run `npx wrangler secret put SYNC_TOKEN` and enter a long random token. Do not commit the token.
3. Run `npx wrangler deploy`.
4. Save the deployed Worker URL in the native client configuration.

The Durable Object SQLite migration is declared in `wrangler.toml`. Cloudflare creates the namespace as part of deployment.

## API

- `GET /health` returns service status.
- `GET /v1/sync/state` returns `{ revision, ciphertext, updatedAt }` and an ETag. An empty account returns revision 0 and null ciphertext.
- `PUT /v1/sync/state` requires JSON `{ "ciphertext": "..." }` and an `If-Match: "<revision>"` header. A stale revision returns HTTP 409; clients must fetch and resolve rather than silently overwrite.

The ciphertext format and client-side key exchange are deliberately not guessed here. All devices must use the same documented encryption envelope and key before sync is switched on.
