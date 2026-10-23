/**
 * Acompanhamento transparente das partes (Prompt 04).
 * Pagamento do cliente ao APP ≠ caixa do fornecedor.
 * Declaração ≠ conferência ≠ confirmação.
 * Contrato ≠ execução. Abrir detalhe ≠ aceite.
 */

import {
  calcularDireitosContrato,
  ModoComissao,
  EstadoRepasse,
} from "./intermediacaoFinanceiraService";

export type NivelPagamentoPlataforma =
  | "nao_informado"
  | "declarado"
  | "conferido"
  | "confirmado_fonte_externa";

export type EstadoExecucaoParte =
  | "nao_iniciado"
  | "agendado"
  | "em_execucao"
  | "entrega_informada"
  | "aceito"
  | "contestado"
  | "cancelado_execucao";

export type OrigemMovimentoParte =
  | "recebimento_proprio_fornecedor"
  | "repasse_plataforma"
  | "pagamento_cliente_plataforma"
  | "comissao_descontada_repasse"
  | "legado_pago_orcamento";

export type ProximoPasso = {
  codigo: string;
  rotulo: string;
  responsavel: "cliente" | "fornecedor" | "plataforma" | "configuracao" | null;
  /** Política ausente = pendência de configuração, não promessa. */
  ehPendenciaConfiguracao: boolean;
};

export type VisaoContratoOrganizador = {
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  nomeEvento: string | null;
  nomeFornecedor: string | null;
  nomeServico: string | null;
  escopo: string | null;
  valorContratadoCentavos: number;
  /** Soma parcelas conhecidas; null se incompleto. */
  parcelasConhecidas: boolean;
  nivelPagamentoPlataforma: NivelPagamentoPlataforma;
  valorDeclaradoCentavos: number;
  valorConfirmadoPlataformaAlocadoCentavos: number;
  aPagarPlataformaCentavos: number;
  /** Status de repasse só no nível permitido (sem banco/margem). */
  statusRepassePermitido: string;
  estadoExecucao: EstadoExecucaoParte;
  proximoPasso: ProximoPasso;
  aviso:
    "Pagamento à plataforma Faça a Festa. Declaração não confirma recebimento.";
};

export type VisaoContratoFornecedor = {
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  nomeEvento: string | null;
  dataEvento: string | null;
  nomeContratante: string | null;
  nomeServico: string | null;
  escopo: string | null;
  valorContratadoCentavos: number;
  modoComissao: ModoComissao;
  percentualBps: number;
  comissaoPrevistaCentavos: number;
  direitoLiquidoPrevistoCentavos: number;
  /** Cliente→APP alocado (estado comercial), NÃO entrada de caixa do fornecedor. */
  recebidoPlataformaAlocadoCentavos: number;
  trataAlocadoComoCaixaProprio: false;
  repassePrevistoCentavos: number;
  repasseAutorizadoCentavos: number;
  repasseConfirmadoCentavos: number;
  /** Ainda não financiado/elegível — sem prometer prazo. */
  saldoPrevistoRepasseCentavos: number;
  parcelaNaoFinanciadaOuNaoElegivelCentavos: number;
  estadoExecucao: EstadoExecucaoParte;
  pendencias: string[];
  proximoPasso: ProximoPasso;
  /** Extrato comissão descontada ≠ dívida duplicada. */
  comissaoJaDescontadaDoRepasse: boolean;
};

export type MovimentoIdentificado = {
  id: string;
  origem: OrigemMovimentoParte;
  valorCentavos: number;
  idContrato: string | null;
};

/** Transições de execução — ler mensagem/abrir detalhe NÃO aceita. */
export function podeInformarEntrega(
  atual: EstadoExecucaoParte,
): { ok: true } | { ok: false; motivo: string } {
  if (
    atual === "aceito" ||
    atual === "cancelado_execucao" ||
    atual === "entrega_informada"
  ) {
    return {
      ok: false,
      motivo:
        atual === "entrega_informada"
          ? "Entrega já informada; aguarda aceite/contestação."
          : "Execução encerrada para nova entrega.",
    };
  }
  return { ok: true };
}

export function podeRegistrarAceiteOuContestacao(
  atual: EstadoExecucaoParte,
  acao: "aceitar" | "contestar",
): { ok: true } | { ok: false; motivo: string } {
  if (atual !== "entrega_informada") {
    return {
      ok: false,
      motivo:
        "Aceite/contestação só após o fornecedor informar a entrega. Abrir detalhe não conta.",
    };
  }
  if (acao !== "aceitar" && acao !== "contestar") {
    return { ok: false, motivo: "Ação inválida." };
  }
  return { ok: true };
}

export function transicionarExecucao(params: {
  atual: EstadoExecucaoParte;
  acao:
    | "informar_entrega"
    | "aceitar"
    | "contestar"
    | "decisao_operador";
  novoEstadoOperador?: EstadoExecucaoParte;
}): {
  novo: EstadoExecucaoParte;
  preservaHistorico: true;
} {
  if (params.acao === "informar_entrega") {
    const c = podeInformarEntrega(params.atual);
    if (!c.ok) throw new Error(c.motivo);
    return { novo: "entrega_informada", preservaHistorico: true };
  }
  if (params.acao === "aceitar") {
    const c = podeRegistrarAceiteOuContestacao(params.atual, "aceitar");
    if (!c.ok) throw new Error(c.motivo);
    return { novo: "aceito", preservaHistorico: true };
  }
  if (params.acao === "contestar") {
    const c = podeRegistrarAceiteOuContestacao(params.atual, "contestar");
    if (!c.ok) throw new Error(c.motivo);
    return { novo: "contestado", preservaHistorico: true };
  }
  // Operador: decisão fundamentada sem apagar manifestações (histórico fora).
  const destino = params.novoEstadoOperador ?? params.atual;
  return { novo: destino, preservaHistorico: true };
}

export function nivelDeConfirmacaoRecebimento(params: {
  declaradoCentavos: number;
  conferidoCentavos: number;
  confirmadoFonteExternaCentavos: number;
}): NivelPagamentoPlataforma {
  if (params.confirmadoFonteExternaCentavos > 0) return "confirmado_fonte_externa";
  if (params.conferidoCentavos > 0) return "conferido";
  if (params.declaradoCentavos > 0) return "declarado";
  return "nao_informado";
}

export function montarVisaoOrganizador(params: {
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  nomeEvento: string | null;
  nomeFornecedor: string | null;
  nomeServico: string | null;
  escopo: string | null;
  valorContratadoCentavos: number;
  declaradoCentavos: number;
  /** Alocado confirmado (conferência/fonte) ao contrato. */
  confirmadoAlocadoCentavos: number;
  estadoRepasse: EstadoRepasse | "sem_repasse" | "elegivel_pendente";
  estadoExecucao: EstadoExecucaoParte;
  parcelasConhecidas: boolean;
  politicaLiberacaoAtiva: boolean;
}): VisaoContratoOrganizador {
  const nivel = nivelDeConfirmacaoRecebimento({
    declaradoCentavos: params.declaradoCentavos,
    conferidoCentavos: params.confirmadoAlocadoCentavos,
    confirmadoFonteExternaCentavos: 0,
  });
  // Antes da conferência, só declaração — aPagar usa confirmado.
  const confirmado = Math.max(0, params.confirmadoAlocadoCentavos);
  const aPagar = Math.max(0, params.valorContratadoCentavos - confirmado);

  let statusRepasse = "Ainda sem repasse ao fornecedor";
  if (params.estadoRepasse === "confirmado") {
    statusRepasse = "Plataforma registrou repasse confirmado (manual/conferência)";
  } else if (params.estadoRepasse === "autorizado" || params.estadoRepasse === "em_processamento") {
    statusRepasse = "Repasse em acompanhamento pela plataforma";
  } else if (!params.politicaLiberacaoAtiva) {
    statusRepasse = "Liberação de repasse pendente de configuração da plataforma";
  }

  return {
    idContrato: params.idContrato,
    idOrcamento: params.idOrcamento,
    idEvento: params.idEvento,
    nomeEvento: params.nomeEvento,
    nomeFornecedor: params.nomeFornecedor,
    nomeServico: params.nomeServico,
    escopo: params.escopo,
    valorContratadoCentavos: params.valorContratadoCentavos,
    parcelasConhecidas: params.parcelasConhecidas,
    nivelPagamentoPlataforma: nivel,
    valorDeclaradoCentavos: Math.max(0, params.declaradoCentavos),
    valorConfirmadoPlataformaAlocadoCentavos: confirmado,
    aPagarPlataformaCentavos: aPagar,
    statusRepassePermitido: statusRepasse,
    estadoExecucao: params.estadoExecucao,
    proximoPasso: proximoPassoOrganizador({
      nivel,
      aPagar,
      estadoExecucao: params.estadoExecucao,
      politicaLiberacaoAtiva: params.politicaLiberacaoAtiva,
    }),
    aviso:
      "Pagamento à plataforma Faça a Festa. Declaração não confirma recebimento.",
  };
}

export function montarVisaoFornecedor(params: {
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  nomeEvento: string | null;
  dataEvento: string | null;
  nomeContratante: string | null;
  nomeServico: string | null;
  escopo: string | null;
  valorContratadoCentavos: number;
  percentualBps: number;
  modoComissao: ModoComissao;
  alocadoPlataformaCentavos: number;
  repasseAutorizadoCentavos: number;
  repasseConfirmadoCentavos: number;
  politicaLiberacaoAtiva: boolean;
  estadoExecucao: EstadoExecucaoParte;
}): VisaoContratoFornecedor {
  const direitos = calcularDireitosContrato({
    valorContratadoCentavos: params.valorContratadoCentavos,
    percentualBps: params.percentualBps,
    modoComissao: params.modoComissao,
  });
  const alocado = Math.max(0, params.alocadoPlataformaCentavos);
  const confirmado = Math.max(0, params.repasseConfirmadoCentavos);
  const autorizado = Math.max(0, params.repasseAutorizadoCentavos);
  const saldoPrevisto = Math.max(
    0,
    direitos.direitoFornecedorPrevistoCentavos - confirmado,
  );
  // Parcela ainda não financiada: direito − alocado (teto comercial alocado).
  const financiadoTeto = Math.min(
    direitos.direitoFornecedorPrevistoCentavos,
    alocado,
  );
  const naoFinanciadaOuNaoElegivel = Math.max(
    0,
    direitos.direitoFornecedorPrevistoCentavos - financiadoTeto,
  );
  const pendencias: string[] = [];
  if (alocado === 0) pendencias.push("aguardando_recebimento_plataforma");
  if (!params.politicaLiberacaoAtiva) {
    pendencias.push("politica_liberacao_pendente");
  }
  if (params.estadoExecucao === "contestado") {
    pendencias.push("execucao_contestada");
  }
  if (params.estadoExecucao === "entrega_informada") {
    pendencias.push("aguardando_aceite_cliente");
  }

  return {
    idContrato: params.idContrato,
    idOrcamento: params.idOrcamento,
    idEvento: params.idEvento,
    nomeEvento: params.nomeEvento,
    dataEvento: params.dataEvento,
    nomeContratante: params.nomeContratante,
    nomeServico: params.nomeServico,
    escopo: params.escopo,
    valorContratadoCentavos: params.valorContratadoCentavos,
    modoComissao: params.modoComissao,
    percentualBps: params.percentualBps,
    comissaoPrevistaCentavos: direitos.comissaoPrevistaCentavos,
    direitoLiquidoPrevistoCentavos: direitos.direitoFornecedorPrevistoCentavos,
    recebidoPlataformaAlocadoCentavos: alocado,
    trataAlocadoComoCaixaProprio: false,
    repassePrevistoCentavos: direitos.direitoFornecedorPrevistoCentavos,
    repasseAutorizadoCentavos: autorizado,
    repasseConfirmadoCentavos: confirmado,
    saldoPrevistoRepasseCentavos: saldoPrevisto,
    parcelaNaoFinanciadaOuNaoElegivelCentavos: naoFinanciadaOuNaoElegivel,
    estadoExecucao: params.estadoExecucao,
    pendencias,
    proximoPasso: proximoPassoFornecedor({
      alocado,
      confirmado,
      saldoPrevisto,
      politicaLiberacaoAtiva: params.politicaLiberacaoAtiva,
      estadoExecucao: params.estadoExecucao,
    }),
    comissaoJaDescontadaDoRepasse:
      params.modoComissao === "descontada_fornecedor",
  };
}

/**
 * Evita duplicar receita: movimentos de origens distintas não se somam
 * como a mesma entrada.
 */
export function conciliarMovimentosSemDuplicar(
  movimentos: MovimentoIdentificado[],
): {
  porOrigem: Record<OrigemMovimentoParte, number>;
  ids: string[];
  totalRepassePlataformaCentavos: number;
  totalRecebimentoProprioCentavos: number;
  totalPagamentoClientePlataformaCentavos: number;
} {
  const porOrigem = {
    recebimento_proprio_fornecedor: 0,
    repasse_plataforma: 0,
    pagamento_cliente_plataforma: 0,
    comissao_descontada_repasse: 0,
    legado_pago_orcamento: 0,
  } as Record<OrigemMovimentoParte, number>;
  const ids: string[] = [];
  const vistos = new Set<string>();
  for (const m of movimentos) {
    if (vistos.has(m.id)) continue;
    vistos.add(m.id);
    ids.push(m.id);
    porOrigem[m.origem] = (porOrigem[m.origem] ?? 0) + m.valorCentavos;
  }
  return {
    porOrigem,
    ids,
    totalRepassePlataformaCentavos: porOrigem.repasse_plataforma,
    totalRecebimentoProprioCentavos: porOrigem.recebimento_proprio_fornecedor,
    totalPagamentoClientePlataformaCentavos:
      porOrigem.pagamento_cliente_plataforma,
  };
}

export function proximoPassoOrganizador(params: {
  nivel: NivelPagamentoPlataforma;
  aPagar: number;
  estadoExecucao: EstadoExecucaoParte;
  politicaLiberacaoAtiva: boolean;
}): ProximoPasso {
  if (params.estadoExecucao === "entrega_informada") {
    return {
      codigo: "aceitar_ou_contestar",
      rotulo: "Registrar aceite ou contestação da entrega",
      responsavel: "cliente",
      ehPendenciaConfiguracao: false,
    };
  }
  if (params.nivel === "declarado") {
    return {
      codigo: "aguardar_conferencia",
      rotulo: "Aguardar conferência da plataforma sobre o pagamento declarado",
      responsavel: "plataforma",
      ehPendenciaConfiguracao: false,
    };
  }
  if (params.aPagar > 0) {
    return {
      codigo: "pagar_plataforma",
      rotulo:
        "Seguir instruções aprovadas para pagamento à plataforma (sem botão de cobrança automática)",
      responsavel: "cliente",
      ehPendenciaConfiguracao: false,
    };
  }
  if (!params.politicaLiberacaoAtiva) {
    return {
      codigo: "politica_liberacao",
      rotulo: "Repasse ao fornecedor aguarda política de liberação da plataforma",
      responsavel: "configuracao",
      ehPendenciaConfiguracao: true,
    };
  }
  return {
    codigo: "acompanhar",
    rotulo: "Acompanhar execução e intermediação",
    responsavel: null,
    ehPendenciaConfiguracao: false,
  };
}

export function proximoPassoFornecedor(params: {
  alocado: number;
  confirmado: number;
  saldoPrevisto: number;
  politicaLiberacaoAtiva: boolean;
  estadoExecucao: EstadoExecucaoParte;
}): ProximoPasso {
  if (
    params.estadoExecucao === "nao_iniciado" ||
    params.estadoExecucao === "agendado" ||
    params.estadoExecucao === "em_execucao"
  ) {
    return {
      codigo: "informar_entrega",
      rotulo: "Informar entrega quando o serviço for prestado",
      responsavel: "fornecedor",
      ehPendenciaConfiguracao: false,
    };
  }
  if (params.estadoExecucao === "entrega_informada") {
    return {
      codigo: "aguardar_aceite",
      rotulo: "Aguardar aceite ou contestação do cliente",
      responsavel: "cliente",
      ehPendenciaConfiguracao: false,
    };
  }
  if (params.estadoExecucao === "contestado") {
    return {
      codigo: "mediacao",
      rotulo: "Acompanhar mediação — sem reembolso automático",
      responsavel: "plataforma",
      ehPendenciaConfiguracao: false,
    };
  }
  if (!params.politicaLiberacaoAtiva && params.saldoPrevisto > 0) {
    return {
      codigo: "politica_liberacao",
      rotulo: "Elegibilidade de repasse pendente de configuração (sem prazo prometido)",
      responsavel: "configuracao",
      ehPendenciaConfiguracao: true,
    };
  }
  if (params.alocado === 0) {
    return {
      codigo: "aguardar_cliente_plataforma",
      rotulo: "Aguardar confirmação de recebimento do cliente pela plataforma",
      responsavel: "plataforma",
      ehPendenciaConfiguracao: false,
    };
  }
  return {
    codigo: "acompanhar_repasse",
    rotulo: "Acompanhar repasse previsto/autorizado/confirmado",
    responsavel: "plataforma",
    ehPendenciaConfiguracao: false,
  };
}

/** CTA proibidos quando não há integração. */
export const CTAS_INTEGRACAO_AUSENTE = [
  "Pagar agora",
  "Sacar",
  "Pagamento garantido",
] as const;

export function rotulosAcaoPermitidos(params: {
  temGatewayPagamento: boolean;
  temSaque: boolean;
  temGarantia: boolean;
}): string[] {
  const out: string[] = [
    "Registrar declaração de pagamento",
    "Anexar comprovante (não confirma sozinho)",
    "Informar entrega",
    "Registrar aceite",
    "Registrar contestação",
    "Abrir caso de mediação",
  ];
  if (params.temGatewayPagamento) out.push("Pagar agora");
  if (params.temSaque) out.push("Sacar");
  if (params.temGarantia) out.push("Pagamento garantido");
  return out;
}

export function acaoExibidaEhSegura(rotulo: string, permitidos: string[]): boolean {
  if ((CTAS_INTEGRACAO_AUSENTE as readonly string[]).includes(rotulo)) {
    return permitidos.includes(rotulo);
  }
  return true;
}

/**
 * Cenário Ana × Débora — aceite Prompt 04 (domínio puro).
 */
export function cenarioAnaDebora(params: {
  valorContratoCentavos: number;
  declaradoCentavos: number;
  confirmadoAlocadoCentavos: number;
  percentualBps: number;
  repasseConfirmadoCentavos: number;
  politicaLiberacaoAtiva: boolean;
}): {
  antesConferencia: {
    nivel: NivelPagamentoPlataforma;
    fornecedorCaixaProprioCentavos: number;
    adminVePendenciaConferencia: boolean;
  };
  aposConfirmacao: {
    aPagarClienteCentavos: number;
    fornecedorVeAlocadoComoCaixa: false;
    direitoLiquidoCentavos: number;
    saldoPrevistoRepasseCentavos: number;
  };
} {
  const nivelAntes = nivelDeConfirmacaoRecebimento({
    declaradoCentavos: params.declaradoCentavos,
    conferidoCentavos: 0,
    confirmadoFonteExternaCentavos: 0,
  });
  const direitos = calcularDireitosContrato({
    valorContratadoCentavos: params.valorContratoCentavos,
    percentualBps: params.percentualBps,
    modoComissao: "descontada_fornecedor",
  });
  const forn = montarVisaoFornecedor({
    idContrato: "c-debora",
    idOrcamento: "o-debora",
    idEvento: "e-ana",
    nomeEvento: "Festa Ana",
    dataEvento: null,
    nomeContratante: "Ana",
    nomeServico: "Decoração",
    escopo: null,
    valorContratadoCentavos: params.valorContratoCentavos,
    percentualBps: params.percentualBps,
    modoComissao: "descontada_fornecedor",
    alocadoPlataformaCentavos: params.confirmadoAlocadoCentavos,
    repasseAutorizadoCentavos: 0,
    repasseConfirmadoCentavos: params.repasseConfirmadoCentavos,
    politicaLiberacaoAtiva: params.politicaLiberacaoAtiva,
    estadoExecucao: "nao_iniciado",
  });
  return {
    antesConferencia: {
      nivel: nivelAntes,
      fornecedorCaixaProprioCentavos: 0,
      adminVePendenciaConferencia: nivelAntes === "declarado",
    },
    aposConfirmacao: {
      aPagarClienteCentavos: Math.max(
        0,
        params.valorContratoCentavos - params.confirmadoAlocadoCentavos,
      ),
      fornecedorVeAlocadoComoCaixa: false,
      direitoLiquidoCentavos: direitos.direitoFornecedorPrevistoCentavos,
      saldoPrevistoRepasseCentavos: forn.saldoPrevistoRepasseCentavos,
    },
  };
}

export function acessoCruzadoNegado(params: {
  idFornecedorContrato: string;
  idFornecedorConsulta: string;
  idContratanteContrato: string;
  idClienteConsulta: string;
}): { fornecedorEstranho: boolean; clienteEstranho: boolean } {
  return {
    fornecedorEstranho:
      params.idFornecedorContrato !== params.idFornecedorConsulta,
    clienteEstranho: params.idContratanteContrato !== params.idClienteConsulta,
  };
}
