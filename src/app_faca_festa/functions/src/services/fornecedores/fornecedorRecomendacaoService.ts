import { HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import {
  EventoRecomendacaoContexto,
  FirestoreRecord,
  FornecedorCandidato,
  FornecedorCategoriaVinculo,
  FornecedorRecomendacaoResultado,
  InteracaoFornecedorResumo,
  RecomendacaoFornecedoresPayload,
  TerritorioFornecedor,
} from "../../types/fornecedorRecomendacao.types";
import { calcularScoreFornecedor, normalizarSlug, normalizarTexto } from "./fornecedorScoreService";
import { calcularPesoInteracaoFornecedor, PESOS_RECOMENDACAO_FORNECEDOR } from "../../ia/fornecedores/recomendacao/pesos";

const COLLECTION_FORNECEDORES = "fornecedor";
const COLLECTION_FORNECEDOR_CATEGORIA = "fornecedor_categoria";
const COLLECTION_TERRITORIO = "territorio";
const COLLECTION_INTERACOES = "fornecedor_interacoes";
const COLLECTION_RECOMENDACOES = "fornecedor_recomendacoes";
const COLLECTION_AVALIACOES_GERAL = "fornecedor_avaliacoes";

export async function recomendarFornecedoresParaEventoService(params: {
  uid: string;
  payload: RecomendacaoFornecedoresPayload;
}): Promise<FornecedorRecomendacaoResultado[]> {
  const { uid, payload } = params;
  const eventoEncontrado = await buscarEventoPorId(payload.idEvento);

  if (!eventoEncontrado) {
    throw new HttpsError(
      "not-found",
      `Evento não encontrado para o id informado: ${payload.idEvento}`,
    );
  }

  const evento = montarEventoContexto({
    idEvento: eventoEncontrado.idEvento,
    idUsuario: uid,
    raw: eventoEncontrado.data,
    latitudePayload: payload.latitude,
    longitudePayload: payload.longitude,
  });

  const [fornecedoresBase, vinculos, territorios, interacoes] = await Promise.all([
    buscarFornecedoresCandidatos(payload.modoDemo === true),
    buscarVinculosCategorias(),
    buscarTerritorios(),
    buscarInteracoesUsuario(uid),
  ]);

  const resumosAvaliacoes = await buscarResumoAvaliacoesFornecedores(
    fornecedoresBase.map((fornecedor) => fornecedor.idFornecedor),
  );

  const fornecedores = aplicarResumoAvaliacoes(fornecedoresBase, resumosAvaliacoes);

  const vinculosPorFornecedor = agruparPor(vinculos, (vinculo) => vinculo.idFornecedor);
  const territoriosPorFornecedor = new Map<string, TerritorioFornecedor>();
  const interacoesPorFornecedor = new Map<string, InteracaoFornecedorResumo>();

  for (const territorio of territorios) {
    territoriosPorFornecedor.set(territorio.idFornecedor, territorio);
  }

  for (const interacao of interacoes) {
    interacoesPorFornecedor.set(interacao.idFornecedor, interacao);
  }

  const recomendacoes: FornecedorRecomendacaoResultado[] = [];

  for (const fornecedor of fornecedores) {
    const score = calcularScoreFornecedor({
      evento,
      fornecedor,
      categoriasFornecedor: vinculosPorFornecedor.get(fornecedor.idFornecedor) ?? [],
      territorio: territoriosPorFornecedor.get(fornecedor.idFornecedor),
      interacao: interacoesPorFornecedor.get(fornecedor.idFornecedor),
    });

    // Regra central da IA: se o fornecedor informou tipos de evento e o tipo não
    // combina com o evento atual, ele não deve aparecer nem em modo demo.
    if (score.tipoEventoIncompativel) {
      continue;
    }

    if (score.score < PESOS_RECOMENDACAO_FORNECEDOR.scoreMinimoParaExibir) {
      continue;
    }

    recomendacoes.push({
      id: `${payload.idEvento}_${fornecedor.idFornecedor}`,

      // Campos em camelCase: padrão usado pelo app Flutter atual.
      eventoId: payload.idEvento,
      usuarioId: uid,
      fornecedorId: fornecedor.idFornecedor,
      nomeFornecedor: fornecedor.razaoSocial,
      bannerUrl: fornecedor.bannerUrl,
      categoriaPrincipal: score.categoriaPrincipal,
      score: score.score,
      nivel: score.nivel,
      nivelLabel: score.nivelLabel,
      motivoPrincipal: score.motivoPrincipal,
      compatibilidadePercentual: score.score,
      tipoEventoInformado: score.tipoEventoInformado,
      tipoEventoCompativel: score.tipoEventoCompativel,
      tipoEventoIncompativel: score.tipoEventoIncompativel,
      mediaAvaliacoes: fornecedor.mediaAvaliacoes,
      totalAvaliacoes: fornecedor.totalAvaliacoes,
      distanciaKm: score.distanciaKm,

      // Campos em snake_case: compatibilidade com documentos/consultas antigas.
      id_evento: payload.idEvento,
      id_usuario: uid,
      id_fornecedor: fornecedor.idFornecedor,
      nome_fornecedor: fornecedor.razaoSocial,
      banner_url: fornecedor.bannerUrl,
      categoria_principal: score.categoriaPrincipal,
      nivel_label: score.nivelLabel,
      motivo_principal: score.motivoPrincipal,
      compatibilidade_percentual: score.score,
      tipo_evento_informado: score.tipoEventoInformado,
      tipo_evento_compativel: score.tipoEventoCompativel,
      tipo_evento_incompativel: score.tipoEventoIncompativel,
      media_avaliacoes: fornecedor.mediaAvaliacoes,
      total_avaliacoes: fornecedor.totalAvaliacoes,
      distancia_km: score.distanciaKm,

      motivos: score.motivos,
    });
  }

  recomendacoes.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    if (b.media_avaliacoes !== a.media_avaliacoes) return b.media_avaliacoes - a.media_avaliacoes;
    return b.total_avaliacoes - a.total_avaliacoes;
  });

  const limite = Math.max(1, Math.min(Number(payload.limite ?? 10), 20));
  const melhores = recomendacoes.slice(0, limite);

  await salvarCacheRecomendacoes(melhores);

  return melhores;
}

async function buscarEventoPorId(idEvento: string): Promise<{
  idEvento: string;
  collectionName: string;
  documentId: string;
  data: FirestoreRecord;
} | null> {
  const db = admin.firestore();
  const colecoesPossiveis = ["evento", "eventos"];

  for (const collectionName of colecoesPossiveis) {
    const docSnap = await db.collection(collectionName).doc(idEvento).get();

    if (docSnap.exists) {
      return {
        idEvento: asString(docSnap.data()?.eventoId ?? docSnap.data()?.idEvento ?? docSnap.id),
        collectionName,
        documentId: docSnap.id,
        data: docSnap.data() ?? {},
      };
    }
  }

  const camposPossiveis = ["eventoId", "idEvento", "id_evento", "id", "documentId"];

  for (const collectionName of colecoesPossiveis) {
    for (const campo of camposPossiveis) {
      const querySnap = await db
        .collection(collectionName)
        .where(campo, "==", idEvento)
        .limit(1)
        .get();

      if (!querySnap.empty) {
        const doc = querySnap.docs[0];
        const data = doc.data() ?? {};

        return {
          idEvento: asString(data.eventoId ?? data.idEvento ?? data.id_evento ?? doc.id),
          collectionName,
          documentId: doc.id,
          data,
        };
      }
    }
  }

  return null;
}

function montarEventoContexto(params: {
  idEvento: string;
  idUsuario: string;
  raw: FirestoreRecord;
  latitudePayload?: number;
  longitudePayload?: number;
}): EventoRecomendacaoContexto {
  const { idEvento, idUsuario, raw, latitudePayload, longitudePayload } = params;

  const tipoEventoNome = asString(
    raw.tipoEventoNome ??
    raw.tipo_evento_nome ??
    raw.nomeTipoEvento ??
    raw.nome_tipo_evento ??
    raw.tipoEvento ??
    raw.tipo_evento,
  );

  const tipoEventoSlug = asString(
    raw.tipoEventoSlug ??
    raw.tipo_evento_slug ??
    raw.tipoEventoNormalizado ??
    raw.tipo_evento_normalizado ??
    normalizarSlug(tipoEventoNome),
  );

  const categoriasNecessarias = asStringArray(
    raw.categoriasNecessarias ??
    raw.categorias_necessarias ??
    raw.categorias ??
    raw.itensOrcamentoCategorias ??
    raw.itens_orcamento_categorias,
  );

  const palavrasChave = removerDuplicados([
    tipoEventoNome,
    tipoEventoSlug,
    normalizarTexto(tipoEventoNome),
    normalizarSlug(tipoEventoNome),
    ...categoriasNecessarias,
    ...asStringArray(raw.palavrasChave ?? raw.palavras_chave),
  ]);

  return {
    idEvento,
    idUsuario,
    tipoEventoId: asString(raw.tipoEventoId ?? raw.idTipoEvento ?? raw.id_tipo_evento ?? raw.tipo_evento_id),
    tipoEventoNome,
    tipoEventoSlug,
    cidade: asString(raw.cidade ?? raw.cidadeEvento ?? raw.cidade_evento),
    estado: asString(raw.estado ?? raw.uf ?? raw.estadoEvento ?? raw.estado_evento),
    latitude: asNullableNumber(latitudePayload ?? raw.latitude ?? raw.latitude_evento),
    longitude: asNullableNumber(longitudePayload ?? raw.longitude ?? raw.longitude_evento),
    categoriasNecessarias,
    palavrasChave,
    raw,
  };
}

async function buscarFornecedoresCandidatos(modoDemo: boolean): Promise<FornecedorCandidato[]> {
  const db = admin.firestore();
  const snapshot = await db
    .collection(COLLECTION_FORNECEDORES)
    .where("ativo", "==", true)
    .get();

  return snapshot.docs
    .map((doc) => montarFornecedorCandidato(doc.id, doc.data() ?? {}))
    .filter((fornecedor) => {
      if (fornecedor.ativo === false) return false;
      if (modoDemo) return true;
      return fornecedor.aptoParaOperar !== false;
    });
}

function montarFornecedorCandidato(documentId: string, raw: FirestoreRecord): FornecedorCandidato {
  return {
    idFornecedor: asString(raw.id_fornecedor ?? raw.idFornecedor ?? raw.fornecedorId ?? documentId),
    idUsuario: asString(raw.id_usuario ?? raw.idUsuario ?? raw.usuarioId),
    razaoSocial: asString(raw.razao_social ?? raw.razaoSocial ?? raw.nome ?? raw.nomeFornecedor, "Fornecedor"),
    descricao: asString(raw.descricao ?? raw.descricao_servico ?? raw.bio),
    cidade: asString(raw.cidade ?? raw.cidade_atendimento ?? raw.cidadeAtendimento),
    estado: asString(raw.estado ?? raw.uf ?? raw.estado_atendimento ?? raw.estadoAtendimento),
    ativo: asBoolean(raw.ativo, true),
    aptoParaOperar: raw.apto_para_operar === undefined && raw.aptoParaOperar === undefined
      ? null
      : asBoolean(raw.apto_para_operar ?? raw.aptoParaOperar, false),
    bannerUrl: asNullableString(raw.banner_url ?? raw.bannerUrl ?? raw.logo_url ?? raw.logoUrl),
    mediaAvaliacoes: asNumber(raw.media_avaliacoes ?? raw.mediaAvaliacoes),
    totalAvaliacoes: asInt(raw.total_avaliacoes ?? raw.totalAvaliacoes),
    isTopCategoria: asBoolean(raw.is_top_categoria ?? raw.isTopCategoria, false),
    categoriasEmbed: Array.isArray(raw.categorias) ? raw.categorias.filter(isRecord) : [],
    tipoEventoIds: asStringArray(raw.tipo_evento_ids ?? raw.tipoEventoIds),
    tipoEventoNomes: asStringArray(raw.tipo_evento_nomes ?? raw.tipoEventoNomes),
    tipoEventoSlugs: asStringArray(raw.tipo_evento_slugs ?? raw.tipoEventoSlugs),
    raw,
  };
}

type ResumoAvaliacoesFornecedor = {
  fornecedorId: string;
  mediaAvaliacoes: number;
  totalAvaliacoes: number;
};

function aplicarResumoAvaliacoes(
  fornecedores: FornecedorCandidato[],
  resumos: Map<string, ResumoAvaliacoesFornecedor>,
): FornecedorCandidato[] {
  return fornecedores.map((fornecedor) => {
    const resumo = resumos.get(fornecedor.idFornecedor);

    if (!resumo || resumo.totalAvaliacoes <= 0) {
      return fornecedor;
    }

    return {
      ...fornecedor,
      mediaAvaliacoes: resumo.mediaAvaliacoes,
      totalAvaliacoes: resumo.totalAvaliacoes,
      raw: {
        ...fornecedor.raw,
        mediaAvaliacoes: resumo.mediaAvaliacoes,
        media_avaliacoes: resumo.mediaAvaliacoes,
        totalAvaliacoes: resumo.totalAvaliacoes,
        total_avaliacoes: resumo.totalAvaliacoes,
      },
    };
  });
}

async function buscarResumoAvaliacoesFornecedores(
  fornecedorIds: string[],
): Promise<Map<string, ResumoAvaliacoesFornecedor>> {
  const ids = removerDuplicados(
    fornecedorIds
      .map((id) => asString(id))
      .filter((id) => id.length > 0),
  );

  const notasPorFornecedor = new Map<string, number[]>();

  if (ids.length === 0) {
    return new Map();
  }

  await Promise.all([
    carregarAvaliacoesColecaoGeral(ids, notasPorFornecedor),
    carregarAvaliacoesSubcolecoesFornecedores(ids, notasPorFornecedor),
  ]);

  const resumos = new Map<string, ResumoAvaliacoesFornecedor>();

  for (const [fornecedorId, notas] of notasPorFornecedor.entries()) {
    const notasValidas = notas.filter(
      (nota) => Number.isFinite(nota) && nota >= 0 && nota <= 5,
    );

    if (notasValidas.length === 0) {
      continue;
    }

    const soma = notasValidas.reduce((total, nota) => total + nota, 0);
    const media = Number((soma / notasValidas.length).toFixed(2));

    resumos.set(fornecedorId, {
      fornecedorId,
      mediaAvaliacoes: media,
      totalAvaliacoes: notasValidas.length,
    });
  }

  return resumos;
}

async function carregarAvaliacoesColecaoGeral(
  fornecedorIds: string[],
  notasPorFornecedor: Map<string, number[]>,
): Promise<void> {
  const db = admin.firestore();
  const camposFornecedor = ["fornecedorId", "idFornecedor", "id_fornecedor"];

  for (const campo of camposFornecedor) {
    for (const bloco of dividirEmBlocos(fornecedorIds, 30)) {
      try {
        const snapshot = await db
          .collection(COLLECTION_AVALIACOES_GERAL)
          .where(campo, "in", bloco)
          .get();

        for (const doc of snapshot.docs) {
          const raw = doc.data() ?? {};
          const fornecedorId = asString(raw.fornecedorId ?? raw.idFornecedor ?? raw.id_fornecedor);
          const nota = asNullableNumber(raw.nota ?? raw.rating ?? raw.avaliacao);

          adicionarNotaFornecedor(notasPorFornecedor, fornecedorId, nota);
        }
      } catch (error) {
        console.warn(
          `[FornecedorRecomendacao] Falha ao consultar ${COLLECTION_AVALIACOES_GERAL} pelo campo ${campo}:`,
          error,
        );
      }
    }
  }
}

async function carregarAvaliacoesSubcolecoesFornecedores(
  fornecedorIds: string[],
  notasPorFornecedor: Map<string, number[]>,
): Promise<void> {

  await Promise.all(
    fornecedorIds.map(async (fornecedorId) => {
      try {
        const fornecedorDoc = await buscarFornecedorDocumentoPorId(fornecedorId);

        if (!fornecedorDoc || !fornecedorDoc.exists) {
          return;
        }

        const snapshot = await fornecedorDoc.ref.collection("avaliacoes").get();

        for (const doc of snapshot.docs) {
          const raw = doc.data() ?? {};
          const idNoDocumento = asString(raw.fornecedorId ?? raw.idFornecedor ?? raw.id_fornecedor);
          const idResolvido = idNoDocumento || fornecedorId;
          const nota = asNullableNumber(raw.nota ?? raw.rating ?? raw.avaliacao);

          adicionarNotaFornecedor(notasPorFornecedor, idResolvido, nota);
        }
      } catch (error) {
        console.warn(
          `[FornecedorRecomendacao] Falha ao consultar subcoleção avaliacoes do fornecedor ${fornecedorId}:`,
          error,
        );
      }
    }),
  );
}

async function buscarFornecedorDocumentoPorId(
  fornecedorId: string,
): Promise<FirebaseFirestore.DocumentSnapshot | null> {
  const db = admin.firestore();
  const docDireto = await db.collection(COLLECTION_FORNECEDORES).doc(fornecedorId).get();

  if (docDireto.exists) {
    return docDireto;
  }

  const camposPossiveis = [
    "id_fornecedor",
    "idFornecedor",
    "fornecedorId",
    "id_usuario",
    "idUsuario",
    "usuarioId",
  ];

  for (const campo of camposPossiveis) {
    const snapshot = await db
      .collection(COLLECTION_FORNECEDORES)
      .where(campo, "==", fornecedorId)
      .limit(1)
      .get();

    if (!snapshot.empty) {
      return snapshot.docs[0];
    }
  }

  return null;
}

function adicionarNotaFornecedor(
  notasPorFornecedor: Map<string, number[]>,
  fornecedorId: string,
  nota: number | null,
): void {
  if (!fornecedorId || nota === null || !Number.isFinite(nota)) {
    return;
  }

  const notas = notasPorFornecedor.get(fornecedorId) ?? [];
  notas.push(nota);
  notasPorFornecedor.set(fornecedorId, notas);
}

function dividirEmBlocos<T>(items: T[], tamanho: number): T[][] {
  const blocos: T[][] = [];

  for (let i = 0; i < items.length; i += tamanho) {
    blocos.push(items.slice(i, i + tamanho));
  }

  return blocos;
}

async function buscarVinculosCategorias(): Promise<FornecedorCategoriaVinculo[]> {
  const db = admin.firestore();
  const snapshot = await db.collection(COLLECTION_FORNECEDOR_CATEGORIA).get();

  return snapshot.docs.map((doc) => {
    const raw = doc.data() ?? {};

    return {
      idFornecedor: asString(raw.id_fornecedor ?? raw.idFornecedor ?? raw.fornecedorId),
      idCategoria: asString(raw.id_categoria ?? raw.idCategoria),
      nomeCategoria: asString(raw.nome_categoria ?? raw.nomeCategoria ?? raw.nome),
      subcategorias: extrairSubcategorias(raw.subcategorias),
      raw,
    };
  }).filter((item) => item.idFornecedor);
}

function extrairSubcategorias(value: unknown): string[] {
  if (!Array.isArray(value)) return [];

  return value.map((item) => {
    if (typeof item === "string") return item;
    if (isRecord(item)) {
      return asString(item.nomeSubcategoria ?? item.nome_subcategoria ?? item.nome ?? item.idSubcategoria);
    }
    return "";
  }).filter(Boolean);
}

async function buscarTerritorios(): Promise<TerritorioFornecedor[]> {
  const db = admin.firestore();
  const snapshot = await db
    .collection(COLLECTION_TERRITORIO)
    .where("ativo", "==", true)
    .get();

  return snapshot.docs.map((doc) => {
    const raw = doc.data() ?? {};

    return {
      idTerritorio: asString(raw.id_territorio ?? raw.idTerritorio ?? doc.id),
      idFornecedor: asString(raw.id_fornecedor ?? raw.idFornecedor ?? raw.fornecedorId),
      latitude: asNullableNumber(raw.latitude),
      longitude: asNullableNumber(raw.longitude),
      raioKm: asNullableNumber(raw.raio_km ?? raw.raioKm),
      descricao: asString(raw.descricao),
      ativo: asBoolean(raw.ativo, true),
      tipoCobertura: asString(raw.tipo_cobertura ?? raw.tipoCobertura),
      regioes: asStringArray(raw.regioes),
      raw,
    };
  }).filter((item) => item.idFornecedor);
}

async function buscarInteracoesUsuario(uid: string): Promise<InteracaoFornecedorResumo[]> {
  const db = admin.firestore();

  // Existem documentos antigos em snake_case e documentos novos em camelCase.
  // Como o Firestore não faz OR simples entre campos diferentes, fazemos duas
  // consultas e consolidamos o resultado em memória.
  const [snapshotSnake, snapshotCamel] = await Promise.all([
    db
      .collection(COLLECTION_INTERACOES)
      .where("id_usuario", "==", uid)
      .limit(300)
      .get(),
    db
      .collection(COLLECTION_INTERACOES)
      .where("usuarioId", "==", uid)
      .limit(300)
      .get(),
  ]);

  const resumo = new Map<string, InteracaoFornecedorResumo>();
  const docs = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();

  for (const doc of snapshotSnake.docs) docs.set(doc.id, doc);
  for (const doc of snapshotCamel.docs) docs.set(doc.id, doc);

  for (const doc of docs.values()) {
    const raw = doc.data() ?? {};
    const idFornecedor = asString(raw.id_fornecedor ?? raw.idFornecedor ?? raw.fornecedorId);
    const acao = asString(raw.acao);

    if (!idFornecedor || !acao) continue;

    const peso = asNumber(raw.peso, calcularPesoInteracaoFornecedor(acao));
    const atual = resumo.get(idFornecedor) ?? {
      idFornecedor,
      score: 0,
      totalInteracoes: 0,
      acoes: {},
    };

    atual.score += peso;
    atual.totalInteracoes += 1;
    atual.acoes[acao] = (atual.acoes[acao] ?? 0) + 1;

    resumo.set(idFornecedor, atual);
  }

  return [...resumo.values()];
}

async function salvarCacheRecomendacoes(recomendacoes: FornecedorRecomendacaoResultado[]): Promise<void> {
  if (recomendacoes.length === 0) return;

  const db = admin.firestore();
  const batch = db.batch();

  for (const recomendacao of recomendacoes) {
    const ref = db.collection(COLLECTION_RECOMENDACOES).doc(recomendacao.id);
    const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

    batch.set(
      ref,
      {
        ...recomendacao,

        eventoId: recomendacao.id_evento,
        usuarioId: recomendacao.id_usuario,
        fornecedorId: recomendacao.id_fornecedor,
        nomeFornecedor: recomendacao.nome_fornecedor,
        bannerUrl: recomendacao.banner_url ?? null,
        categoriaPrincipal: recomendacao.categoria_principal ?? null,
        nivelLabel: recomendacao.nivel_label ?? null,
        motivoPrincipal: recomendacao.motivo_principal ?? null,
        compatibilidadePercentual: recomendacao.compatibilidade_percentual ?? recomendacao.score,
        tipoEventoInformado: recomendacao.tipo_evento_informado ?? false,
        tipoEventoCompativel: recomendacao.tipo_evento_compativel ?? false,
        tipoEventoIncompativel: recomendacao.tipo_evento_incompativel ?? false,
        mediaAvaliacoes: recomendacao.media_avaliacoes,
        totalAvaliacoes: recomendacao.total_avaliacoes,
        distanciaKm: recomendacao.distancia_km ?? null,
        createdAt: serverTimestamp,
        updatedAt: serverTimestamp,

        created_at: serverTimestamp,
        updated_at: serverTimestamp,
      },
      { merge: true },
    );
  }

  await batch.commit();
}

function agruparPor<T>(items: T[], getKey: (item: T) => string): Map<string, T[]> {
  const map = new Map<string, T[]>();

  for (const item of items) {
    const key = getKey(item);
    if (!key) continue;
    map.set(key, [...(map.get(key) ?? []), item]);
  }

  return map;
}

function asString(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const text = String(value).trim();
  return text.length > 0 && text !== "null" ? text : fallback;
}

function asNullableString(value: unknown): string | null {
  const text = asString(value);
  return text || null;
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", ".").replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
}

function asInt(value: unknown, fallback = 0): number {
  return Math.trunc(asNumber(value, fallback));
}

function asNullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = asNumber(value, Number.NaN);
  return Number.isFinite(parsed) ? parsed : null;
}

function asBoolean(value: unknown, fallback = false): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const text = value.toLowerCase().trim();
    if (["true", "s", "sim", "1"].includes(text)) return true;
    if (["false", "n", "nao", "não", "0"].includes(text)) return false;
  }
  if (typeof value === "number") return value === 1;
  return fallback;
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => asString(item)).filter(Boolean);
}

function removerDuplicados(lista: string[]): string[] {
  return [...new Set(lista.filter((item) => item.trim().length > 0))];
}

function isRecord(value: unknown): value is FirestoreRecord {
  return Boolean(value && typeof value === "object" && !Array.isArray(value));
}
