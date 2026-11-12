export interface Env {
  SYNC_TOKEN: string;
  GLASS_SYNC: DurableObjectNamespace;
}

type SyncRecord = {
  revision: number;
  ciphertext: string;
  updatedAt: string;
};

const MAX_BODY_BYTES = 512 * 1024;

function json(data: unknown, status = 200, headers: HeadersInit = {}): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...headers },
  });
}

function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return result === 0;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health" && request.method === "GET") {
      return json({ service: "GLASS Sync", status: "ok", apiVersion: 1 });
    }

    if (url.pathname !== "/v1/sync/state") return json({ error: "not_found" }, 404);
    if (!env.SYNC_TOKEN) return json({ error: "sync_not_configured" }, 503);

    const authorization = request.headers.get("authorization") ?? "";
    const suppliedToken = authorization.startsWith("Bearer ") ? authorization.slice(7) : "";
    if (!safeEqual(suppliedToken, env.SYNC_TOKEN)) return json({ error: "unauthorized" }, 401);

    const id = env.GLASS_SYNC.idFromName("primary-account");
    return env.GLASS_SYNC.get(id).fetch(request);
  },
};

export class GLASSSyncObject {
  private state: DurableObjectState;

  constructor(state: DurableObjectState) {
    this.state = state;
  }

  async fetch(request: Request): Promise<Response> {
    if (request.method === "GET") {
      const record = await this.state.storage.get<SyncRecord>("state");
      if (!record) return json({ revision: 0, ciphertext: null, updatedAt: null }, 200, { etag: '"0"' });
      return json(record, 200, { etag: `"${record.revision}"` });
    }

    if (request.method !== "PUT") {
      return json({ error: "method_not_allowed" }, 405, { allow: "GET, PUT" });
    }

    const contentLength = Number(request.headers.get("content-length") ?? 0);
    if (contentLength > MAX_BODY_BYTES) return json({ error: "payload_too_large" }, 413);

    const ifMatch = request.headers.get("if-match");
    if (!ifMatch || !/^"\d+"$/.test(ifMatch)) return json({ error: "if_match_required" }, 428);

    let body: { ciphertext?: unknown };
    try {
      const raw = await request.text();
      if (new TextEncoder().encode(raw).byteLength > MAX_BODY_BYTES) return json({ error: "payload_too_large" }, 413);
      body = JSON.parse(raw);
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    if (typeof body.ciphertext !== "string" || body.ciphertext.length < 16) {
      return json({ error: "invalid_ciphertext" }, 400);
    }

    const current = await this.state.storage.get<SyncRecord>("state");
    const currentRevision = current?.revision ?? 0;
    const expectedRevision = Number(ifMatch.slice(1, -1));
    if (expectedRevision !== currentRevision) {
      return json({ error: "revision_conflict", revision: currentRevision }, 409, { etag: `"${currentRevision}"` });
    }

    const next: SyncRecord = {
      revision: currentRevision + 1,
      ciphertext: body.ciphertext,
      updatedAt: new Date().toISOString(),
    };
    await this.state.storage.put("state", next);
    return json(next, 200, { etag: `"${next.revision}"` });
  }
}
