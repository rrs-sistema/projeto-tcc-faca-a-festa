/**
 * Pesos da IA de recomendação de fornecedores.
 *
 * Modelo híbrido explicável:
 * - compatibilidade com tipo de evento;
 * - compatibilidade de categoria/serviço;
 * - localização e território de atendimento;
 * - reputação do fornecedor;
 * - comportamento/interações do usuário.
 */
export const PESOS_RECOMENDACAO_FORNECEDOR = {
  tipoEventoId: 34,
  tipoEventoSlug: 30,
  tipoEventoNome: 28,
  tipoEventoNaoInformado: 4,
  penalidadeTipoEventoIncompativel: -45,

  categoriaCompativel: 22,
  descricaoCompativel: 6,

  mesmaCidade: 18,
  mesmoEstado: 8,
  dentroRaioAtendimento: 20,
  proximoRaioAtendimento: 8,
  regiaoAtendimentoTexto: 10,

  avaliacaoExcelente: 15,
  avaliacaoBoa: 10,
  avaliacaoPositiva: 5,
  volumeAvaliacoesAlto: 8,
  volumeAvaliacoesMedio: 4,
  fornecedorDestaque: 5,

  limiteInteracaoPositiva: 15,
  limiteInteracaoNegativa: -10,

  scoreMinimoParaExibir: 30,
  scoreMaximo: 100,
};

/**
 * Pesos do aprendizado por comportamento.
 */
export const PESOS_INTERACAO_FORNECEDOR: Record<string, number> = {
  visualizou: 1,
  favoritou: 4,
  reservou: 6,
  pediu_orcamento: 8,
  contratou: 12,
  avaliou_bem: 10,
  dispensou: -8,
  ignorou: -2,
};

export function calcularPesoInteracaoFornecedor(acao: string): number {
  return PESOS_INTERACAO_FORNECEDOR[acao] ?? 0;
}
