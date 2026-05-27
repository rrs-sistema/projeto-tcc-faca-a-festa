export type PrioridadeSugestao = "baixa" | "media" | "alta";

export type TipoSugestao =
  | "economia"
  | "alerta"
  | "melhoria"
  | "excesso"
  | "falta"
  | "planejamento";

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
