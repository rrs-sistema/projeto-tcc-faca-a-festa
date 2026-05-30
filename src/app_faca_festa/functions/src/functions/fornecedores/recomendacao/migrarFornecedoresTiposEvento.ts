import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { admin } from "../../../shared/firebaseAdmin";

const DEFAULT_REGION = "southamerica-east1";
const COLLECTION_FORNECEDORES = "fornecedor";
const COLLECTION_FORNECEDOR_CATEGORIA = "fornecedor_categoria";

const TIPOS_EVENTO = {
  chaBebe: {
    id: "1eab2c53-a7d3-4a97-b473-02572464e779",
    slug: "cha_de_bebe",
    nome: "Chá de Bebê",
  },
  aniversario: {
    id: "7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda",
    slug: "aniversario",
    nome: "Aniversário",
  },
  festaInfantil: {
    id: "ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8",
    slug: "festa_infantil",
    nome: "Festa Infantil",
  },
  formatura: {
    id: "WlLdfdmu4Chvw2p8daUm",
    slug: "formatura",
    nome: "Formatura",
  },
  casamento: {
    id: "302191a2-dbf3-4ac6-ba53-08273b384cab",
    slug: "casamento",
    nome: "Casamento",
  },
  corporativo: {
    id: "lXf0M5vMNvyRn52yQ2fY",
    slug: "evento_corporativo",
    nome: "Evento Corporativo",
  },
} as const;

type TipoEventoKey = keyof typeof TIPOS_EVENTO;
type FirestoreRecord = Record<string, unknown>;

export const migrarFornecedoresTiposEvento = onCall(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 120,
    memory: "512MiB",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const dryRun = asBoolean(request.data?.dryRun ?? request.data?.dry_run, true);
    const aplicar = asBoolean(request.data?.aplicar, false);
    const sobrescrever = asBoolean(request.data?.sobrescrever, false);
    const limite = Math.max(1, Math.min(asInt(request.data?.limite, 500), 1000));

    if (!dryRun && !aplicar) {
      throw new HttpsError(
        "failed-precondition",
        "Para aplicar a migração, envie dryRun=false e aplicar=true.",
      );
    }

    const db = admin.firestore();

    const [fornecedoresSnap, vinculosSnap] = await Promise.all([
      db.collection(COLLECTION_FORNECEDORES).limit(limite).get(),
      db.collection(COLLECTION_FORNECEDOR_CATEGORIA).get(),
    ]);

    const vinculosPorFornecedor = new Map<string, FirestoreRecord[]>();

    for (const doc of vinculosSnap.docs) {
      const raw = doc.data() ?? {};
      const idFornecedor = asString(raw.idFornecedor ?? raw.fornecedorId ?? raw.id_fornecedor);
      if (!idFornecedor) continue;

      const lista = vinculosPorFornecedor.get(idFornecedor) ?? [];
      lista.push(raw);
      vinculosPorFornecedor.set(idFornecedor, lista);
    }

    const resultados: Array<{
      fornecedorId: string;
      nome: string;
      jaPossuiaTipos: boolean;
      atualizado: boolean;
      tiposEventoNomes: string[];
      motivoInferencia: string;
    }> = [];
    
    const batch = db.batch();
    let totalAtualizados = 0;
    let totalIgnorados = 0;

    for (const doc of fornecedoresSnap.docs) {
      const fornecedor = doc.data() ?? {};
      const fornecedorId = asString(fornecedor.idFornecedor ?? fornecedor.fornecedorId ?? fornecedor.id_fornecedor ?? doc.id);
      const nome = asString(fornecedor.razaoSocial ?? fornecedor.razao_social ?? fornecedor.nome ?? fornecedor.nomeFornecedor, "Fornecedor");

      const tiposExistentes = asStringArray(fornecedor.tipoEventoIds ?? fornecedor.tipo_evento_ids);
      const jaPossuiaTipos = tiposExistentes.length > 0;

      if (jaPossuiaTipos && !sobrescrever) {
        totalIgnorados += 1;
        resultados.push({
          fornecedorId,
          nome,
          jaPossuiaTipos: true,
          atualizado: false,
          tiposEventoNomes: asStringArray(fornecedor.tipoEventoNomes ?? fornecedor.tipo_evento_nomes),
          motivoInferencia: "Fornecedor já possuía tipos de evento; não sobrescrito.",
        });
        continue;
      }

      const vinculos = vinculosPorFornecedor.get(fornecedorId) ?? [];
      const inferencia = inferirTiposEventoFornecedor(fornecedor, vinculos);

      if (inferencia.tipos.length === 0) {
        totalIgnorados += 1;
        resultados.push({
          fornecedorId,
          nome,
          jaPossuiaTipos,
          atualizado: false,
          tiposEventoNomes: [],
          motivoInferencia: "Não foi possível inferir tipos de evento com segurança.",
        });
        continue;
      }

      const tipoEventoIds = inferencia.tipos.map((key) => TIPOS_EVENTO[key].id);
      const tipoEventoSlugs = inferencia.tipos.map((key) => TIPOS_EVENTO[key].slug);
      const tipoEventoNomes = inferencia.tipos.map((key) => TIPOS_EVENTO[key].nome);

      if (!dryRun) {
        batch.set(
          doc.ref,
          {
            tipoEventoIds,
            tipoEventoSlugs,
            tipoEventoNomes,
            tipo_evento_ids: tipoEventoIds,
            tipo_evento_slugs: tipoEventoSlugs,
            tipo_evento_nomes: tipoEventoNomes,
            migracaoTiposEventoFornecedorAt: admin.firestore.FieldValue.serverTimestamp(),
            migracao_tipos_evento_fornecedor_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      totalAtualizados += 1;
      resultados.push({
        fornecedorId,
        nome,
        jaPossuiaTipos,
        atualizado: !dryRun,
        tiposEventoNomes: tipoEventoNomes,
        motivoInferencia: inferencia.motivo,
      });
    }

    if (!dryRun && totalAtualizados > 0) {
      await batch.commit();
    }

    logger.info("Migração de tipos de evento de fornecedores concluída.", {
      dryRun,
      aplicar,
      sobrescrever,
      totalFornecedores: fornecedoresSnap.size,
      totalAtualizados,
      totalIgnorados,
    });

    return {
      ok: true,
      dryRun,
      aplicar,
      sobrescrever,
      totalFornecedores: fornecedoresSnap.size,
      totalAtualizados,
      totalIgnorados,
      resultados: resultados.slice(0, 100),
    };
  },
);

function inferirTiposEventoFornecedor(
  fornecedor: FirestoreRecord,
  vinculos: FirestoreRecord[],
): { tipos: TipoEventoKey[]; motivo: string } {
  const texto = normalizarTexto([
    fornecedor.razaoSocial,
    fornecedor.razao_social,
    fornecedor.nome,
    fornecedor.nomeFornecedor,
    fornecedor.descricao,
    fornecedor.bio,
    fornecedor.servico,
    JSON.stringify(fornecedor.categorias ?? []),
    JSON.stringify(vinculos),
  ].filter(Boolean).join(" "));

  const tipos = new Set<TipoEventoKey>();
  const motivos: string[] = [];

  if (contemAlgum(texto, ["casamento", "noiva", "noivo", "cerimonial", "aliança", "alianca", "wedding"])) {
    tipos.add("casamento");
    motivos.push("termos relacionados a casamento");
  }

  if (contemAlgum(texto, ["infantil", "crianca", "criança", "kids", "recreacao", "recreação", "playground", "cama elastica", "piscina de bolinhas", "personagem"])) {
    tipos.add("festaInfantil");
    tipos.add("aniversario");
    motivos.push("termos relacionados a festa infantil/aniversário");
  }

  if (contemAlgum(texto, ["aniversario", "aniversário", "bolo", "docinho", "docinhos", "lembrancinha", "festa personalizada", "topper", "toppers"])) {
    tipos.add("aniversario");
    motivos.push("termos relacionados a aniversário/festa");
  }

  if (contemAlgum(texto, ["cha de bebe", "chá de bebê", "cha bebe", "bebe", "bebê", "maternidade", "revelacao", "revelação"])) {
    tipos.add("chaBebe");
    motivos.push("termos relacionados a chá de bebê");
  }

  if (contemAlgum(texto, ["formatura", "formando", "colacao", "colação", "baile", "diploma"])) {
    tipos.add("formatura");
    motivos.push("termos relacionados a formatura");
  }

  if (contemAlgum(texto, ["corporativo", "empresa", "empresarial", "coffee break", "coffe break", "confraternizacao", "confraternização", "palestra", "workshop", "treinamento"])) {
    tipos.add("corporativo");
    motivos.push("termos relacionados a evento corporativo");
  }

  if (tipos.size === 0 && contemAlgum(texto, ["decoracao", "decoração", "fotografia", "filmagem", "buffet", "musica", "música", "dj", "papelaria", "flores", "mesa", "cadeira", "locacao", "locação"])) {
    tipos.add("casamento");
    tipos.add("aniversario");
    tipos.add("festaInfantil");
    tipos.add("chaBebe");
    tipos.add("formatura");
    motivos.push("categoria genérica aplicável a eventos sociais");
  }

  return {
    tipos: [...tipos],
    motivo: motivos.length > 0 ? motivos.join("; ") : "Sem inferência automática.",
  };
}

function contemAlgum(texto: string, termos: string[]): boolean {
  return termos.some((termo) => texto.includes(normalizarTexto(termo)));
}

function normalizarTexto(valor: unknown): string {
  return String(valor ?? "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s_-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function asString(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const text = String(value).trim();
  return text.length > 0 && text !== "null" ? text : fallback;
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.map((item) => asString(item)).filter(Boolean);
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

function asInt(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string") {
    const parsed = Number(value.replace(",", ".").replace(/[^0-9.-]/g, ""));
    return Number.isFinite(parsed) ? Math.trunc(parsed) : fallback;
  }
  return fallback;
}
