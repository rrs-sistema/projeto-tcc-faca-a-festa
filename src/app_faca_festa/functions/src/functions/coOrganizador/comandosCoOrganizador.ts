import { randomBytes } from "crypto";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

import { onCall } from "../../shared/callableComMfa";
import {
  exigirTipo,
  exigirUsuarioAutenticado,
} from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import {
  SECRETS_SMTP,
  enviarEmailCodigo,
  isSmtpNaoConfigurado,
} from "../../shared/emailCodigo";
import {
  MAX_CO_ORGANIZADORES,
  carregarEvento,
  exigirDonoEvento,
  exigirGestorEvento,
} from "../../shared/eventoPermissao";
import { emailPermiteConvite } from "../lgpd/preferenciasNotificacao";
import { montarHtmlConviteCoOrganizador } from "./coOrganizadorEmailTemplate";

const REGION = "southamerica-east1";
const ORIGEM_PUBLICA = "https://faca-a-festa.web.app";
const COL_CONVITES = "convites_co_organizador";
const EMAIL_OK = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const TOKEN_OK = /^[A-Za-z0-9]{24,64}$/;
const DIAS_VALIDADE = 14;

function texto(valor: unknown): string {
  return typeof valor === "string" ? valor.trim() : "";
}

function emailNorm(valor: unknown): string {
  return texto(valor).toLowerCase();
}

function formatarData(valor: unknown): string {
  try {
    if (valor && typeof (valor as { toDate?: () => Date }).toDate === "function") {
      const d = (valor as { toDate: () => Date }).toDate();
      return d.toLocaleDateString("pt-BR");
    }
    if (typeof valor === "string" && valor) {
      const d = new Date(valor);
      if (!Number.isNaN(d.getTime())) return d.toLocaleDateString("pt-BR");
    }
  } catch (_) {
    // ignora
  }
  return "";
}

function novoToken(): string {
  return randomBytes(24).toString("hex");
}

async function nomeUsuario(uid: string): Promise<string> {
  const snap = await admin.firestore().collection("usuarios").doc(uid).get();
  const data = snap.data() ?? {};
  return texto(data.nome) || texto(data.nome_completo) || "Organizadora(or)";
}

async function buscarUidPorEmail(email: string): Promise<string | null> {
  try {
    const user = await admin.auth().getUserByEmail(email);
    return user.uid;
  } catch (_) {
    return null;
  }
}

export const convidarCoOrganizador = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    cors: true,
    secrets: [...SECRETS_SMTP],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O"]);

    const idEvento = texto(request.data?.idEvento ?? request.data?.id_evento);
    const email = emailNorm(request.data?.email);
    const nomeConvidado = texto(request.data?.nome);

    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe o evento.");
    }
    if (!EMAIL_OK.test(email)) {
      throw new HttpsError("invalid-argument", "Informe um e-mail válido.");
    }

    const evento = await exigirDonoEvento(admin.firestore(), perfil.uid, idEvento);
    if (evento.coOrganizadores.length >= MAX_CO_ORGANIZADORES) {
      throw new HttpsError(
        "failed-precondition",
        `Este evento já tem o máximo de ${MAX_CO_ORGANIZADORES} co-organizadores.`,
      );
    }

    const uidExistente = await buscarUidPorEmail(email);
    if (uidExistente === perfil.uid || uidExistente === evento.idUsuario) {
      throw new HttpsError(
        "failed-precondition",
        "Você já é o organizador principal deste evento.",
      );
    }
    if (uidExistente && evento.coOrganizadores.includes(uidExistente)) {
      throw new HttpsError(
        "already-exists",
        "Esta pessoa já é co-organizadora deste evento.",
      );
    }

    const permite = await emailPermiteConvite(admin.firestore(), email);
    if (!permite) {
      throw new HttpsError(
        "failed-precondition",
        "Este e-mail não aceita convites da plataforma.",
      );
    }

    const db = admin.firestore();
    const pendentes = await db
      .collection(COL_CONVITES)
      .where("id_evento", "==", idEvento)
      .where("email", "==", email)
      .where("status", "==", "pendente")
      .limit(5)
      .get();

    const agora = Timestamp.now();
    for (const doc of pendentes.docs) {
      const expira = doc.data().expira_em as Timestamp | undefined;
      if (expira && expira.toMillis() > agora.toMillis()) {
        throw new HttpsError(
          "already-exists",
          "Já existe um convite pendente para este e-mail.",
        );
      }
    }

    const token = novoToken();
    const expiraEm = Timestamp.fromMillis(
      Date.now() + DIAS_VALIDADE * 24 * 60 * 60 * 1000,
    );
    const nomeEvento =
      texto(evento.data.nome_evento) || texto(evento.data.nome) || "seu evento";
    const nomeDono = await nomeUsuario(perfil.uid);
    const link = `${ORIGEM_PUBLICA}/#/convite-organizador/${token}`;

    await db.collection(COL_CONVITES).doc(token).set({
      token,
      id_evento: idEvento,
      email,
      nome_convidado: nomeConvidado || null,
      convidado_por: perfil.uid,
      uid_destino: uidExistente,
      status: "pendente",
      criado_em: FieldValue.serverTimestamp(),
      expira_em: expiraEm,
      nome_evento: nomeEvento,
    });

    try {
      await enviarEmailCodigo({
        para: email,
        assunto: `Convite para co-organizar ${nomeEvento}`,
        html: montarHtmlConviteCoOrganizador({
          nomeConvidado: nomeConvidado || "",
          nomeDono,
          nomeEvento,
          quando: formatarData(evento.data.data),
          link,
        }),
        texto:
          `${nomeDono} convidou você para co-organizar ${nomeEvento}. ` +
          `Abra o link para aceitar: ${link}`,
      });
    } catch (error) {
      if (isSmtpNaoConfigurado(error)) {
        throw new HttpsError(
          "failed-precondition",
          "Envio de e-mail ainda não configurado no servidor.",
        );
      }
      throw error;
    }

    return {
      ok: true,
      token,
      email,
      expiraEm: expiraEm.toDate().toISOString(),
    };
  },
);

export const aceitarConviteCoOrganizador = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O"]);

    const token = texto(request.data?.token);
    if (!TOKEN_OK.test(token)) {
      throw new HttpsError("invalid-argument", "Convite inválido.");
    }

    const db = admin.firestore();
    const conviteRef = db.collection(COL_CONVITES).doc(token);
    const authUser = await admin.auth().getUser(perfil.uid);
    const emailConta = emailNorm(authUser.email);
    if (!emailConta) {
      throw new HttpsError(
        "failed-precondition",
        "Sua conta precisa ter um e-mail para aceitar o convite.",
      );
    }

    // Validações fora da transação (evita HttpsError engolido pelo retry).
    const conviteSnap = await conviteRef.get();
    if (!conviteSnap.exists) {
      throw new HttpsError("not-found", "Convite não encontrado.");
    }
    const convitePre = conviteSnap.data() ?? {};
    if (texto(convitePre.status) === "aceito") {
      if (texto(convitePre.uid_aceito) === perfil.uid) {
        return {
          ok: true,
          idEvento: texto(convitePre.id_evento),
          idempotente: true,
        };
      }
      throw new HttpsError(
        "failed-precondition",
        "Este convite já foi utilizado.",
      );
    }
    if (
      texto(convitePre.status) === "cancelado" ||
      texto(convitePre.status) === "revogado"
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Este convite não está mais válido.",
      );
    }
    const expiraPre = convitePre.expira_em as Timestamp | undefined;
    if (expiraPre && expiraPre.toMillis() < Date.now()) {
      throw new HttpsError("failed-precondition", "Este convite expirou.");
    }
    const emailConvite = emailNorm(convitePre.email);
    if (emailConta !== emailConvite) {
      throw new HttpsError(
        "permission-denied",
        "Entre com a conta do e-mail que recebeu o convite.",
      );
    }

    let idEvento = texto(convitePre.id_evento);
    if (!idEvento) {
      throw new HttpsError("failed-precondition", "Convite sem evento vinculado.");
    }

    // Resolve o documento do evento (id do doc ou campo id_evento).
    let eventoRef = db.collection("evento").doc(idEvento);
    let eventoSnap = await eventoRef.get();
    if (!eventoSnap.exists) {
      const porCampo = await db
        .collection("evento")
        .where("id_evento", "==", idEvento)
        .limit(1)
        .get();
      if (porCampo.empty) {
        throw new HttpsError("not-found", "Evento não encontrado.");
      }
      eventoRef = porCampo.docs[0].ref;
      eventoSnap = porCampo.docs[0];
      idEvento = eventoRef.id;
    }

    const eventoPre = eventoSnap.data() ?? {};
    const donoPre = texto(eventoPre.id_usuario);
    if (perfil.uid === donoPre) {
      throw new HttpsError(
        "failed-precondition",
        "Você já é o organizador principal deste evento.",
      );
    }

    try {
      await db.runTransaction(async (tx) => {
        const [cSnap, eSnap] = await Promise.all([
          tx.get(conviteRef),
          tx.get(eventoRef),
        ]);
        if (!cSnap.exists) {
          throw new HttpsError("not-found", "Convite não encontrado.");
        }
        if (!eSnap.exists) {
          throw new HttpsError("not-found", "Evento não encontrado.");
        }
        const convite = cSnap.data() ?? {};
        if (texto(convite.status) === "aceito") {
          if (texto(convite.uid_aceito) === perfil.uid) return;
          throw new HttpsError(
            "failed-precondition",
            "Este convite já foi utilizado.",
          );
        }
        const evento = eSnap.data() ?? {};
        const coOrgs = Array.isArray(evento.co_organizadores)
          ? evento.co_organizadores.map((u: unknown) => texto(u)).filter(Boolean)
          : [];
        if (coOrgs.includes(perfil.uid)) {
          tx.update(conviteRef, {
            status: "aceito",
            uid_aceito: perfil.uid,
            aceito_em: FieldValue.serverTimestamp(),
          });
          return;
        }
        if (coOrgs.length >= MAX_CO_ORGANIZADORES) {
          throw new HttpsError(
            "failed-precondition",
            `Este evento já tem o máximo de ${MAX_CO_ORGANIZADORES} co-organizadores.`,
          );
        }
        tx.update(eventoRef, {
          co_organizadores: [...coOrgs, perfil.uid],
          atualizado_em: FieldValue.serverTimestamp(),
        });
        tx.set(
          eventoRef.collection("membros").doc(perfil.uid),
          {
            uid: perfil.uid,
            papel: "co_organizador",
            email: emailConta,
            convidado_por: texto(convite.convidado_por) || null,
            aceito_em: FieldValue.serverTimestamp(),
            status: "ativo",
          },
          { merge: true },
        );
        tx.update(conviteRef, {
          status: "aceito",
          uid_aceito: perfil.uid,
          aceito_em: FieldValue.serverTimestamp(),
        });
      });
    } catch (erro) {
      if (erro instanceof HttpsError) throw erro;
      console.error("[aceitarConviteCoOrganizador] Falha na transação", {
        uid: perfil.uid,
        token,
        idEvento,
        erro,
      });
      throw new HttpsError(
        "internal",
        "Não foi possível concluir o aceite. Tente novamente.",
      );
    }

    return { ok: true, idEvento, idempotente: false };
  },
);

export const removerCoOrganizador = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O"]);

    const idEvento = texto(request.data?.idEvento ?? request.data?.id_evento);
    const uidAlvo = texto(request.data?.uid ?? request.data?.uidCoOrganizador);
    if (!idEvento || !uidAlvo) {
      throw new HttpsError("invalid-argument", "Informe o evento e o co-organizador.");
    }

    const db = admin.firestore();
    await exigirDonoEvento(db, perfil.uid, idEvento);

    await db.runTransaction(async (tx) => {
      const ref = db.collection("evento").doc(idEvento);
      const snap = await tx.get(ref);
      if (!snap.exists) {
        throw new HttpsError("not-found", "Evento não encontrado.");
      }
      const data = snap.data() ?? {};
      if (texto(data.id_usuario) === uidAlvo) {
        throw new HttpsError(
          "failed-precondition",
          "Não é possível remover o organizador principal.",
        );
      }
      const coOrgs = Array.isArray(data.co_organizadores)
        ? data.co_organizadores.map((u: unknown) => texto(u)).filter(Boolean)
        : [];
      if (!coOrgs.includes(uidAlvo)) {
        throw new HttpsError("not-found", "Co-organizador não encontrado neste evento.");
      }
      tx.update(ref, {
        co_organizadores: coOrgs.filter((u) => u !== uidAlvo),
        atualizado_em: FieldValue.serverTimestamp(),
      });
      tx.set(
        ref.collection("membros").doc(uidAlvo),
        {
          status: "removido",
          removido_em: FieldValue.serverTimestamp(),
          removido_por: perfil.uid,
        },
        { merge: true },
      );
    });

    return { ok: true };
  },
);

export const listarCoOrganizadores = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O", "A"]);

    const idEvento = texto(request.data?.idEvento ?? request.data?.id_evento);
    const evento =
      perfil.tipo === "A"
        ? await carregarEvento(admin.firestore(), idEvento)
        : await exigirGestorEvento(admin.firestore(), perfil.uid, idEvento);

    const db = admin.firestore();
    const donoUid = evento.idUsuario;
    const uids = [donoUid, ...evento.coOrganizadores].filter(Boolean);
    const membros: Array<{
      uid: string;
      papel: "dono" | "co_organizador";
      nome: string;
      email: string;
    }> = [];

    for (const uid of uids) {
      const snap = await db.collection("usuarios").doc(uid).get();
      const data = snap.data() ?? {};
      let email = texto(data.email);
      if (!email) {
        try {
          email = emailNorm((await admin.auth().getUser(uid)).email);
        } catch (_) {
          email = "";
        }
      }
      membros.push({
        uid,
        papel: uid === donoUid ? "dono" : "co_organizador",
        nome: texto(data.nome) || texto(data.nome_completo) || "Organizador",
        email,
      });
    }

    const convitesSnap = await db
      .collection(COL_CONVITES)
      .where("id_evento", "==", evento.id)
      .where("status", "==", "pendente")
      .limit(20)
      .get();

    const agora = Date.now();
    const convitesPendentes = convitesSnap.docs
      .map((doc) => {
        const d = doc.data();
        const expira = d.expira_em as Timestamp | undefined;
        return {
          token: doc.id,
          email: emailNorm(d.email),
          nome: texto(d.nome_convidado),
          expiraEm: expira?.toDate().toISOString() ?? null,
          expirado: expira ? expira.toMillis() < agora : false,
        };
      })
      .filter((c) => !c.expirado);

    return {
      idEvento: evento.id,
      souDono: perfil.uid === donoUid,
      maxCoOrganizadores: MAX_CO_ORGANIZADORES,
      membros,
      convitesPendentes,
    };
  },
);

export const consultarConviteCoOrganizador = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
    invoker: "public",
  },
  async (request) => {
    const token = texto(request.data?.token);
    if (!TOKEN_OK.test(token)) {
      throw new HttpsError("invalid-argument", "Convite inválido.");
    }

    const snap = await admin
      .firestore()
      .collection(COL_CONVITES)
      .doc(token)
      .get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Convite não encontrado.");
    }
    const d = snap.data() ?? {};
    const expira = d.expira_em as Timestamp | undefined;
    const status = texto(d.status) || "pendente";
    const expirado = expira ? expira.toMillis() < Date.now() : false;

    return {
      token,
      status: expirado && status === "pendente" ? "expirado" : status,
      email: emailNorm(d.email),
      nomeEvento: texto(d.nome_evento),
      idEvento: texto(d.id_evento),
      expiraEm: expira?.toDate().toISOString() ?? null,
    };
  },
);
