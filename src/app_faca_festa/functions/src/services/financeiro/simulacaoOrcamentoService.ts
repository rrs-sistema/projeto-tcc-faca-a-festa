import { calcularResumo } from "./resumoFinanceiro";

export type Alternativa = {
  id: string;
  idNecessidade: string;
  rotulo: string;
  precoCentavos: number;
  vigente?: boolean;
  compativelCatalogo?: boolean;
  historicoValido?: boolean;
  fonte?: string;
  versaoFonte?: string;
};

/**
 * Simulação read-only. Não grava contrato/compra/reserva/pagamento/comissão.
 */
export function orcamentoLivreAntesDespesas(
  limiteCentavos: number,
  comprometidoCentavos: number,
): number {
  return limiteCentavos - comprometidoCentavos;
}

export function comprometidoCentavosDeCompromissos(
  compromissos: Record<string, unknown>[],
): number {
  const r = calcularResumo(compromissos);
  return Math.round(r.contratado * 100);
}

export function simularOrcamento(entrada: {
  limiteCentavos: number;
  compromissos: Record<string, unknown>[];
  necessidades: Array<{
    id: string;
    descricao: string;
    eliminada?: boolean;
    cobertaPorBuffet?: boolean;
  }>;
  alternativasPorNecessidade: Record<string, Alternativa[]>;
  despesasCentavos?: number;
  reservaCentavos?: number;
}): {
  limiteConfirmadoCentavos: number;
  comprometidoCentavos: number;
  orcamentoLivreAntesDespesasCentavos: number;
  completo: boolean;
  alteraFinanceiro: false;
  cenarios: Array<{
    tipo: string;
    previsaoCentavos: number;
    folgaOuExcessoCentavos: number;
    disponivel: boolean;
    motivoIndisponivel?: string;
    itensSemPreco: number;
  }>;
  premissas: string[];
} {
  const comprometido = comprometidoCentavosDeCompromissos(entrada.compromissos);
  const livres = orcamentoLivreAntesDespesas(entrada.limiteCentavos, comprometido);
  const despesas = entrada.despesasCentavos ?? 0;
  const reserva = entrada.reservaCentavos ?? 0;
  let completo = true;

  function altsValidas(idNec: string): Alternativa[] {
    return (entrada.alternativasPorNecessidade[idNec] ?? [])
      .filter(
        (a) =>
          a.vigente !== false &&
          a.compativelCatalogo !== false &&
          a.historicoValido !== false &&
          a.precoCentavos > 0,
      )
      .sort((a, b) => a.precoCentavos - b.precoCentavos);
  }

  for (const n of entrada.necessidades) {
    if (n.eliminada || n.cobertaPorBuffet) continue;
    if (altsValidas(n.id).length === 0) completo = false;
  }

  function montar(tipo: "economico" | "intermediario" | "completo") {
    let adicional = 0;
    let disponivel = true;
    let motivo: string | undefined;
    let itensSemPreco = 0;

    for (const n of entrada.necessidades) {
      if (n.eliminada || n.cobertaPorBuffet) continue;
      const alts = altsValidas(n.id);
      if (alts.length === 0) {
        disponivel = false;
        itensSemPreco++;
        motivo = `Sem preço válido para ${n.descricao} (não inventa).`;
        continue;
      }
      if (tipo === "intermediario" && alts.length < 2) {
        disponivel = false;
        motivo = "Cenário intermediário exige alternativas reais distintas.";
      }
      if (tipo === "completo" && alts.length < 2) {
        disponivel = false;
        motivo = "Cenário completo exige mais de uma alternativa real.";
      }
      let escolha = alts[0];
      if (tipo === "completo") escolha = alts[alts.length - 1];
      else if (tipo === "intermediario") escolha = alts[Math.floor(alts.length / 2)];
      // Uma alternativa por necessidade — não soma concorrentes.
      adicional += escolha.precoCentavos;
    }

    const previsao = comprometido + adicional + despesas;
    return {
      tipo,
      previsaoCentavos: previsao,
      folgaOuExcessoCentavos: entrada.limiteCentavos - previsao - reserva,
      disponivel,
      motivoIndisponivel: motivo,
      itensSemPreco,
    };
  }

  return {
    limiteConfirmadoCentavos: entrada.limiteCentavos,
    comprometidoCentavos: comprometido,
    orcamentoLivreAntesDespesasCentavos: livres,
    completo,
    alteraFinanceiro: false,
    cenarios: [montar("economico"), montar("intermediario"), montar("completo")],
    premissas: [
      "Simulação não altera fatos financeiros.",
      "Alternativas da mesma necessidade não são somadas.",
      "Uma cobertura por cenário; buffet já coberto não entra de novo.",
    ],
  };
}

/** Teto do serviço compartilhado — nunca o limite global do cliente. */
export function tetoCompartilhadoParaFornecedor(params: {
  idFornecedor: string;
  idNecessidade: string;
  tetoCentavos: number | null;
  compartilhadoExplicitamente: boolean;
  solicitanteUid: string;
  idFornecedorSolicitante: string;
}): { tetoCentavos: number; idNecessidade: string } | null {
  if (!params.compartilhadoExplicitamente || params.tetoCentavos == null) {
    return null;
  }
  if (params.solicitanteUid !== params.idFornecedorSolicitante) {
    throw Object.assign(new Error("Sem autorização para o teto deste serviço."), {
      code: "permission-denied",
    });
  }
  if (params.idFornecedor !== params.idFornecedorSolicitante) {
    throw Object.assign(new Error("Sem acesso a teto de outro fornecedor."), {
      code: "permission-denied",
    });
  }
  return {
    tetoCentavos: params.tetoCentavos,
    idNecessidade: params.idNecessidade,
  };
}
