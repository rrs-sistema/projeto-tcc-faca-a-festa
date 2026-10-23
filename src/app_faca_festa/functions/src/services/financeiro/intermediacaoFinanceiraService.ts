/**
 * Intermediação operacional: recebimento → alocação → comissão → repasse.
 * Sem movimentação bancária. Dimensões não somáveis indiscriminadamente.
 * Política de liberação ausente/inativa → elegibilidade pendente (não libera auto).
 */

import { calcularComissaoCentavos } from "./comissaoPlataformaService";
import { LIMITE_CENTAVOS } from "./dinheiro";

export type NivelConfirmacaoRecebimento =
  | "declaracao"
  | "conferencia"
  | "fonte_externa";

export type EstadoRepasse =
  | "previsto"
  | "elegivel_pendente"
  | "autorizado"
  | "em_processamento"
  | "confirmado"
  | "falhou"
  | "cancelado";

export type ModoComissao = "descontada_fornecedor" | "adicionada_cliente";

export type CriterioAlocacao = "manual_explicito";

export type RecebimentoPlataforma = {
  id: string;
  idEvento: string;
  idPagador: string | null;
  valorCentavos: number;
  nivelConfirmacao: NivelConfirmacaoRecebimento;
  /** Soma das alocações válidas. */
  alocadoCentavos: number;
  referencia: string | null;
  origem: string;
  /** Legado "pago" no orçamento ≠ recebimento plataforma. */
  origemLegadoPago: boolean;
};

export type AlocacaoContrato = {
  id: string;
  idRecebimento: string;
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  idFornecedor: string | null;
  valorCentavos: number;
  criterio: CriterioAlocacao;
};

export type PoliticaLiberacaoRepasse = {
  id: string;
  versao: number;
  ativa: boolean;
  /** Se false/ausente, nenhum repasse é elegível automaticamente. */
  permiteRepasseParcial: boolean;
  /** Teto opcional por operação (centavos). null = sem teto além do disponível. */
  tetoParcialCentavos: number | null;
};

export type PosicaoContratoIntermediado = {
  idContrato: string;
  valorContratadoCentavos: number;
  modoComissao: ModoComissao;
  percentualBps: number;
  comissaoPrevistaCentavos: number;
  direitoFornecedorPrevistoCentavos: number;
  recebidoPlataformaAlocadoCentavos: number;
  aReceberClienteCentavos: number;
  previstoRepasseCentavos: number;
  elegivelRepasseCentavos: number;
  autorizadoRepasseCentavos: number;
  emProcessamentoCentavos: number;
  repassadoConfirmadoCentavos: number;
  /** Dinheiro na plataforma ainda sem destinação a contrato. */
  semAlocacaoNoPedidoCentavos: number;
  /** Remuneração APP prevista (não é caixa de terceiros). */
  remuneracaoAppPrevistaCentavos: number;
  politicaLiberacaoAtiva: boolean;
};

export type RepasseRascunho = {
  idContrato: string;
  idFornecedor: string;
  valorCentavos: number;
  estado: EstadoRepasse;
  idsAlocacaoOrigem: string[];
  confirmacaoManual: boolean;
  motivoBloqueio: string | null;
};

function assertCentavos(v: number, nome: string): void {
  if (!Number.isInteger(v) || v < 0 || v > LIMITE_CENTAVOS) {
    throw Object.assign(new Error(`${nome} inválido.`), {
      code: "invalid-argument",
    });
  }
}

/** Direito do fornecedor e comissão — sem cobrança duplicada no modo desconto. */
export function calcularDireitosContrato(params: {
  valorContratadoCentavos: number;
  percentualBps: number;
  modoComissao: ModoComissao;
}): {
  comissaoPrevistaCentavos: number;
  direitoFornecedorPrevistoCentavos: number;
  precoClienteCentavos: number;
} {
  assertCentavos(params.valorContratadoCentavos, "Valor contratado");
  const comissao = calcularComissaoCentavos(
    params.valorContratadoCentavos,
    params.percentualBps,
  );
  if (params.modoComissao === "descontada_fornecedor") {
    return {
      comissaoPrevistaCentavos: comissao,
      direitoFornecedorPrevistoCentavos:
        params.valorContratadoCentavos - comissao,
      precoClienteCentavos: params.valorContratadoCentavos,
    };
  }
  // adicionada_cliente: cliente paga contrato + comissão; fornecedor recebe o contratado.
  return {
    comissaoPrevistaCentavos: comissao,
    direitoFornecedorPrevistoCentavos: params.valorContratadoCentavos,
    precoClienteCentavos: params.valorContratadoCentavos + comissao,
  };
}

export function disponivelParaAlocar(r: RecebimentoPlataforma): number {
  return Math.max(0, r.valorCentavos - r.alocadoCentavos);
}

/**
 * Valida lote de alocações manuais sobre um recebimento.
 * Não rateia silenciosamente; cada destinação deve ser explícita.
 */
export function validarAlocacoesRecebimento(params: {
  recebimento: RecebimentoPlataforma;
  alocacoesNovas: Array<{ idContrato: string; valorCentavos: number }>;
  alocadoPrevioCentavos?: number;
}): { ok: true; totalNovo: number } | { ok: false; motivo: string } {
  const previo = params.alocadoPrevioCentavos ?? params.recebimento.alocadoCentavos;
  let totalNovo = 0;
  for (const a of params.alocacoesNovas) {
    assertCentavos(a.valorCentavos, "Alocação");
    if (!a.idContrato.trim()) {
      return { ok: false, motivo: "Contrato obrigatório em cada alocação." };
    }
    if (a.valorCentavos <= 0) {
      return { ok: false, motivo: "Alocação deve ser positiva." };
    }
    totalNovo += a.valorCentavos;
  }
  if (previo + totalNovo > params.recebimento.valorCentavos) {
    return {
      ok: false,
      motivo: "Alocação excede o valor confirmado do recebimento.",
    };
  }
  return { ok: true, totalNovo };
}

/** Simula concorrência: duas tentativas sobre o mesmo disponível. */
export function tentarAlocarConcurrente(params: {
  disponivelCentavos: number;
  pedidoACentavos: number;
  pedidoBCentavos: number;
}): { aceitoA: boolean; aceitoB: boolean; restante: number } {
  let restante = params.disponivelCentavos;
  let aceitoA = false;
  let aceitoB = false;
  if (params.pedidoACentavos <= restante) {
    restante -= params.pedidoACentavos;
    aceitoA = true;
  }
  if (params.pedidoBCentavos <= restante) {
    restante -= params.pedidoBCentavos;
    aceitoB = true;
  }
  return { aceitoA, aceitoB, restante };
}

export function avaliarElegibilidadeRepasse(params: {
  direitoFornecedorPrevistoCentavos: number;
  alocadoAoContratoCentavos: number;
  jaRepassadoCentavos: number;
  jaAutorizadoOuProcessandoCentavos: number;
  politica: PoliticaLiberacaoRepasse | null;
}): {
  estadoSugerido: EstadoRepasse;
  elegivelCentavos: number;
  motivo: string | null;
} {
  const tetoDireito = Math.max(
    0,
    params.direitoFornecedorPrevistoCentavos -
      params.jaRepassadoCentavos -
      params.jaAutorizadoOuProcessandoCentavos,
  );
  const financiado = Math.max(
    0,
    params.alocadoAoContratoCentavos -
      params.jaRepassadoCentavos -
      params.jaAutorizadoOuProcessandoCentavos,
  );
  const bruto = Math.min(tetoDireito, financiado);

  if (!params.politica || !params.politica.ativa) {
    return {
      estadoSugerido: "elegivel_pendente",
      elegivelCentavos: 0,
      motivo:
        "Política de liberação ausente ou inativa — repasse não autorizado automaticamente.",
    };
  }

  let elegivel = bruto;
  if (params.politica.permiteRepasseParcial) {
    if (
      typeof params.politica.tetoParcialCentavos === "number" &&
      params.politica.tetoParcialCentavos >= 0
    ) {
      elegivel = Math.min(elegivel, params.politica.tetoParcialCentavos);
    }
  } else {
    // Sem parcial: só libera o total do direito quando financiado integralmente.
    if (financiado < tetoDireito) {
      return {
        estadoSugerido: "elegivel_pendente",
        elegivelCentavos: 0,
        motivo: "Política exige financiamento integral antes do repasse.",
      };
    }
  }

  if (elegivel <= 0) {
    return {
      estadoSugerido: "previsto",
      elegivelCentavos: 0,
      motivo: "Sem valor elegível no momento.",
    };
  }

  return {
    estadoSugerido: "autorizado",
    elegivelCentavos: elegivel,
    motivo: null,
  };
}

/**
 * Autorizar ≠ confirmado. Confirmação manual é conferência, não banco.
 */
export function transicionarRepasse(params: {
  estadoAtual: EstadoRepasse;
  acao: "autorizar" | "iniciar_processamento" | "confirmar_manual" | "falhar" | "cancelar";
  confirmacaoManual?: boolean;
}): { estado: EstadoRepasse; confirmacaoManual: boolean } {
  const atual = params.estadoAtual;
  switch (params.acao) {
    case "autorizar":
      if (atual !== "elegivel_pendente" && atual !== "previsto" && atual !== "autorizado") {
        throw Object.assign(new Error("Estado não permite autorizar."), {
          code: "failed-precondition",
        });
      }
      return { estado: "autorizado", confirmacaoManual: false };
    case "iniciar_processamento":
      if (atual !== "autorizado") {
        throw Object.assign(new Error("Só processa repasse autorizado."), {
          code: "failed-precondition",
        });
      }
      return { estado: "em_processamento", confirmacaoManual: false };
    case "confirmar_manual":
      if (atual !== "autorizado" && atual !== "em_processamento") {
        throw Object.assign(new Error("Confirmação exige autorização prévia."), {
          code: "failed-precondition",
        });
      }
      return {
        estado: "confirmado",
        confirmacaoManual: params.confirmacaoManual !== false,
      };
    case "falhar":
      if (atual !== "em_processamento" && atual !== "autorizado") {
        throw Object.assign(new Error("Falha só em processamento/autorizado."), {
          code: "failed-precondition",
        });
      }
      return { estado: "falhou", confirmacaoManual: false };
    case "cancelar":
      if (atual === "confirmado") {
        throw Object.assign(
          new Error("Repasse confirmado não é apagado; use ajuste/recuperação."),
          { code: "failed-precondition" },
        );
      }
      return { estado: "cancelado", confirmacaoManual: false };
    default:
      throw Object.assign(new Error("Ação inválida."), { code: "invalid-argument" });
  }
}

/**
 * Concilição de caixa do pedido (dimensões separadas).
 * Invariante: recebido = alocado + sem_alocacao.
 * Repassado ≤ alocado (financiamento); comissão não “some” o residual.
 */
export function conciliarCaixaPedido(params: {
  recebimentosConfirmadosCentavos: number;
  alocadoTotalCentavos: number;
  repassadoConfirmadoCentavos: number;
  remuneracaoAppSeparadaCentavos: number;
}): {
  semAlocacaoCentavos: number;
  residualAposRepasseCentavos: number;
  ok: boolean;
  violacoes: string[];
} {
  const violacoes: string[] = [];
  if (params.alocadoTotalCentavos > params.recebimentosConfirmadosCentavos) {
    violacoes.push("Alocado excede recebido.");
  }
  if (params.repassadoConfirmadoCentavos > params.alocadoTotalCentavos) {
    violacoes.push("Repassado excede alocado (financiamento).");
  }
  const semAlocacao = Math.max(
    0,
    params.recebimentosConfirmadosCentavos - params.alocadoTotalCentavos,
  );
  const residual = Math.max(
    0,
    params.alocadoTotalCentavos - params.repassadoConfirmadoCentavos,
  );
  // Remuneração APP é dimensão separada — não reduz automaticamente o residual.
  if (params.remuneracaoAppSeparadaCentavos < 0) {
    violacoes.push("Remuneração inválida.");
  }
  return {
    semAlocacaoCentavos: semAlocacao,
    residualAposRepasseCentavos: residual,
    ok: violacoes.length === 0,
    violacoes,
  };
}

/**
 * Chargeback/reembolso após repasse: não apaga saída; registra necessidade de recuperação.
 */
export function registrarChargebackAposRepasse(params: {
  valorChargebackCentavos: number;
  repassadoConfirmadoCentavos: number;
}): {
  ajusteCreditoClienteCentavos: number;
  recuperacaoPendenteCentavos: number;
  repasseHistoricoPreservadoCentavos: number;
} {
  assertCentavos(params.valorChargebackCentavos, "Chargeback");
  return {
    ajusteCreditoClienteCentavos: params.valorChargebackCentavos,
    recuperacaoPendenteCentavos: Math.min(
      params.valorChargebackCentavos,
      params.repassadoConfirmadoCentavos,
    ),
    repasseHistoricoPreservadoCentavos: params.repassadoConfirmadoCentavos,
  };
}

/** Monta posição operacional de um contrato intermediado (visão admin). */
export function montarPosicaoContrato(params: {
  idContrato: string;
  valorContratadoCentavos: number;
  percentualBps: number;
  modoComissao: ModoComissao;
  alocadoCentavos: number;
  repassadoConfirmadoCentavos: number;
  autorizadoOuProcessandoCentavos: number;
  recebimentosPedidoCentavos: number;
  alocadoPedidoCentavos: number;
  politica: PoliticaLiberacaoRepasse | null;
}): PosicaoContratoIntermediado {
  const direitos = calcularDireitosContrato({
    valorContratadoCentavos: params.valorContratadoCentavos,
    percentualBps: params.percentualBps,
    modoComissao: params.modoComissao,
  });
  const aReceber = Math.max(
    0,
    direitos.precoClienteCentavos - params.recebimentosPedidoCentavos,
  );
  const eleg = avaliarElegibilidadeRepasse({
    direitoFornecedorPrevistoCentavos: direitos.direitoFornecedorPrevistoCentavos,
    alocadoAoContratoCentavos: params.alocadoCentavos,
    jaRepassadoCentavos: params.repassadoConfirmadoCentavos,
    jaAutorizadoOuProcessandoCentavos: params.autorizadoOuProcessandoCentavos,
    politica: params.politica,
  });
  const conc = conciliarCaixaPedido({
    recebimentosConfirmadosCentavos: params.recebimentosPedidoCentavos,
    alocadoTotalCentavos: params.alocadoPedidoCentavos,
    repassadoConfirmadoCentavos: params.repassadoConfirmadoCentavos,
    remuneracaoAppSeparadaCentavos: direitos.comissaoPrevistaCentavos,
  });

  return {
    idContrato: params.idContrato,
    valorContratadoCentavos: params.valorContratadoCentavos,
    modoComissao: params.modoComissao,
    percentualBps: params.percentualBps,
    comissaoPrevistaCentavos: direitos.comissaoPrevistaCentavos,
    direitoFornecedorPrevistoCentavos: direitos.direitoFornecedorPrevistoCentavos,
    recebidoPlataformaAlocadoCentavos: params.alocadoCentavos,
    aReceberClienteCentavos: aReceber,
    previstoRepasseCentavos: Math.max(
      0,
      direitos.direitoFornecedorPrevistoCentavos - params.repassadoConfirmadoCentavos,
    ),
    elegivelRepasseCentavos: eleg.elegivelCentavos,
    autorizadoRepasseCentavos: params.autorizadoOuProcessandoCentavos,
    emProcessamentoCentavos: 0,
    repassadoConfirmadoCentavos: params.repassadoConfirmadoCentavos,
    semAlocacaoNoPedidoCentavos: conc.semAlocacaoCentavos,
    remuneracaoAppPrevistaCentavos: direitos.comissaoPrevistaCentavos,
    politicaLiberacaoAtiva: params.politica?.ativa === true,
  };
}
