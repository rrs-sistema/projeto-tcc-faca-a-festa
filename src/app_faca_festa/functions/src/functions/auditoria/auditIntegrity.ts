import { createHash } from "crypto";

const IGNORED_HASH_FIELDS = new Set([
  "criado_em",
  "hash_integridade",
]);

function normalize(value: unknown): unknown {
  if (value === undefined) return null;
  if (value === null || typeof value === "string" ||
    typeof value === "number" || typeof value === "boolean") {
    return value;
  }
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(normalize);
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>)
      .filter(([key, item]) => !IGNORED_HASH_FIELDS.has(key) && item !== undefined)
      .sort(([left], [right]) => left.localeCompare(right));

    const normalized: Record<string, unknown> = {};
    for (const [key, item] of entries) {
      normalized[key] = normalize(item);
    }
    return normalized;
  }
  return String(value);
}

export function calcularHashIntegridadeAuditoria(
  payload: Record<string, unknown>,
): string {
  const canonical = JSON.stringify(normalize(payload));
  return createHash("sha256").update(canonical).digest("hex");
}
