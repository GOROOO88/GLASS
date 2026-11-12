# GLASS Sync Protocol v1

## Data protection

- Payload encryption: AES-256-GCM on the client using CryptoKit on Apple platforms and equivalent AES-GCM implementations on Android/Windows.
- The 256-bit encryption key is generated with the platform cryptographic random generator and stored in the iOS Keychain with device-only accessibility.
- Envelope: `glass.aesgcm.v1.<base64(combined nonce+ciphertext+tag)>`.
- Additional authenticated data: UTF-8 bytes of `com.gorooo.glass.sync.payload.v1`.
- JSON is encoded as UTF-8. Dates use ISO-8601. Unknown schema versions must be rejected, not guessed.
- The server stores the opaque envelope only. Cookies, passwords, website data stores, and private tabs are never part of the sync snapshot.

## Snapshot schema

Version 1 contains bookmarks, browsing history, spaces, regular tab IDs/URLs, active regular tab/space, and browser settings. Downloaded file bytes and private browsing tabs are excluded. Download metadata is local because file paths are device-specific.

## Device pairing

Each device must use the same 32-byte account encryption key. iOS currently stores it in Keychain as a device-only item and provides internal export/import primitives for a future local QR pairing flow. The pairing code is a secret and must never be logged, pasted into support chats, or sent to the sync server.

The current iOS key is device-local until pairing is completed. Do not enable network sync with mismatched device keys.

## Conflict handling

The Worker uses monotonically increasing revisions and ETags. A client must fetch the latest revision before writing. HTTP 409 means another device wrote first; the client must fetch, compare, and resolve before retrying. Never use last-write-wins for the entire browser snapshot without warning.

## Production gate

The current Worker bearer token is a server-side bootstrap/testing secret and must never be embedded in client binaries. Production sync requires account/device pairing and revocable per-device credentials before any app connects to the Worker.
