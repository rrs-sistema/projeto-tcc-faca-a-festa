export type FirestoreRecord = Record<string, unknown>;

export interface RecomendacaoFornecedoresPayload {
  idEvento: string;

  /**
   * Útil para apresentação/TCC quando existem fornecedores cadastrados
   * sem aprovação completa. Em produção, deixe false/ausente.
   */
  modoDemo?: boolean;

  latitude?: number;
  longitude?: number;

  limite?: number;
}

export interface RegistrarInteracaoFornecedorPayload {
  idEvento: string;
  idFornecedor: string;
  acao: string;
  tipoEventoId?: string | null;
  tipoEventoNome?: string | null;
  tipoEventoSlug?: string | null;
  cidade?: string | null;
}

export interface EventoRecomendacaoContexto {
  idEvento: string;
  idUsuario: string;
  tipoEventoId: string;
  tipoEventoNome: string;
  tipoEventoSlug: string;
  cidade: string;
  estado: string;
  latitude: number | null;
  longitude: number | null;
  categoriasNecessarias: string[];
  palavrasChave: string[];
  raw: FirestoreRecord;
}

export interface FornecedorCandidato {
  idFornecedor: string;
  idUsuario: string;
  razaoSocial: string;
  descricao: string;
  cidade: string;
  estado: string;
  ativo: boolean;
  aptoParaOperar: boolean | null;
  bannerUrl: string | null;
  mediaAvaliacoes: number;
  totalAvaliacoes: number;
  isTopCategoria: boolean;
  categoriasEmbed: FirestoreRecord[];
  tipoEventoIds: string[];
  tipoEventoNomes: string[];
  tipoEventoSlugs: string[];
  raw: FirestoreRecord;
}

export interface FornecedorCategoriaVinculo {
  idFornecedor: string;
  idCategoria: string;
  nomeCategoria: string;
  subcategorias: string[];
  raw: FirestoreRecord;
}

export interface TerritorioFornecedor {
  idTerritorio: string;
  idFornecedor: string;
  latitude: number | null;
  longitude: number | null;
  raioKm: number | null;
  descricao: string;
  ativo: boolean;
  tipoCobertura: string;
  regioes: string[];
  raw: FirestoreRecord;
}

export interface InteracaoFornecedorResumo {
  idFornecedor: string;
  score: number;
  totalInteracoes: number;
  acoes: Record<string, number>;
}

export interface ScoreFornecedorResultado {
  score: number;
  nivel: string;
  nivelLabel: string;
  motivos: string[];
  motivoPrincipal: string;
  distanciaKm: number | null;
  categoriaPrincipal: string | null;
  tipoEventoInformado: boolean;
  tipoEventoCompativel: boolean;
  tipoEventoIncompativel: boolean;
}

export interface FornecedorRecomendacaoResultado {
  id: string;

  // Identificadores em snake_case
  id_evento: string;
  id_usuario: string;
  id_fornecedor: string;

  // Identificadores em camelCase, para compatibilidade com Flutter/Firestore
  eventoId?: string;
  usuarioId?: string;
  fornecedorId?: string;

  // Dados principais do fornecedor
  nome_fornecedor: string;
  nomeFornecedor?: string;

  banner_url: string | null;
  bannerUrl?: string | null;

  categoria_principal: string | null;
  categoriaPrincipal?: string | null;

  // Score / compatibilidade
  score: number;
  nivel: string;

  nivel_label?: string;
  nivelLabel?: string;

  motivo_principal?: string;
  motivoPrincipal?: string;

  compatibilidade_percentual?: number;
  compatibilidadePercentual?: number;

  // Compatibilidade com tipo de evento
  tipo_evento_informado?: boolean;
  tipoEventoInformado?: boolean;

  tipo_evento_compativel?: boolean;
  tipoEventoCompativel?: boolean;

  tipo_evento_incompativel?: boolean;
  tipoEventoIncompativel?: boolean;

  // Tipos de evento vinculados ao fornecedor
  tipo_evento_ids?: string[];
  tipoEventoIds?: string[];

  tipo_evento_slugs?: string[];
  tipoEventoSlugs?: string[];

  tipo_evento_nomes?: string[];
  tipoEventoNomes?: string[];

  // Avaliações
  media_avaliacoes: number;
  mediaAvaliacoes?: number;

  total_avaliacoes: number;
  totalAvaliacoes?: number;

  // Localização
  distancia_km: number | null;
  distanciaKm?: number | null;

  // Motivos explicáveis da IA
  motivos: string[];

  // Datas
  created_at?: unknown;
  createdAt?: unknown;

  updated_at?: unknown;
  updatedAt?: unknown;
}
