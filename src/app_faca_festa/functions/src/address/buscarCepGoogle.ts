import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import { createHash } from "node:crypto";

import { admin } from "../shared/firebaseAdmin";
import {
    GEOCODE_CACHE_TTL_MS,
    chaveCep,
    chaveEndereco,
    chaveReverse,
    gravarCacheMaps,
    lerCacheMaps,
} from "./../mapsCache";

function db() {
    return admin.firestore();
}

const googleMapsApiKey = defineSecret("GOOGLE_MAPS_API_KEY");

type AddressComponent = {
    long_name?: string;
    short_name?: string;
    types?: string[];
};

type GeocodeResult = {
    address_components?: AddressComponent[];
    formatted_address?: string;
    geometry?: {
        location?: {
            lat?: number;
            lng?: number;
        };
    };
};

type EnderecoResolvido = {
    logradouro: string;
    bairro: string;
    cidade: string;
    uf: string;
    latitude: number | null;
    longitude: number | null;
    formatado: string;
    origemCalculo: string;
};

function texto(value: unknown): string {
    return String(value ?? "").trim();
}

function somenteDigitos(value: unknown): string {
    return texto(value).replace(/\D/g, "");
}

function componente(
    components: AddressComponent[],
    tipos: string[],
    preferShort = false,
): string {
    for (const tipo of tipos) {
        const item = components.find((c) => (c.types ?? []).includes(tipo));
        if (!item) continue;
        const valor = preferShort
            ? texto(item.short_name) || texto(item.long_name)
            : texto(item.long_name) || texto(item.short_name);
        if (valor) return valor;
    }
    return "";
}

function montarEnderecoTexto(parts: {
    logradouro?: string;
    bairro?: string;
    cidade?: string;
    uf?: string;
    cep?: string;
}): string {
    const cep = somenteDigitos(parts.cep);
    const cepFmt = cep.length === 8 ? `${cep.slice(0, 5)}-${cep.slice(5)}` : texto(parts.cep);
    return [
        texto(parts.logradouro),
        texto(parts.bairro),
        texto(parts.cidade),
        texto(parts.uf),
        cepFmt,
        "Brasil",
    ]
        .filter((item) => item.length > 0)
        .join(", ");
}

async function validarLimite(ip: string, cep: string): Promise<boolean> {
    const chave = createHash("sha256").update(`${ip}|${cep}`).digest("hex");
    const ref = db().collection("_cep_lookup_limits").doc(chave);
    const agora = Date.now();
    const janelaMs = 10 * 60 * 1000;
    const maximo = 60;

    return db().runTransaction(async (transaction: any) => {
        const snap = await transaction.get(ref);
        const data = snap.data() ?? {};
        const inicio = Number(data.inicioMs ?? agora);
        const contagem = Number(data.contagem ?? 0);

        if (agora - inicio > janelaMs) {
            transaction.set(ref, {
                inicioMs: agora,
                contagem: 1,
                atualizadoEm: new Date(),
            });
            return true;
        }

        if (contagem >= maximo) return false;

        transaction.set(
            ref,
            {
                inicioMs: inicio,
                contagem: contagem + 1,
                atualizadoEm: new Date(),
            },
            { merge: true },
        );
        return true;
    });
}

type EnderecoResolvidoComCep = EnderecoResolvido & {
    cep: string;
    numero: string;
};

function parseGeocodeResult(
    result: GeocodeResult,
    origemCalculo: string,
): EnderecoResolvidoComCep | null {
    const components = result.address_components ?? [];

    const logradouro = componente(components, ["route", "street_address"]);
    const numero = componente(components, ["street_number"]);
    const bairro = componente(components, [
        "sublocality_level_1",
        "sublocality",
        "neighborhood",
        "political",
    ]);
    const cidade = componente(components, [
        "administrative_area_level_2",
        "locality",
    ]);
    const uf = componente(components, ["administrative_area_level_1"], true);
    const cep = somenteDigitos(componente(components, ["postal_code"]));

    const latitude = result.geometry?.location?.lat ?? null;
    const longitude = result.geometry?.location?.lng ?? null;

    if (!cidade && !uf && latitude == null && longitude == null) {
        return null;
    }

    return {
        cep: cep.length === 8 ? cep : "",
        logradouro,
        numero,
        bairro,
        cidade,
        uf,
        latitude: typeof latitude === "number" ? latitude : null,
        longitude: typeof longitude === "number" ? longitude : null,
        formatado: texto(result.formatted_address),
        origemCalculo,
    };
}

async function geocodeGoogle(
    apiKey: string,
    queries: URLSearchParams[],
    origemCalculo: string,
): Promise<EnderecoResolvidoComCep | null> {
    for (const params of queries) {
        const response = await fetch(
            `https://maps.googleapis.com/maps/api/geocode/json?${params.toString()}`,
        );

        if (!response.ok) {
            const body = await response.text();
            console.warn("[buscarCepGoogle] HTTP", response.status, body);
            continue;
        }

        const data = (await response.json()) as {
            status?: string;
            error_message?: string;
            results?: GeocodeResult[];
        };

        if (data.status !== "OK" || !data.results?.length) {
            console.warn(
                "[buscarCepGoogle] status:",
                data.status,
                data.error_message ?? "",
            );
            continue;
        }

        const parsed = parseGeocodeResult(data.results[0], origemCalculo);
        if (parsed) return parsed;
    }

    return null;
}

async function buscarViaCep(cep: string): Promise<{
    logradouro: string;
    bairro: string;
    cidade: string;
    uf: string;
} | null> {
    try {
        const response = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
        if (!response.ok) return null;
        const data = (await response.json()) as Record<string, unknown>;
        if (data.erro === true) return null;

        return {
            logradouro: texto(data.logradouro),
            bairro: texto(data.bairro),
            cidade: texto(data.localidade),
            uf: texto(data.uf),
        };
    } catch (error) {
        console.warn("[buscarCepGoogle] ViaCEP falhou:", error);
        return null;
    }
}

async function buscarViaCepPorLogradouro(params: {
    uf: string;
    cidade: string;
    logradouro: string;
    bairro?: string;
}): Promise<{
    cep: string;
    logradouro: string;
    bairro: string;
    cidade: string;
    uf: string;
} | null> {
    const uf = texto(params.uf).toUpperCase();
    const cidade = texto(params.cidade);
    const logradouro = texto(params.logradouro)
        .replace(/[\s,.-]+\d+\s*$/, "")
        .trim();
    const bairroAlvo = texto(params.bairro).toLowerCase();

    if (uf.length !== 2 || cidade.length < 2 || logradouro.length < 3) {
        return null;
    }

    try {
        const url =
            `https://viacep.com.br/ws/${encodeURIComponent(uf)}/` +
            `${encodeURIComponent(cidade)}/${encodeURIComponent(logradouro)}/json/`;
        const response = await fetch(url);
        if (!response.ok) return null;

        const raw = (await response.json()) as unknown;
        const itens = Array.isArray(raw)
            ? raw.filter((item): item is Record<string, unknown> => !!item && typeof item === "object")
            : raw && typeof raw === "object" && (raw as Record<string, unknown>).erro !== true
                ? [raw as Record<string, unknown>]
                : [];

        if (!itens.length) return null;

        itens.sort((a, b) => {
            const aBairro = texto(a.bairro).toLowerCase();
            const bBairro = texto(b.bairro).toLowerCase();
            const aScore =
                (bairroAlvo && (aBairro.includes(bairroAlvo) || bairroAlvo.includes(aBairro)) ? 0 : 1) +
                (texto(a.logradouro).toLowerCase().includes(logradouro.toLowerCase()) ? 0 : 1);
            const bScore =
                (bairroAlvo && (bBairro.includes(bairroAlvo) || bairroAlvo.includes(bBairro)) ? 0 : 1) +
                (texto(b.logradouro).toLowerCase().includes(logradouro.toLowerCase()) ? 0 : 1);
            return aScore - bScore;
        });

        const melhor = itens[0];
        const cep = somenteDigitos(melhor.cep);
        if (cep.length !== 8) return null;

        return {
            cep,
            logradouro: texto(melhor.logradouro) || logradouro,
            bairro: texto(melhor.bairro),
            cidade: texto(melhor.localidade) || cidade,
            uf: texto(melhor.uf).toUpperCase() || uf,
        };
    } catch (error) {
        console.warn("[buscarCepGoogle] ViaCEP logradouro falhou:", error);
        return null;
    }
}

async function reverseNominatim(
    latitude: number,
    longitude: number,
): Promise<EnderecoResolvidoComCep | null> {
    try {
        const params = new URLSearchParams({
            lat: String(latitude),
            lon: String(longitude),
            format: "json",
            addressdetails: "1",
            zoom: "18",
        });
        const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?${params.toString()}`,
            {
                headers: {
                    "User-Agent": "FacaAFesta/1.0 (consulta-cep)",
                    "Accept-Language": "pt-BR",
                },
            },
        );
        if (!response.ok) return null;

        const data = (await response.json()) as {
            address?: Record<string, unknown>;
            lat?: string;
            lon?: string;
        };
        const address = data.address ?? {};
        const cep = somenteDigitos(address.postcode);
        const logradouro = texto(address.road || address.pedestrian);
        const numero = texto(address.house_number);
        const bairro = texto(
            address.suburb || address.neighbourhood || address.city_district,
        );
        const cidade = texto(
            address.city || address.town || address.municipality || address.county,
        );
        const ufRaw = texto(
            address["ISO3166-2-lvl4"] || address.state_code || address.state,
        );
        const ufMatch = ufRaw.match(/(?:BR[-\s]?)?([A-Za-z]{2})$/i);
        const uf = (ufMatch?.[1] ?? ufRaw).toUpperCase();
        const ufFinal = uf.length === 2 && uf !== "BR" ? uf : "";

        if (!logradouro && !cidade) return null;

        return {
            cep: cep.length === 8 ? cep : "",
            logradouro,
            numero,
            bairro,
            cidade,
            uf: ufFinal,
            latitude,
            longitude,
            formatado: montarEnderecoTexto({
                logradouro: [logradouro, numero].filter(Boolean).join(", "),
                bairro,
                cidade,
                uf: ufFinal,
                cep,
            }),
            origemCalculo: "NOMINATIM_REVERSE",
        };
    } catch (error) {
        console.warn("[buscarCepGoogle] Nominatim reverse falhou:", error);
        return null;
    }
}

async function enriquecerCepViaLogradouro(
    base: EnderecoResolvidoComCep,
): Promise<EnderecoResolvidoComCep> {
    if (base.logradouro.length < 3 || base.cidade.length < 2 || base.uf.length !== 2) {
        return base;
    }

    const viaCep = await buscarViaCepPorLogradouro({
        uf: base.uf,
        cidade: base.cidade,
        logradouro: base.logradouro,
        bairro: base.bairro,
    });
    if (!viaCep) return base;

    const cepBase = somenteDigitos(base.cep);
    const cepMudou = viaCep.cep !== cepBase;

    return {
        ...base,
        // ViaCEP é a fonte oficial de CEP no Brasil; corrige postcode do OSM/Google.
        cep: viaCep.cep,
        logradouro: base.logradouro || viaCep.logradouro,
        bairro: base.bairro || viaCep.bairro,
        cidade: base.cidade || viaCep.cidade,
        uf: base.uf || viaCep.uf,
        origemCalculo: cepMudou || cepBase.length !== 8
            ? base.origemCalculo.includes("GOOGLE")
                ? "GOOGLE_REVERSE_VIACEP"
                : "NOMINATIM_REVERSE_VIACEP"
            : base.origemCalculo,
    };
}

async function resolverPorCoordenadas(
    apiKey: string,
    latitude: number,
    longitude: number,
): Promise<EnderecoResolvidoComCep | null> {
    const cacheKey = chaveReverse(latitude, longitude);
    const cached = await lerCacheMaps<EnderecoResolvidoComCep>(cacheKey);
    if (cached?.cidade || cached?.logradouro || cached?.latitude != null) {
        return {
            ...cached,
            origemCalculo: `${texto(cached.origemCalculo) || "CACHE"}_HIT`,
        };
    }

    const latlng = `${latitude},${longitude}`;
    // Uma query principal; evita 2–3 cobranças Google por reverse.
    let resultado = await geocodeGoogle(
        apiKey,
        [
            new URLSearchParams({
                latlng,
                language: "pt-BR",
                region: "br",
                key: apiKey,
            }),
        ],
        "GOOGLE_REVERSE_GEOCODING",
    );

    if (!resultado) {
        console.warn(
            "[buscarCepGoogle] Google reverse sem resultado. Tentando Nominatim...",
            latlng,
        );
        resultado = await reverseNominatim(latitude, longitude);
    }

    if (!resultado) return null;

    const enriquecido = await enriquecerCepViaLogradouro({
        ...resultado,
        latitude,
        longitude,
    });
    await gravarCacheMaps(cacheKey, enriquecido, GEOCODE_CACHE_TTL_MS, {
        tipo: "reverse",
    });
    return enriquecido;
}

async function resolverPorEndereco(
    apiKey: string,
    endereco: {
        logradouro?: string;
        numero?: string;
        bairro?: string;
        cidade?: string;
        uf?: string;
        cep?: string;
    },
): Promise<EnderecoResolvidoComCep | null> {
    const base = {
        logradouro: texto(endereco.logradouro),
        numero: texto(endereco.numero),
        bairro: texto(endereco.bairro),
        cidade: texto(endereco.cidade),
        uf: texto(endereco.uf).toUpperCase(),
        cep: somenteDigitos(endereco.cep),
    };

    const cacheKey = chaveEndereco(base);
    const cached = await lerCacheMaps<EnderecoResolvidoComCep>(cacheKey);
    if (cached?.cidade || cached?.latitude != null) {
        return {
            ...cached,
            origemCalculo: `${texto(cached.origemCalculo) || "CACHE"}_HIT`,
        };
    }

    const linhaRua = [base.logradouro, base.numero].filter(Boolean).join(", ");
    const enderecoTexto = montarEnderecoTexto({
        logradouro: linhaRua || base.logradouro,
        bairro: base.bairro,
        cidade: base.cidade,
        uf: base.uf,
        cep: base.cep,
    });

    if (enderecoTexto.replace(/Brasil|,|\s/g, "").length < 8) {
        return null;
    }

    const queries: URLSearchParams[] = [
        new URLSearchParams({
            address: enderecoTexto,
            components: "country:BR",
            language: "pt-BR",
            region: "br",
            key: apiKey,
        }),
    ];

    if (base.logradouro && base.cidade) {
        queries.push(
            new URLSearchParams({
                address: `${linhaRua || base.logradouro}, ${base.bairro}, ${base.cidade} - ${base.uf}, Brasil`
                    .replace(/,\s*,/g, ",")
                    .replace(/\s+-\s+,/g, ","),
                language: "pt-BR",
                region: "br",
                key: apiKey,
            }),
        );
    }

    const resultado = await geocodeGoogle(
        apiKey,
        queries,
        "GOOGLE_GEOCODING_ENDERECO",
    );
    if (resultado) {
        await gravarCacheMaps(cacheKey, resultado, GEOCODE_CACHE_TTL_MS, {
            tipo: "endereco",
        });
    }
    return resultado;
}

async function resolverCep(
    cep: string,
    apiKey: string,
    enderecoHint?: {
        logradouro?: string;
        numero?: string;
        bairro?: string;
        cidade?: string;
        uf?: string;
    },
): Promise<EnderecoResolvidoComCep | null> {
    const cacheKey = chaveCep(cep);
    const cached = await lerCacheMaps<EnderecoResolvidoComCep>(cacheKey);
    // Só reaproveita cache com coordenadas. ViaCEP sem lat/lng não deve
    // bloquear novas tentativas de Google Geocoding.
    if (
        cached &&
        cached.latitude != null &&
        cached.longitude != null &&
        Number.isFinite(cached.latitude) &&
        Number.isFinite(cached.longitude)
    ) {
        return {
            ...cached,
            cep: cached.cep || cep,
            origemCalculo: `${texto(cached.origemCalculo) || "CACHE"}_HIT`,
        };
    }

    const cepFormatado = `${cep.slice(0, 5)}-${cep.slice(5)}`;

    // Poucas tentativas Google (antes eram 5+). Para no primeiro OK.
    const porCep = await geocodeGoogle(
        apiKey,
        [
            new URLSearchParams({
                components: `country:BR|postal_code:${cepFormatado}`,
                language: "pt-BR",
                region: "br",
                key: apiKey,
            }),
            new URLSearchParams({
                address: `${cepFormatado}, Brasil`,
                language: "pt-BR",
                region: "br",
                key: apiKey,
            }),
        ],
        "GOOGLE_GEOCODING_CEP",
    );

    if (porCep?.latitude != null && porCep.longitude != null) {
        const ok = { ...porCep, cep: porCep.cep || cep };
        await gravarCacheMaps(cacheKey, ok, GEOCODE_CACHE_TTL_MS, { tipo: "cep" });
        return ok;
    }

    // ViaCEP → geocode textual (com número, se houver hint).
    const viaCep = await buscarViaCep(cep);
    const numeroHint = texto(enderecoHint?.numero);
    const base = {
        logradouro: texto(enderecoHint?.logradouro) || viaCep?.logradouro || porCep?.logradouro || "",
        bairro: texto(enderecoHint?.bairro) || viaCep?.bairro || porCep?.bairro || "",
        cidade: texto(enderecoHint?.cidade) || viaCep?.cidade || porCep?.cidade || "",
        uf: texto(enderecoHint?.uf) || viaCep?.uf || porCep?.uf || "",
        cep,
    };

    const linhaRua = [base.logradouro, numeroHint].filter(Boolean).join(", ");
    const enderecoTexto = montarEnderecoTexto({
        logradouro: linhaRua || base.logradouro,
        bairro: base.bairro,
        cidade: base.cidade,
        uf: base.uf,
        cep: base.cep,
    });
    if (enderecoTexto.replace(/Brasil|,|\s/g, "").length < 8) {
        const parcial = porCep
            ? { ...porCep, cep: porCep.cep || cep }
            : viaCep
                ? {
                    cep,
                    logradouro: viaCep.logradouro,
                    numero: numeroHint,
                    bairro: viaCep.bairro,
                    cidade: viaCep.cidade,
                    uf: viaCep.uf,
                    latitude: null,
                    longitude: null,
                    formatado: montarEnderecoTexto({ ...viaCep, cep }),
                    origemCalculo: "VIACEP",
                }
                : null;
        if (parcial?.latitude != null) {
            await gravarCacheMaps(cacheKey, parcial, GEOCODE_CACHE_TTL_MS, { tipo: "cep" });
        }
        return parcial;
    }

    // Mesmas estratégias de resolverPorEndereco (1–2 queries Google).
    const queriesEndereco: URLSearchParams[] = [
        new URLSearchParams({
            address: enderecoTexto,
            components: "country:BR",
            language: "pt-BR",
            region: "br",
            key: apiKey,
        }),
    ];
    if (base.logradouro && base.cidade) {
        queriesEndereco.push(
            new URLSearchParams({
                address: `${linhaRua || base.logradouro}, ${base.bairro}, ${base.cidade} - ${base.uf}, Brasil`
                    .replace(/,\s*,/g, ",")
                    .replace(/\s+-\s+,/g, ","),
                language: "pt-BR",
                region: "br",
                key: apiKey,
            }),
        );
    }

    let porEndereco = await geocodeGoogle(
        apiKey,
        queriesEndereco,
        viaCep ? "GOOGLE_GEOCODING_VIA_VIACEP" : "GOOGLE_GEOCODING_ENDERECO",
    );

    // Se o geocode “inline” falhou, tenta o resolver dedicado (cache/endereço).
    if (
        (porEndereco?.latitude == null || porEndereco?.longitude == null) &&
        base.logradouro.length >= 3 &&
        base.cidade.length >= 2
    ) {
        const dedicado = await resolverPorEndereco(apiKey, {
            logradouro: base.logradouro,
            numero: numeroHint,
            bairro: base.bairro,
            cidade: base.cidade,
            uf: base.uf,
            cep,
        });
        if (dedicado?.latitude != null && dedicado.longitude != null) {
            porEndereco = dedicado;
        }
    }

    if (!porEndereco || porEndereco.latitude == null || porEndereco.longitude == null) {
        if (viaCep) {
            // Não grava cache sem coords — evita “envenenar” lookups futuros.
            return {
                cep,
                logradouro: viaCep.logradouro,
                numero: numeroHint,
                bairro: viaCep.bairro,
                cidade: viaCep.cidade,
                uf: viaCep.uf,
                latitude: null,
                longitude: null,
                formatado: montarEnderecoTexto({ ...viaCep, cep }),
                origemCalculo: "VIACEP",
            };
        }
        return porCep ? { ...porCep, cep: porCep.cep || cep } : null;
    }

    const resultado = {
        cep: porEndereco.cep || cep,
        logradouro: porEndereco.logradouro || base.logradouro,
        numero: porEndereco.numero || numeroHint,
        bairro: porEndereco.bairro || base.bairro,
        cidade: porEndereco.cidade || base.cidade,
        uf: porEndereco.uf || base.uf,
        latitude: porEndereco.latitude,
        longitude: porEndereco.longitude,
        formatado: porEndereco.formatado || enderecoTexto,
        origemCalculo: porEndereco.origemCalculo,
    };
    await gravarCacheMaps(cacheKey, resultado, GEOCODE_CACHE_TTL_MS, { tipo: "cep" });
    return resultado;
}

export const buscarCepGoogle = onRequest(
    {
        region: "southamerica-east1",
        secrets: [googleMapsApiKey],
        timeoutSeconds: 20,
        memory: "256MiB",
        // Cadastro ainda não tem sessão; a consulta é limitada por IP.
        invoker: "public",
    },
    async (req, res) => {
        res.set("Access-Control-Allow-Origin", "*");
        res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
        res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }

        if (req.method !== "POST") {
            res.status(405).json({ sucesso: false, mensagem: "Método não permitido." });
            return;
        }

        try {
            const body = (req.body?.data ?? req.body ?? {}) as Record<string, unknown>;
            const cep = somenteDigitos(body.cep);
            const logradouro = texto(body.logradouro);
            const numero = texto(body.numero);
            const bairro = texto(body.bairro);
            const cidade = texto(body.cidade);
            const uf = texto(body.uf).toUpperCase();
            const latitude = Number(body.latitude);
            const longitude = Number(body.longitude);
            const temCep = cep.length === 8;
            const temEndereco = logradouro.length >= 3 && cidade.length >= 2;
            const temCoords =
                Number.isFinite(latitude) &&
                Number.isFinite(longitude) &&
                latitude >= -90 &&
                latitude <= 90 &&
                longitude >= -180 &&
                longitude <= 180;

            if (!temCep && !temEndereco && !temCoords) {
                res.status(400).json({
                    sucesso: false,
                    mensagem:
                        "Informe um CEP válido (8 dígitos), rua e cidade, ou latitude/longitude.",
                });
                return;
            }

            const ip = texto(req.headers["x-forwarded-for"] ?? req.ip).split(",")[0];
            const chaveLimite = temCoords
                ? `gps:${latitude.toFixed(4)}|${longitude.toFixed(4)}`
                : temCep
                    ? cep
                    : `${uf}|${cidade}|${logradouro}|${numero}`.toLowerCase();
            const permitido = await validarLimite(ip || "unknown", chaveLimite);
            if (!permitido) {
                res.status(429).json({
                    sucesso: false,
                    mensagem: "Muitas consultas de endereço. Aguarde alguns minutos.",
                });
                return;
            }

            const apiKey = googleMapsApiKey.value();
            const resultado = temCoords
                ? await resolverPorCoordenadas(apiKey, latitude, longitude)
                : temCep
                    ? await resolverCep(cep, apiKey, {
                        logradouro,
                        numero,
                        bairro,
                        cidade,
                        uf,
                    })
                    : await resolverPorEndereco(apiKey, {
                        logradouro,
                        numero,
                        bairro,
                        cidade,
                        uf,
                        cep,
                    });

            // CEP veio só do ViaCEP (sem lat/lng): tenta geocode dedicado por endereço.
            let resolvido = resultado;
            if (
                resolvido &&
                (resolvido.latitude == null || resolvido.longitude == null) &&
                temEndereco
            ) {
                console.info(
                    "[buscarCepGoogle] origem sem coords (%s). Tentando resolverPorEndereco…",
                    resolvido.origemCalculo,
                );
                const porEndereco = await resolverPorEndereco(apiKey, {
                    logradouro: logradouro || resolvido.logradouro,
                    numero: numero || resolvido.numero,
                    bairro: bairro || resolvido.bairro,
                    cidade: cidade || resolvido.cidade,
                    uf: uf || resolvido.uf,
                    cep: cep || resolvido.cep,
                });
                if (porEndereco?.latitude != null && porEndereco.longitude != null) {
                    resolvido = {
                        ...porEndereco,
                        cep: somenteDigitos(porEndereco.cep) || cep || resolvido.cep,
                        logradouro: porEndereco.logradouro || resolvido.logradouro,
                        numero: porEndereco.numero || numero || resolvido.numero,
                        bairro: porEndereco.bairro || resolvido.bairro,
                        cidade: porEndereco.cidade || resolvido.cidade,
                        uf: porEndereco.uf || resolvido.uf,
                    };
                }
            }

            if (!resolvido) {
                res.status(404).json({
                    sucesso: false,
                    mensagem: temCoords
                        ? "Não foi possível localizar um endereço para essas coordenadas."
                        : temCep
                            ? "CEP não localizado no Google Maps."
                            : "Endereço não localizado no Google Maps.",
                });
                return;
            }

            const cepResposta = somenteDigitos(resolvido.cep) || cep;

            res.status(200).json({
                sucesso: true,
                cep: cepResposta,
                logradouro: resolvido.logradouro,
                numero: resolvido.numero || "",
                bairro: resolvido.bairro,
                cidade: resolvido.cidade,
                uf: resolvido.uf,
                latitude: resolvido.latitude,
                longitude: resolvido.longitude,
                formatado: resolvido.formatado,
                origemCalculo: resolvido.origemCalculo,
                possuiCoordenadas:
                    resolvido.latitude != null && resolvido.longitude != null,
            });
        } catch (error) {
            console.error("[buscarCepGoogle] erro:", error);
            res.status(500).json({
                sucesso: false,
                mensagem: "Falha interna ao consultar o endereço.",
            });
        }
    },
);
