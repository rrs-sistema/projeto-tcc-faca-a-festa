/**
 * Precificação do fornecedor.
 * Margem + taxas na mesma base de venda:
 *   preço = custos / (1 − margem − taxas)
 * Distinto de markup sobre custo. Denominador ≤ 0 → rejeita.
 */

export type PrecificacaoResultado = {
  precoCentavos: number;
  custosMonetariosCentavos: number;
  margemSobreVenda: number;
  taxasSobreVenda: number;
  denominador: number;
  tipo: string;
  premissas: string[];
};

export function precoPorMargemSobreVenda(
  custosMonetariosCentavos: number,
  margemSobreVenda: number,
  taxasSobreVenda = 0,
): PrecificacaoResultado {
  if (!Number.isInteger(custosMonetariosCentavos) || custosMonetariosCentavos < 0) {
    throw Object.assign(new Error("Custos monetários inválidos."), {
      code: "invalid-argument",
    });
  }
  if (
    !Number.isFinite(margemSobreVenda) ||
    margemSobreVenda < 0 ||
    !Number.isFinite(taxasSobreVenda) ||
    taxasSobreVenda < 0
  ) {
    throw Object.assign(new Error("Margem/taxas inválidas."), {
      code: "invalid-argument",
    });
  }
  const denominador = 1 - margemSobreVenda - taxasSobreVenda;
  if (!(denominador > 0) || !Number.isFinite(denominador)) {
    throw Object.assign(
      new Error(
        `Denominador não positivo (1 − margem − taxas = ${denominador}).`,
      ),
      { code: "failed-precondition" },
    );
  }
  const preco = Math.round(custosMonetariosCentavos / denominador);
  return {
    precoCentavos: preco,
    custosMonetariosCentavos,
    margemSobreVenda,
    taxasSobreVenda,
    denominador,
    tipo: "margem_sobre_venda",
    premissas: [
      "preço = custos_monetarios / (1 − margem − taxas) na mesma base de venda",
      "margem ≠ markup sobre custo",
      "estoque: custo de uso/consumo, não só compra futura",
    ],
  };
}
