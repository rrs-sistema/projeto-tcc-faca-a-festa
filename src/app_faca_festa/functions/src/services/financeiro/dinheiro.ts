/** Centavos inteiros BRL — limites e arredondamento explícitos. */
export const LIMITE_CENTAVOS = 100_000_000; // R$ 1.000.000,00

export type Dinheiro = { centavos: number; moeda: "BRL" };

export function dinheiro(centavos: number): Dinheiro {
  if (!Number.isInteger(centavos) || centavos < 0 || centavos > LIMITE_CENTAVOS) {
    throw new Error("Valor monetário inválido.");
  }
  return { centavos, moeda: "BRL" };
}

export function reaisParaCentavosArredondado(reais: number): number {
  if (!Number.isFinite(reais) || reais < 0) {
    throw new Error("Informe um valor em reais válido.");
  }
  return Math.round(reais * 100);
}

export function deMapa(valor: unknown): Dinheiro | null {
  if (!valor || typeof valor !== "object") return null;
  const c = (valor as { centavos?: unknown }).centavos;
  if (typeof c === "number" && Number.isInteger(c) && c >= 0 && c <= LIMITE_CENTAVOS) {
    return { centavos: c, moeda: "BRL" };
  }
  return null;
}

/** Adapta legado double sem migrar silenciosamente valores ambíguos. */
export function deReaisLegado(reais: unknown): Dinheiro | null {
  if (typeof reais !== "number" || !Number.isFinite(reais) || reais < 0) return null;
  const centavos = Math.round(reais * 100);
  if (Math.abs(centavos / 100 - reais) > 1e-9) return null;
  if (centavos > LIMITE_CENTAVOS) return null;
  return { centavos, moeda: "BRL" };
}

export function emReais(d: Dinheiro): number {
  return d.centavos / 100;
}
