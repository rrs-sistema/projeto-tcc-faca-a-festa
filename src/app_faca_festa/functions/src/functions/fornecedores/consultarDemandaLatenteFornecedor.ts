import { onCall } from "../../shared/callableComMfa";
import { HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";

const REGION = "southamerica-east1";

type BucketAcc = {
  tipoNome: string;
  cidade: string;
  quantidade: number;
  semCotacao: number;
  proximos90Dias: number;
  somaConvidados: number;
  comConvidados: number;
};

function texto(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const t = String(value).trim();
  return t.length > 0 && t !== "null" ? t : fallback;
}

function normalizar(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

function asDate(value: unknown): Date | null {
  if (!value) return null;
  if (typeof (value as { toDate?: () => Date }).toDate === "function") {
    return (value as { toDate: () => Date }).toDate();
  }
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const d = new Date(value);
    return Number.isFinite(d.getTime()) ? d : null;
  }
  return null;
}

function asInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string") {
    const n = Number(value.replace(/[^\d-]/g, ""));
    return Number.isFinite(n) ? Math.trunc(n) : 0;
  }
  return 0;
}

function statusEmCurso(
  status: string,
  ativo: boolean,
  data: Date | null,
  agora: Date,
): boolean {
  const s = normalizar(status).replace(/\s+/g, "");
  const ativos = new Set([
    "rascunho",
    "planejamento",
    "confirmado",
    "emandamento",
    "em_andamento",
  ]);
  if (s) return ativos.has(s);
  if (!ativo) return false;
  if (!data) return true;
  return data.getTime() >= agora.getTime() - 86400000;
}

/**
 * Radar de demanda latente: agrega eventos futuros alinhados ao território/tipos
 * do fornecedor, sem expor dados pessoais do organizador.
 */
export const consultarDemandaLatenteFornecedor = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["F"]);
    const uid = perfil.uid;
    const db = admin.firestore();
    const agora = new Date();
    const limite90 = new Date(agora.getTime() + 90 * 86400000);

    const [fornecedorSnap, territorioSnap, eventosSnap, cotacoesSnap, tiposSnap] =
      await Promise.all([
        db.collection("fornecedor").doc(uid).get(),
        db.collection("territorio").where("id_fornecedor", "==", uid).get(),
        db.collection("evento").get(),
        db.collection("cotacao").get(),
        db.collection("tipo_evento").get(),
      ]);

    if (!fornecedorSnap.exists) {
      throw new HttpsError("not-found", "Fornecedor não encontrado.");
    }

    const fornecedor = fornecedorSnap.data() || {};
    if (fornecedor.ativo === false) {
      throw new HttpsError("permission-denied", "Fornecedor inativo.");
    }

    const cidadeFornecedor = normalizar(
      texto(
        fornecedor.cidade ??
          fornecedor.cidade_atendimento ??
          fornecedor.cidadeAtendimento,
      ),
    );
    const ufFornecedor = normalizar(
      texto(
        fornecedor.estado ??
          fornecedor.uf ??
          fornecedor.estado_atendimento,
      ),
    );
    const tiposFornecedor = new Set(
      [
        ...(Array.isArray(fornecedor.tipo_evento_nomes)
          ? fornecedor.tipo_evento_nomes
          : []),
        ...(Array.isArray(fornecedor.tipoEventoNomes)
          ? fornecedor.tipoEventoNomes
          : []),
        ...(Array.isArray(fornecedor.tipo_evento_slugs)
          ? fornecedor.tipo_evento_slugs
          : []),
        ...(Array.isArray(fornecedor.tipoEventoSlugs)
          ? fornecedor.tipoEventoSlugs
          : []),
      ]
        .map((t) => normalizar(String(t)))
        .filter(Boolean),
    );

    const regioes = new Set<string>();
    for (const doc of territorioSnap.docs) {
      const data = doc.data();
      if (data.ativo === false) continue;
      const lista = Array.isArray(data.regioes) ? data.regioes : [];
      for (const r of lista) {
        const n = normalizar(String(r));
        if (n) regioes.add(n);
      }
      const desc = normalizar(texto(data.descricao));
      if (desc) regioes.add(desc);
    }
    if (cidadeFornecedor) regioes.add(cidadeFornecedor);

    const nomesTipo = new Map<string, string>();
    for (const doc of tiposSnap.docs) {
      const d = doc.data();
      const nome = texto(d.nome, "Tipo não informado");
      nomesTipo.set(doc.id, nome);
      const alt = texto(d.id_tipo_evento ?? d.idTipoEvento);
      if (alt) nomesTipo.set(alt, nome);
    }

    const cotacoesPorEvento = new Map<string, number>();
    for (const doc of cotacoesSnap.docs) {
      const d = doc.data();
      const idEvento = texto(d.id_evento ?? d.idEvento);
      if (!idEvento) continue;
      cotacoesPorEvento.set(
        idEvento,
        (cotacoesPorEvento.get(idEvento) || 0) + 1,
      );
    }

    const buckets = new Map<string, BucketAcc>();
    let totalEventos = 0;
    let totalSemCotacao = 0;

    for (const doc of eventosSnap.docs) {
      const d = doc.data();
      const ativo = d.ativo !== false;
      const status = texto(d.status);
      const data = asDate(d.data ?? d.data_evento ?? d.dataEvento);
      if (!statusEmCurso(status, ativo, data, agora)) continue;
      if (data && data.getTime() < agora.getTime() - 86400000) continue;

      const cidade = texto(
        d.nomeCidade ?? d.nome_cidade ?? d.cidade,
        "Cidade não informada",
      );
      const uf = texto(d.uf ?? d.estado);
      const idTipo = texto(d.id_tipo_evento ?? d.idTipoEvento);
      const tipoNome =
        nomesTipo.get(idTipo) ||
        texto(d.tipoEventoNome ?? d.tipo_evento_nome, "Evento");
      const tipoNorm = normalizar(tipoNome);
      const cidadeNorm = normalizar(cidade);
      const ufNorm = normalizar(uf);

      const cobreRegiao =
        regioes.size === 0
          ? true
          : regioes.has(cidadeNorm) ||
            (ufNorm.length > 0 && regioes.has(ufNorm)) ||
            (cidadeFornecedor.length > 0 && cidadeNorm === cidadeFornecedor) ||
            (ufFornecedor.length > 0 && ufNorm === ufFornecedor);

      if (regioes.size > 0 && !cobreRegiao) continue;

      if (tiposFornecedor.size > 0) {
        const cobreTipo = [...tiposFornecedor].some(
          (t) => tipoNorm.includes(t) || t.includes(tipoNorm),
        );
        if (!cobreTipo) continue;
      }

      const qtdCot = cotacoesPorEvento.get(doc.id) || 0;
      const semCotacao = qtdCot <= 0;
      const proximos90 =
        data != null &&
        data.getTime() >= agora.getTime() &&
        data.getTime() <= limite90.getTime();
      const convidados = asInt(d.totalConvidados ?? d.total_convidados);

      totalEventos += 1;
      if (semCotacao) totalSemCotacao += 1;

      const chave = `${tipoNorm}|${cidadeNorm}`;
      const atual = buckets.get(chave) || {
        tipoNome,
        cidade,
        quantidade: 0,
        semCotacao: 0,
        proximos90Dias: 0,
        somaConvidados: 0,
        comConvidados: 0,
      };
      atual.quantidade += 1;
      if (semCotacao) atual.semCotacao += 1;
      if (proximos90) atual.proximos90Dias += 1;
      if (convidados > 0) {
        atual.somaConvidados += convidados;
        atual.comConvidados += 1;
      }
      buckets.set(chave, atual);
    }

    const lista = [...buckets.values()]
      .map((b) => ({
        tipoNome: b.tipoNome,
        cidade: b.cidade,
        quantidade: b.quantidade,
        semCotacao: b.semCotacao,
        proximos90Dias: b.proximos90Dias,
        convidadosMedios:
          b.comConvidados > 0
            ? Math.round(b.somaConvidados / b.comConvidados)
            : 0,
      }))
      .sort(
        (a, b) =>
          b.semCotacao - a.semCotacao ||
          b.proximos90Dias - a.proximos90Dias ||
          b.quantidade - a.quantidade,
      )
      .slice(0, 20);

    return {
      geradoEm: agora.toISOString(),
      totalEventos,
      totalSemCotacao,
      buckets: lista,
      criterio:
        "Eventos em curso com data futura na cobertura (regiões/cidade/UF do território) e tipos atendidos. Agregado sem dados pessoais. Sem cotação = demanda latente.",
    };
  },
);
