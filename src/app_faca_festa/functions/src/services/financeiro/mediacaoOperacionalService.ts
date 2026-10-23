/**
 * Mediação operacional por contratação (Prompt 03).
 * Decisão de caso ≠ efeito financeiro. Nota interna ≠ compartilhável.
 * Bloqueio/recomendação atua só no contrato afetado.
 */

export type EstadoCasoMediacao =
  | "aberto"
  | "em_analise"
  | "aguardando_partes"
  | "em_decisao"
  | "fechado"
  | "cancelado_caso";

export type PrioridadeCaso = "baixa" | "normal" | "alta" | "critica";

export type CategoriaCaso =
  | "divergencia_servico"
  | "pagamento"
  | "reembolso_solicitado"
  | "cancelamento_solicitado"
  | "identificacao"
  | "outro";

export type VisibilidadeRegistro = "interna" | "compartilhavel";

export type TipoRegistroMediacao =
  | "abertura"
  | "analise"
  | "nota_interna"
  | "info_compartilhavel"
  | "solicitacao_info"
  | "atribuicao"
  | "decisao"
  | "recomendacao_bloqueio"
  | "fechamento";

/** Pedido de reembolso / cancelamento ≠ decisão ≠ efeito financeiro. */
export type TipoDecisaoMediacao =
  | "manter"
  | "recomendar_reembolso"
  | "recomendar_cancelamento"
  | "recomendar_repasse"
  | "encaminhar"
  | "arquivar";

export type CapacidadeMediacao =
  | "consulta_comercial"
  | "notas_internas"
  | "decisao_mediacao"
  | "autorizacao_financeira";

export type PapelConsultaMediacao = "admin" | "cliente" | "fornecedor";

export type RegistroMediacao = {
  id: string;
  idCaso: string;
  tipo: TipoRegistroMediacao;
  visibilidade: VisibilidadeRegistro;
  texto: string;
  autorId: string;
  criadoEm: string;
  tipoDecisao?: TipoDecisaoMediacao | null;
  /** Referências a comandos financeiros autorizados — não altera saldo sozinho. */
  referenciasComandos?: string[];
  efeitoFinanceiroExecutado: boolean;
};

export type CasoMediacao = {
  id: string;
  idEvento: string;
  idContrato: string;
  idOrcamento: string;
  idFornecedor: string | null;
  idContratante: string | null;
  categoria: CategoriaCaso;
  motivo: string;
  descricao: string;
  prioridade: PrioridadeCaso;
  estado: EstadoCasoMediacao;
  idResponsavel: string | null;
  abertoPorId: string;
  abertoEm: string;
  fechadoEm: string | null;
  conclusao: string | null;
  /** Recomendação de revisão no contrato — sem retenção automática se política ausente. */
  recomendacaoBloqueioAtiva: boolean;
  motivoRecomendacaoBloqueio: string | null;
  /** Retenção efetiva só se política explícita existir (nesta entrega: nunca auto). */
  retencaoEfetivaAtiva: boolean;
};

export type DimensoesFinanceirasContrato = {
  valorContratadoCentavos: number;
  /** Recebido do cliente pela plataforma e alocado a este contrato. */
  recebidoClienteAlocadoCentavos: number;
  /** Ainda a receber do cliente (contrato − alocado), nunca negativo. */
  aReceberClienteCentavos: number;
  repassadoConfirmadoCentavos: number;
  /** Direito/previsto fornecedor ainda não confirmado como repasse. */
  pendenteRepasseCentavos: number;
  remuneracaoAppPrevistaCentavos: number;
};

export type LinhaCentralContratacao = {
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  nomeEvento: string | null;
  dataEvento: string | null;
  nomeContratante: string | null;
  nomeFornecedor: string | null;
  nomeServico: string | null;
  escopoCurto: string | null;
  valorContratadoCentavos: number;
  recebidoClienteCentavos: number;
  repassadoCentavos: number;
  /** Saldos separados — não somar cliente + fornecedor. */
  aReceberClienteCentavos: number;
  pendenteRepasseCentavos: number;
  estadoComercial: string;
  estadoExecucao: string;
  casoAberto: boolean;
  idCasoAberto: string | null;
  pendencias: string[];
  identidadeIncompleta: boolean;
};

export function capacidadesParaTipoUsuario(tipo: string): CapacidadeMediacao[] {
  if (tipo === "A") {
    return [
      "consulta_comercial",
      "notas_internas",
      "decisao_mediacao",
      "autorizacao_financeira",
    ];
  }
  // Cliente/fornecedor: só consulta do próprio vínculo via callable filtrado.
  return ["consulta_comercial"];
}

export function temCapacidade(
  caps: CapacidadeMediacao[],
  requerida: CapacidadeMediacao,
): boolean {
  return caps.includes(requerida);
}

export function visibilidadeObrigatoriaDoTipo(
  tipo: TipoRegistroMediacao,
): VisibilidadeRegistro {
  if (tipo === "nota_interna" || tipo === "recomendacao_bloqueio") {
    return "interna";
  }
  if (tipo === "info_compartilhavel" || tipo === "solicitacao_info") {
    return "compartilhavel";
  }
  // abertura/análise/atribuição/decisão/fechamento: default interno;
  // decisão pode marcar compartilhável explicitamente no registro.
  return "interna";
}

export function filtrarRegistrosPorPapel(
  registros: RegistroMediacao[],
  papel: PapelConsultaMediacao,
  caps: CapacidadeMediacao[],
): RegistroMediacao[] {
  if (papel === "admin" && temCapacidade(caps, "notas_internas")) {
    return [...registros];
  }
  return registros.filter((r) => r.visibilidade === "compartilhavel");
}

/** Exportação/anexo: nunca inclui nota interna. */
export function registrosParaExportacao(
  registros: RegistroMediacao[],
): RegistroMediacao[] {
  return registros.filter((r) => r.visibilidade === "compartilhavel");
}

export function podeAbrirCaso(params: {
  idContrato: string;
  idEvento: string;
  casosAbertosNoContrato: number;
}): { ok: true } | { ok: false; motivo: string } {
  if (!params.idContrato || !params.idEvento) {
    return { ok: false, motivo: "Contrato e evento são obrigatórios." };
  }
  if (params.casosAbertosNoContrato > 0) {
    return {
      ok: false,
      motivo: "Já existe caso aberto neste contrato.",
    };
  }
  return { ok: true };
}

/**
 * Bloqueio/recomendação só no contrato afetado — não propaga ao evento.
 */
export function escopoBloqueioRevisao(params: {
  idContratoAlvo: string;
  idsContratosDoEvento: string[];
}): { contratosAfetados: string[]; naoAfetados: string[] } {
  const alvo = params.idContratoAlvo;
  const afetados = params.idsContratosDoEvento.filter((id) => id === alvo);
  const naoAfetados = params.idsContratosDoEvento.filter((id) => id !== alvo);
  return { contratosAfetados: afetados, naoAfetados };
}

export function aplicarRecomendacaoBloqueio(params: {
  caso: CasoMediacao;
  motivo: string;
  /** Política de retenção operacional definida? Nesta entrega: false. */
  politicaRetencaoAtiva: boolean;
  temCapacidadeAutorizacao: boolean;
}): {
  caso: CasoMediacao;
  retencaoAplicada: boolean;
  somenteRecomendacao: boolean;
} {
  if (!params.temCapacidadeAutorizacao) {
    throw new Error("Sem capacidade de autorização financeira.");
  }
  const motivo = params.motivo.trim();
  if (!motivo) {
    throw new Error("Informe o motivo da revisão.");
  }
  const retencao = params.politicaRetencaoAtiva === true;
  return {
    caso: {
      ...params.caso,
      recomendacaoBloqueioAtiva: true,
      motivoRecomendacaoBloqueio: motivo,
      retencaoEfetivaAtiva: retencao,
    },
    retencaoAplicada: retencao,
    somenteRecomendacao: !retencao,
  };
}

export function registrarDecisaoSemEfeitoFinanceiro(params: {
  caso: CasoMediacao;
  tipoDecisao: TipoDecisaoMediacao;
  texto: string;
  autorId: string;
  agoraIso: string;
  referenciasComandos?: string[];
  compartilharComPartes?: boolean;
}): { caso: CasoMediacao; registro: Omit<RegistroMediacao, "id"> } {
  if (!temCapacidade(capacidadesParaTipoUsuario("A"), "decisao_mediacao")) {
    // Capacidade checada no callable; aqui só monta o fato.
  }
  const estado: EstadoCasoMediacao =
    params.tipoDecisao === "arquivar" ? "fechado" : "em_decisao";
  return {
    caso: {
      ...params.caso,
      estado,
      fechadoEm:
        estado === "fechado" ? params.agoraIso : params.caso.fechadoEm,
      conclusao:
        estado === "fechado"
          ? params.texto
          : params.caso.conclusao,
    },
    registro: {
      idCaso: params.caso.id,
      tipo: "decisao",
      visibilidade: params.compartilharComPartes
        ? "compartilhavel"
        : "interna",
      texto: params.texto,
      autorId: params.autorId,
      criadoEm: params.agoraIso,
      tipoDecisao: params.tipoDecisao,
      referenciasComandos: params.referenciasComandos ?? [],
      efeitoFinanceiroExecutado: false,
    },
  };
}

export function fecharCasoSemMovimentoFinanceiro(params: {
  caso: CasoMediacao;
  conclusao: string;
  autorId: string;
  agoraIso: string;
}): { caso: CasoMediacao; registro: Omit<RegistroMediacao, "id">; efeitosFinanceiros: [] } {
  const conclusao = params.conclusao.trim();
  if (!conclusao) {
    throw new Error("Informe a conclusão ao fechar o caso.");
  }
  return {
    caso: {
      ...params.caso,
      estado: "fechado",
      fechadoEm: params.agoraIso,
      conclusao,
    },
    registro: {
      idCaso: params.caso.id,
      tipo: "fechamento",
      visibilidade: "interna",
      texto: conclusao,
      autorId: params.autorId,
      criadoEm: params.agoraIso,
      efeitoFinanceiroExecutado: false,
    },
    /** Explicitamente vazio: fechar ≠ reembolso/repasse. */
    efeitosFinanceiros: [],
  };
}

export function calcularDimensoesFinanceiras(params: {
  valorContratadoCentavos: number;
  recebidoAlocadoCentavos: number;
  repassadoConfirmadoCentavos: number;
  remuneracaoAppPrevistaCentavos?: number;
}): DimensoesFinanceirasContrato {
  const valor = Math.max(0, params.valorContratadoCentavos);
  const recebido = Math.max(0, params.recebidoAlocadoCentavos);
  const repassado = Math.max(0, params.repassadoConfirmadoCentavos);
  const aReceber = Math.max(0, valor - recebido);
  const pendenteRepasse = Math.max(0, recebido - repassado);
  return {
    valorContratadoCentavos: valor,
    recebidoClienteAlocadoCentavos: recebido,
    aReceberClienteCentavos: aReceber,
    repassadoConfirmadoCentavos: repassado,
    pendenteRepasseCentavos: pendenteRepasse,
    remuneracaoAppPrevistaCentavos: Math.max(
      0,
      params.remuneracaoAppPrevistaCentavos ?? 0,
    ),
  };
}

export function montarLinhaCentral(params: {
  idContrato: string;
  idOrcamento: string;
  idEvento: string;
  nomeEvento: string | null;
  dataEvento: string | null;
  nomeContratante: string | null;
  nomeFornecedor: string | null;
  nomeServico: string | null;
  escopoCurto: string | null;
  estadoComercial: string;
  estadoExecucao: string;
  identidadeIncompleta: boolean;
  pendenciasIdentificacao: string[];
  financeiro: DimensoesFinanceirasContrato;
  casoAberto: CasoMediacao | null;
}): LinhaCentralContratacao {
  const pendencias = [...params.pendenciasIdentificacao];
  if (params.financeiro.aReceberClienteCentavos > 0) {
    pendencias.push("financeiro_cliente");
  }
  if (params.casoAberto) {
    pendencias.push("caso_mediacao_aberto");
  }
  if (params.financeiro.pendenteRepasseCentavos > 0) {
    pendencias.push("repasse_pendente");
  }
  return {
    idContrato: params.idContrato,
    idOrcamento: params.idOrcamento,
    idEvento: params.idEvento,
    nomeEvento: params.nomeEvento,
    dataEvento: params.dataEvento,
    nomeContratante: params.nomeContratante,
    nomeFornecedor: params.nomeFornecedor,
    nomeServico: params.nomeServico,
    escopoCurto: params.escopoCurto,
    valorContratadoCentavos: params.financeiro.valorContratadoCentavos,
    recebidoClienteCentavos: params.financeiro.recebidoClienteAlocadoCentavos,
    repassadoCentavos: params.financeiro.repassadoConfirmadoCentavos,
    aReceberClienteCentavos: params.financeiro.aReceberClienteCentavos,
    pendenteRepasseCentavos: params.financeiro.pendenteRepasseCentavos,
    estadoComercial: params.estadoComercial,
    estadoExecucao: params.estadoExecucao,
    casoAberto: params.casoAberto != null,
    idCasoAberto: params.casoAberto?.id ?? null,
    pendencias,
    identidadeIncompleta: params.identidadeIncompleta,
  };
}

export function casoPertenceAoVinculo(params: {
  caso: CasoMediacao;
  papel: PapelConsultaMediacao;
  uid: string;
  idFornecedorOperador?: string | null;
}): boolean {
  if (params.papel === "admin") return true;
  if (params.papel === "cliente") {
    return params.caso.idContratante === params.uid;
  }
  if (params.papel === "fornecedor") {
    return (
      !!params.idFornecedorOperador &&
      params.caso.idFornecedor === params.idFornecedorOperador
    );
  }
  return false;
}

export function rotuloCategoria(c: CategoriaCaso): string {
  switch (c) {
    case "divergencia_servico":
      return "Divergência de serviço";
    case "pagamento":
      return "Pagamento";
    case "reembolso_solicitado":
      return "Pedido de reembolso";
    case "cancelamento_solicitado":
      return "Solicitação de cancelamento";
    case "identificacao":
      return "Identificação";
    default:
      return "Outro";
  }
}

export function rotuloEstadoCaso(e: EstadoCasoMediacao): string {
  switch (e) {
    case "aberto":
      return "Aberto";
    case "em_analise":
      return "Em análise";
    case "aguardando_partes":
      return "Aguardando partes";
    case "em_decisao":
      return "Em decisão";
    case "fechado":
      return "Fechado";
    case "cancelado_caso":
      return "Caso cancelado";
    default:
      return e;
  }
}
