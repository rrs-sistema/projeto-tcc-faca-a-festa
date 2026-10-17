import { montarHtml, selecionarCapaConvite } from "./conviteEmailTemplate";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import {
  exigirTipo,
  exigirUsuarioAutenticado,
} from "../../shared/auth";
import {
  SECRETS_SMTP,
  enviarEmailCodigo,
  isSmtpNaoConfigurado,
} from "../../shared/emailCodigo";
import { admin } from "../../shared/firebaseAdmin";
import { emailPermiteConvite } from "../lgpd/preferenciasNotificacao";

const REGION = "southamerica-east1";
const ORIGEM_PUBLICA = "https://faca-a-festa.web.app";
const MAX_POR_CHAMADA = 40;
const EMAIL_OK = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type EnviarConvitesData = {
  idEvento?: unknown;
  idsConvidados?: unknown;
};

export const enviarConvitesPorEmail = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    cors: true,
    secrets: [...SECRETS_SMTP],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O", "A"]);

    const idEvento = texto((request.data as EnviarConvitesData).idEvento);
    const ids = normalizarIds(
      (request.data as EnviarConvitesData).idsConvidados,
    );
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe o evento.");
    }
    if (ids.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "Selecione ao menos um convidado.",
      );
    }
    if (ids.length > MAX_POR_CHAMADA) {
      throw new HttpsError(
        "invalid-argument",
        `Envie no máximo ${MAX_POR_CHAMADA} convites por vez.`,
      );
    }

    const eventoSnap = await admin
      .firestore()
      .collection("evento")
      .doc(idEvento)
      .get();
    if (!eventoSnap.exists) {
      throw new HttpsError("not-found", "Evento não encontrado.");
    }

    const evento = eventoSnap.data() ?? {};
    const dono = texto(evento.id_usuario);
    if (perfil.tipo !== "A" && dono !== perfil.uid) {
      throw new HttpsError(
        "permission-denied",
        "Você não pode enviar convites deste evento.",
      );
    }

    const nomeEvento =
      texto(evento.nome_evento) || texto(evento.nome) || "o evento";
    const local =
      texto(evento.local_evento) || texto(evento.logradouro);
    const hora = texto(evento.hora);
    const mensagem =
      texto(evento.mensagem) || texto(evento.mensagem_convidado);
    const quando = formatarData(evento.data);
    const visual = await carregarVisualTema(evento);
    const traje = texto(evento.dress_code) || visual.dressCode;

    let enviados = 0;
    const semEmail: string[] = [];
    const falhas: { id: string; motivo: string }[] = [];

    for (const idConvidado of ids) {
      try {
        const encontrado = await buscarConvidado(idConvidado);
        if (!encontrado) {
          falhas.push({ id: idConvidado, motivo: "não encontrado" });
          continue;
        }

        const { snapshot, data } = encontrado;
        if (texto(data.id_evento) !== idEvento) {
          falhas.push({ id: idConvidado, motivo: "não pertence ao evento" });
          continue;
        }

        const email = texto(data.email).toLowerCase();
        if (!EMAIL_OK.test(email)) {
          semEmail.push(idConvidado);
          continue;
        }
        const permite = await emailPermiteConvite(admin.firestore(), email);
        if (!permite) {
          falhas.push({ id: idConvidado, motivo: "titular desligou convites" });
          continue;
        }

        const token =
          texto(data.convite_token) ||
          texto(data.token_convite) ||
          snapshot.id;
        const nome = texto(data.nome) || "Convidado";
        const link = `${ORIGEM_PUBLICA}/#/convite/${encodeURIComponent(token)}`;

        await enviarEmailCodigo({
          para: email,
          assunto: `Convite: ${nomeEvento}`,
          texto: montarTexto({
            nome,
            nomeEvento,
            quando,
            hora,
            local,
            mensagem,
            link,
            nomeTema: visual.nomeTema,
            traje,
          }),
          html: montarHtml({
            nome,
            nomeEvento,
            quando,
            hora,
            local,
            mensagem,
            link,
            nomeTema: visual.nomeTema,
            traje,
            capaUrl: visual.capaUrl,
            corPrimaria: visual.corPrimaria,
            corSecundaria: visual.corSecundaria,
          }),
        });

        await snapshot.ref.set(
          {
            convite_token: token,
            convite_status:
              texto(data.convite_status) === "vinculado"
                ? "vinculado"
                : "enviado_email",
            data_envio: Timestamp.now(),
            data_atualizacao: Timestamp.now(),
          },
          { merge: true },
        );
        enviados += 1;
      } catch (error) {
        if (isSmtpNaoConfigurado(error)) {
          throw new HttpsError(
            "failed-precondition",
            "Envio de e-mail ainda não configurado no servidor.",
          );
        }
        console.error(
          "[enviarConvitesPorEmail] Falha ao enviar:",
          idConvidado,
          error,
        );
        falhas.push({ id: idConvidado, motivo: "falha no envio" });
      }
    }

    return {
      enviados,
      semEmail,
      falhas,
    };
  },
);

async function buscarConvidado(id: string) {
  const porId = await admin.firestore().collection("convidado").doc(id).get();
  if (porId.exists && porId.data()) {
    return { snapshot: porId, data: porId.data() as Record<string, unknown> };
  }
  const snapshot = await admin
    .firestore()
    .collection("convidado")
    .where("id_convidado", "==", id)
    .limit(1)
    .get();
  if (snapshot.empty) return null;
  const doc = snapshot.docs[0];
  return { snapshot: doc, data: doc.data() as Record<string, unknown> };
}

function normalizarIds(valor: unknown): string[] {
  if (!Array.isArray(valor)) return [];
  const vistos = new Set<string>();
  const ids: string[] = [];
  for (const item of valor) {
    const id = texto(item);
    if (!id || id.length > 80 || vistos.has(id)) continue;
    vistos.add(id);
    ids.push(id);
  }
  return ids;
}

function texto(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.trim();
}

function formatarData(value: unknown): string {
  let data: Date | null = null;
  if (value instanceof Timestamp) data = value.toDate();
  else if (value instanceof Date) data = value;
  else if (typeof value === "string" && value.trim()) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) data = parsed;
  }
  if (!data) return "";
  return data.toLocaleDateString("pt-BR", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "America/Sao_Paulo",
  });
}

async function carregarVisualTema(evento: Record<string, unknown>): Promise<{
  nomeTema: string;
  dressCode: string;
  capaUrl: string;
  corPrimaria: string;
  corSecundaria: string;
}> {
  const capaEvento = selecionarCapaConvite(evento.imagem_capa_url);
  const fallback = {
    nomeTema: texto(evento.tema),
    dressCode: texto(evento.dress_code),
    capaUrl: capaEvento,
    corPrimaria: "#009688",
    corSecundaria: "#4DB6AC",
  };
  const idTema = texto(evento.id_tema);
  if (!idTema || idTema === "outro") return fallback;
  try {
    const snap = await admin
      .firestore()
      .collection("tema_festa")
      .doc(idTema)
      .get();
    if (!snap.exists) return fallback;
    const data = snap.data() ?? {};
    return {
      nomeTema: texto(data.nome) || fallback.nomeTema,
      dressCode:
        fallback.dressCode || texto(data.dress_code_sugerido),
      capaUrl: selecionarCapaConvite(capaEvento, data.imagem_capa_url),
      corPrimaria: corCss(texto(data.cor_primaria), fallback.corPrimaria),
      corSecundaria: corCss(texto(data.cor_secundaria), fallback.corSecundaria),
    };
  } catch (error) {
    console.error("[enviarConvitesPorEmail] Falha ao carregar tema:", error);
    return fallback;
  }
}

function corCss(value: string, fallback: string): string {
  return /^#[0-9a-fA-F]{6}$/.test(value.trim())
    ? value.trim().toUpperCase()
    : fallback;
}

function montarTexto(params: {
  nome: string;
  nomeEvento: string;
  quando: string;
  hora: string;
  local: string;
  mensagem: string;
  link: string;
  nomeTema: string;
  traje: string;
}): string {
  const linhas = [
    `Olá, ${params.nome}!`,
    "",
    `Você foi convidado(a) para ${params.nomeEvento}.`,
  ];
  if (params.nomeTema) linhas.push(`Tema: ${params.nomeTema}`);
  if (params.traje) linhas.push(`Traje: ${params.traje}`);
  if (params.quando) linhas.push(`Quando: ${params.quando}`);
  if (params.hora) linhas.push(`Horário: ${params.hora}`);
  if (params.local) linhas.push(`Local: ${params.local}`);
  if (params.mensagem) {
    linhas.push("", params.mensagem);
  }
  linhas.push("", "Abra seu convite:", params.link);
  return linhas.join("\n");
}
