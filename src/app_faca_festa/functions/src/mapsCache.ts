import { createHash } from "node:crypto";

import { admin } from "./shared/firebaseAdmin";

function db() {
    return admin.firestore();
}

/** Cache de Geocoding / reverse: 30 dias. */
export const GEOCODE_CACHE_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/** Cache de rota delivery: 7 dias (trânsito muda, mas distância muda pouco). */
export const ROUTE_CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

function texto(value: unknown): string {
    return String(value ?? "").trim();
}

export function chaveCacheSha(partes: string[]): string {
    return createHash("sha256").update(partes.join("|").toLowerCase()).digest("hex");
}

export function chaveCep(cep: string): string {
    return `cep_${texto(cep).replace(/\D/g, "")}`;
}

export function chaveEndereco(parts: {
    logradouro?: string;
    numero?: string;
    bairro?: string;
    cidade?: string;
    uf?: string;
    cep?: string;
}): string {
    return `addr_${chaveCacheSha([
        texto(parts.logradouro),
        texto(parts.numero),
        texto(parts.bairro),
        texto(parts.cidade),
        texto(parts.uf).toUpperCase(),
        texto(parts.cep).replace(/\D/g, ""),
    ])}`;
}

/** Arredonda ~11 m para reaproveitar reverse geocode próximo. */
export function chaveReverse(lat: number, lng: number): string {
    return `rev_${lat.toFixed(4)}_${lng.toFixed(4)}`;
}

export function chaveRota(params: {
    cnpj: string;
    origemLat: number | null;
    origemLng: number | null;
    origemEndereco: string;
    destino: string;
    travelMode: string;
}): string {
    const origem =
        params.origemLat !== null && params.origemLng !== null
            ? `${params.origemLat.toFixed(5)},${params.origemLng.toFixed(5)}`
            : texto(params.origemEndereco).toLowerCase();
    return `rota_${chaveCacheSha([
        texto(params.cnpj),
        origem,
        texto(params.destino).toLowerCase(),
        texto(params.travelMode).toUpperCase(),
    ])}`;
}

export async function lerCacheMaps<T extends Record<string, unknown>>(
    docId: string,
): Promise<T | null> {
    try {
        const snap = await db().collection("_maps_cache").doc(docId).get();
        if (!snap.exists) return null;
        const data = snap.data() ?? {};
        const expiraEmMs = Number(data.expiraEmMs ?? 0);
        if (!Number.isFinite(expiraEmMs) || Date.now() > expiraEmMs) {
            return null;
        }
        const payload = data.payload;
        if (!payload || typeof payload !== "object") return null;
        return payload as T;
    } catch (error) {
        console.warn("[mapsCache] leitura falhou:", error);
        return null;
    }
}

export async function gravarCacheMaps(
    docId: string,
    payload: Record<string, unknown>,
    ttlMs: number,
    meta?: Record<string, unknown>,
): Promise<void> {
    try {
        await db().collection("_maps_cache").doc(docId).set(
            {
                payload,
                expiraEmMs: Date.now() + ttlMs,
                atualizadoEm: new Date(),
                ...(meta ?? {}),
            },
            { merge: true },
        );
    } catch (error) {
        console.warn("[mapsCache] gravação falhou:", error);
    }
}
