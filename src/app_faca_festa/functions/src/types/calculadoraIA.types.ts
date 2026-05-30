export type PrioridadeSugestao = "baixa" | "media" | "alta";

export type PrioridadeSugestaoBase = PrioridadeSugestao | "critica";

export type TipoSugestao =
  | "economia"
  | "alerta"
  | "melhoria"
  | "excesso"
  | "falta"
  | "planejamento";

export interface CalculadoraIAItemRequest {
  id_item_resultado?: string;
  idItemResultado?: string;
  nome?: string;
  categoria?: string;
  tipo_item?: string;
  tipoItem?: string;
  publico_alvo?: string;
  publicoAlvo?: string;
  unidade?: string;
  quantidade?: number;
  quantidade_por_convidado_equivalente?: number;
  quantidadePorConvidadoEquivalente?: number;
  valor_unitario_medio?: number;
  valorUnitarioMedio?: number;
  custo_estimado?: number;
  custoEstimado?: number;
  regra_aplicada?: string;
  regraAplicada?: string;
  [key: string]: unknown;
}

export interface CalculadoraIARequest {
  id?: string;
  id_calculo?: string;
  idCalculo?: string;
  id_evento?: string;
  idEvento?: string;
  id_usuario?: string;
  idUsuario?: string;
  nome_evento?: string;
  nomeEvento?: string;
  tipo_evento?: string;
  tipoEvento?: string;
  perfil_festa?: string;
  perfilFesta?: string;
  perfil_festa_tipo?: string;
  perfilFestaTipo?: string;
  base_calculo?: string;
  baseCalculo?: string;
  adultos?: number;
  criancas?: number;
  crianças?: number;
  bebes?: number;
  bebês?: number;
  total_informado?: number;
  totalInformado?: number;
  total_convidados?: number;
  totalConvidados?: number;
  total_equivalente?: number;
  totalEquivalente?: number;
  convidados_equivalentes?: number;
  convidadosEquivalentes?: number;
  total_equivalente_arredondado?: number;
  totalEquivalenteArredondado?: number;
  duracao_horas?: number;
  duracaoHoras?: number;
  margem?: number;
  orcamento_disponivel?: number | null;
  orcamentoDisponivel?: number | null;
  custo_total_estimado?: number;
  custoTotalEstimado?: number;
  custo_estimado?: number;
  custoEstimado?: number;
  diferenca_orcamento?: number;
  diferencaOrcamento?: number;
  itens?: CalculadoraIAItemRequest[];
  itens_calculados?: CalculadoraIAItemRequest[];
  itensCalculados?: CalculadoraIAItemRequest[];
  [key: string]: unknown;
}

export interface SugestaoBaseIA {
  id: string;
  titulo: string;
  descricao: string;
  modulo: string;
  tema: string;
  tipo_evento: string[];
  perfis_festa: string[];
  categoria: string;
  prioridade: string;
  gatilhos: Record<string, unknown>;
  tags: string[];
  ativo: boolean;
  excluido: boolean;
  ordem: number;

  /** Versão editorial da sugestão base usada para auditoria. */
  versao: number;

  /** Origem do cadastro: seed_inicial, admin, migracao, importacao, etc. */
  origem: string;

  /** Responsável pela última revisão/aprovação. */
  revisado_por: string;

  /** Datas normalizadas em ISO-8601 quando existirem. */
  data_revisao: string | null;
  data_publicacao: string | null;

  /** Status editorial. Apenas sugestões aprovadas/publicadas entram como contexto. */
  status_revisao: string;
  observacao_revisao: string;
}

export type FonteAnaliseCalculadoraIA = "ia_generativa" | "fallback_local" | "local";

export interface SugestaoCalculadoraIAResponse {
  id: string;
  titulo: string;
  descricao: string;
  tipo: "economia" | "alerta" | "melhoria" | "excesso" | "falta" | "planejamento";
  prioridade: "baixa" | "media" | "alta";
  item_relacionado: string | null;
  impacto_estimado: number;
}

export interface AnaliseCalculadoraIAResponse {
  titulo: string;
  resumo: string;
  indice_economia: number;
  indice_risco_faltar_itens: number;
  indice_conforto: number;
  custo_total_estimado: number;
  orcamento_disponivel: number | null;
  diferenca_orcamento: number;
  data_analise: string;
  sugestoes: SugestaoCalculadoraIAResponse[];
  diagnostico_financeiro: string;
  diagnostico_consumo: string;
  recomendacao_final: string;
  pontos_de_atencao: string[];
  proximas_acoes: string[];
  fonte: FonteAnaliseCalculadoraIA;
  versao_schema: string;

  /** Rastreabilidade técnica/editorial preenchida pela Cloud Function. */
  nome_prompt: string;
  versao_prompt: string;
  ids_sugestoes_base_utilizadas: string[];
  versoes_sugestoes_base_utilizadas: Record<string, number>;
  total_sugestoes_base_utilizadas: number;
  modelo_ia_utilizado: string;
  data_processamento: string;

  [key: string]: unknown;
}

/*
export type PrioridadeSugestao = "baixa" | "media" | "alta";

export type PrioridadeSugestaoBase = PrioridadeSugestao | "critica";

export type TipoSugestao =
  | "economia"
  | "alerta"
  | "melhoria"
  | "excesso"
  | "falta"
  | "planejamento";

export type CategoriaSugestaoBase =
  | "alerta"
  | "economia"
  | "consumo"
  | "financeiro"
  | "organizacao"
  | "fornecedor"
  | "cardapio"
  | "decoracao"
  | "geral";

export interface ItemCalculadoraIARequest {
  id_item_resultado?: string;
  nome: string;
  categoria: string;
  tipo_item?: string;
  publico_alvo?: string;
  unidade?: string;
  quantidade?: number;
  quantidade_por_convidado_equivalente?: number;
  valor_unitario_medio?: number;
  custo_estimado?: number;
  regra_aplicada?: string;
}

export interface CalculadoraIARequest {
  id_calculo?: string;
  id_evento?: string;
  id_usuario?: string;
  nome_evento?: string;
  tipo_evento?: string;
  perfil_festa?: string;
  perfil_festa_tipo?: string;
  adultos?: number;
  criancas?: number;
  bebes?: number;
  total_informado?: number;
  total_equivalente?: number;
  total_equivalente_arredondado?: number;
  duracao_horas?: number;
  margem?: number;
  orcamento_disponivel?: number | null;
  custo_total_estimado?: number;
  itens?: ItemCalculadoraIARequest[];
}

export interface SugestaoCalculadoraIAResponse {
  id: string;
  titulo: string;
  descricao: string;
  tipo: TipoSugestao;
  prioridade: PrioridadeSugestao;
  item_relacionado: string | null;
  impacto_estimado: number;
}

export interface AnaliseCalculadoraIAResponse {
  titulo: string;
  resumo: string;
  indice_economia: number;
  indice_risco_faltar_itens: number;
  indice_conforto: number;
  custo_total_estimado: number;
  orcamento_disponivel: number | null;
  diferenca_orcamento: number;
  data_analise: string;
  sugestoes: SugestaoCalculadoraIAResponse[];
  diagnostico_financeiro: string;
  diagnostico_consumo: string;
  recomendacao_final: string;
  pontos_de_atencao: string[];
  proximas_acoes: string[];
  fonte: "ia_generativa" | "fallback_local";
  versao_schema: string;
}

export interface SugestaoBaseIA {
  id: string;
  titulo: string;
  descricao: string;
  modulo: string;
  tema: string;
  tipo_evento: string[];
  perfis_festa: string[];
  categoria: CategoriaSugestaoBase | string;
  prioridade: PrioridadeSugestaoBase | string;
  gatilhos: Record<string, unknown>;
  tags: string[];
  ativo: boolean;
  ordem: number;
}
*/
