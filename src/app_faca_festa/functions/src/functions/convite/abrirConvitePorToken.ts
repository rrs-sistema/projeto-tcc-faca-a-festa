import { createHash } from "crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { admin } from "../../shared/firebaseAdmin";

const REGION = "southamerica-east1";
const COLECOES_CONVITE = ["convidado", "convidados"] as const;
const CAMPOS_TOKEN = ["convite_token", "token_convite", "token"] as const;

type AbrirConviteData = {
  token?: unknown;
};

export const abrirConvitePorToken = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    invoker: "public",
  },
  async (request) => {
    const token = normalizarToken(request.data as AbrirConviteData);
    const encontrado = await buscarConvitePorToken(token);
    if (!encontrado) {
      throw new HttpsError("not-found", "Convite não encontrado.");
    }

    const { snapshot, data } = encontrado;
    const idConvidado = texto(data.id_convidado) || snapshot.id;
    const idEvento = texto(data.id_evento);
    if (!idEvento) {
      throw new HttpsError("not-found", "Convite não encontrado.");
    }

    const eventoSnap = await admin
      .firestore()
      .collection("evento")
      .doc(idEvento)
      .get();
    if (!eventoSnap.exists) {
      throw new HttpsError("not-found", "Convite não encontrado.");
    }

    const evento = eventoSnap.data() ?? {};
    const conviteToken = texto(data.convite_token) || token;
    if (!texto(data.convite_token)) {
      await snapshot.ref.set({ convite_token: conviteToken }, { merge: true });
    }

    const claims = {
      conviteToken,
      idConvidado,
      idEvento,
      papel: "C",
    };

    const uid = uidVisitante(token);
    await garantirUsuarioVisitante(uid);
    await admin.auth().setCustomUserClaims(uid, claims);
    let customToken: string;
    try {
      customToken = await admin.auth().createCustomToken(uid, claims);
    } catch (error) {
      console.error("[abrirConvitePorToken] Falha ao criar sessão:", error);
      throw new HttpsError(
        "failed-precondition",
        "Não foi possível abrir o convite agora. Tente novamente.",
      );
    }

    return {
      tokenSessao: customToken,
      convidado: serializarConvidado(data, idConvidado, conviteToken),
      evento: serializarEvento(evento, idEvento),
    };
  },
);

function uidVisitante(token: string): string {
  const hash = createHash("sha256")
    .update(`convite:${token}`)
    .digest("hex")
    .slice(0, 28);
  return `c_${hash}`;
}

async function garantirUsuarioVisitante(uid: string): Promise<void> {
  try {
    await admin.auth().getUser(uid);
  } catch (erro) {
    const codigo =
      erro && typeof erro === "object" && "code" in erro
        ? String((erro as { code: unknown }).code)
        : "";
    if (codigo !== "auth/user-not-found") {
      throw erro;
    }
    await admin.auth().createUser({ uid, disabled: false });
  }
}

function normalizarToken(data: AbrirConviteData): string {
  const token = typeof data.token === "string" ? data.token.trim() : "";
  if (!/^[A-Za-z0-9-]{16,80}$/.test(token)) {
    throw new HttpsError("invalid-argument", "Convite inválido.");
  }
  return token;
}

async function buscarConvitePorToken(token: string) {
  for (const colecao of COLECOES_CONVITE) {
    const porId = await admin.firestore().collection(colecao).doc(token).get();
    if (porId.exists && porId.data()) {
      return { snapshot: porId, data: porId.data() as Record<string, unknown> };
    }

    for (const campo of CAMPOS_TOKEN) {
      const snapshot = await admin
        .firestore()
        .collection(colecao)
        .where(campo, "==", token)
        .limit(1)
        .get();
      if (!snapshot.empty) {
        const doc = snapshot.docs[0];
        return { snapshot: doc, data: doc.data() as Record<string, unknown> };
      }
    }
  }
  return null;
}

function serializarConvidado(
  data: Record<string, unknown>,
  idConvidado: string,
  conviteToken: string,
): Record<string, unknown> {
  return {
    id_convidado: idConvidado,
    id_evento: texto(data.id_evento),
    nome: texto(data.nome),
    contato: texto(data.contato),
    email: texto(data.email) || null,
    status: texto(data.status) || "pendente",
    tipo_convidado: texto(data.tipo_convidado),
    adulto: data.adulto === true,
    id_grupo: texto(data.id_grupo) || null,
    nome_grupo: texto(data.nome_grupo) || null,
    id_mesa: texto(data.id_mesa) || null,
    numero_mesa: data.numero_mesa ?? null,
    ocupa_assento: data.ocupa_assento !== false,
    cuidado_especial: data.cuidado_especial === true,
    data_envio: iso(data.data_envio),
    data_resposta: iso(data.data_resposta),
    data_cadastro: iso(data.data_cadastro),
    data_atualizacao: iso(data.data_atualizacao),
    convite_token: conviteToken,
    convite_status: texto(data.convite_status) || "link_gerado",
    id_usuario: texto(data.id_usuario) || null,
  };
}

function serializarEvento(
  data: Record<string, unknown>,
  idEvento: string,
): Record<string, unknown> {
  const mensagem =
    texto(data.mensagem) ||
    texto(data.mensagem_convidado) ||
    texto(data.descricao);

  return {
    id_evento: texto(data.id_evento) || idEvento,
    id_tipo_evento: texto(data.id_tipo_evento),
    id_usuario: texto(data.id_usuario),
    nome_evento: texto(data.nome_evento) || texto(data.nome),
    local_evento: texto(data.local_evento) || texto(data.logradouro),
    data: iso(data.data),
    hora: texto(data.hora) || null,
    mensagem,
    mensagem_convidado: mensagem,
    nome_cidade: texto(data.nome_cidade) || null,
    uf: texto(data.uf) || null,
    cep: texto(data.cep) || null,
    logradouro: texto(data.logradouro) || null,
    numero: texto(data.numero) || null,
    complemento: texto(data.complemento) || null,
    bairro: texto(data.bairro) || null,
    dress_code: texto(data.dress_code) || null,
    hashtag_evento: texto(data.hashtag_evento) || null,
    site_evento: texto(data.site_evento) || null,
    id_tema: texto(data.id_tema) || null,
    tema: texto(data.tema) || null,
  };
}

function texto(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.trim();
}

function iso(value: unknown): string | null {
  if (!value) return null;
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "string" && value.trim()) return value.trim();
  return null;
}
