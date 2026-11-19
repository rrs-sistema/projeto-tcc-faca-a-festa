import { onCall } from "../../shared/callableComMfa";
import { HttpsError } from "firebase-functions/v2/https";
import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
} from "firebase-admin/firestore";
import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { recomendarFornecedoresParaEventoService } from "../../services/fornecedores/fornecedorRecomendacaoService";
import { usuarioPermiteAviso } from "../lgpd/preferenciasNotificacao";

const REGION = "southamerica-east1";

function texto(value: unknown, fallback = ""): string {
  if (value === null || value === undefined) return fallback;
  const t = String(value).trim();
  return t.length > 0 && t !== "null" ? t : fallback;
}

function asInt(value: unknown, fallback: number): number {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string") {
    const n = Number(value);
    if (Number.isFinite(n)) return Math.trunc(n);
  }
  return fallback;
}

/**
 * Ações comerciais do admin sobre um evento-lead:
 * sugerir_fornecedores | marcar_follow_up | limpar_follow_up | nudge_organizador
 */
export const gerenciarOportunidadeEventoAdmin = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const data = (request.data || {}) as Record<string, unknown>;
    const acao = texto(data.acao ?? data.action).toLowerCase();
    const idEvento = texto(data.idEvento ?? data.id_evento);
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "idEvento é obrigatório.");
    }

    const db = admin.firestore();
    const eventoRef = db.collection("evento").doc(idEvento);
    const eventoSnap = await eventoRef.get();
    if (!eventoSnap.exists) {
      throw new HttpsError("not-found", "Evento não encontrado.");
    }
    const evento = eventoSnap.data() || {};
    const idOrganizador = texto(
      evento.idUsuario ?? evento.id_usuario ?? evento.usuarioId,
    );
    const nomeEvento = texto(
      evento.nomeEvento ?? evento.nome_evento ?? evento.nome,
      "seu evento",
    );

    switch (acao) {
      case "sugerir_fornecedores":
        return sugerirFornecedores({
          idEvento,
          idOrganizador,
          limite: asInt(data.limite, 5),
          modoDemo: data.modoDemo === true || data.modo_demo === true,
        });
      case "marcar_follow_up":
        return marcarFollowUp({
          eventoRef,
          adminUid: perfil.uid,
          nota: texto(data.nota ?? data.observacao),
          proximoContatoIso: texto(data.proximoContato ?? data.proximo_contato),
        });
      case "limpar_follow_up":
        await eventoRef.update({
          follow_up_comercial: FieldValue.delete(),
          followUpComercial: FieldValue.delete(),
        });
        return { ok: true, followUp: null };
      case "nudge_organizador":
        return nudgeOrganizador({
          db,
          eventoRef,
          evento,
          idEvento,
          idOrganizador,
          nomeEvento,
          adminUid: perfil.uid,
          mensagem: texto(
            data.mensagem,
            `Há fornecedores alinhados a "${nomeEvento}". Abra cotações para avançar o planejamento.`,
          ),
          gerarRecomendacoes: data.gerarRecomendacoes !== false,
          limite: asInt(data.limite, 5),
        });
      default:
        throw new HttpsError(
          "invalid-argument",
          "Ação inválida. Use sugerir_fornecedores, marcar_follow_up, limpar_follow_up ou nudge_organizador.",
        );
    }
  },
);

async function sugerirFornecedores(params: {
  idEvento: string;
  idOrganizador: string;
  limite: number;
  modoDemo: boolean;
}) {
  const uid = params.idOrganizador || "admin-preview";
  const recomendacoes = await recomendarFornecedoresParaEventoService({
    uid,
    payload: {
      idEvento: params.idEvento,
      limite: Math.max(1, Math.min(params.limite, 10)),
      modoDemo: params.modoDemo,
    },
  });

  return {
    ok: true,
    idEvento: params.idEvento,
    total: recomendacoes.length,
    recomendacoes: recomendacoes.map((r) => ({
      idFornecedor: r.fornecedorId ?? r.id_fornecedor,
      nomeFornecedor: r.nomeFornecedor ?? r.nome_fornecedor,
      score: r.score,
      nivel: r.nivel,
      nivelLabel: r.nivelLabel ?? r.nivel_label,
      motivoPrincipal: r.motivoPrincipal ?? r.motivo_principal,
      categoriaPrincipal: r.categoriaPrincipal ?? r.categoria_principal,
      mediaAvaliacoes: r.mediaAvaliacoes ?? r.media_avaliacoes,
      totalAvaliacoes: r.totalAvaliacoes ?? r.total_avaliacoes,
      distanciaKm: r.distanciaKm ?? r.distancia_km,
    })),
  };
}

async function marcarFollowUp(params: {
  eventoRef: DocumentReference;
  adminUid: string;
  nota: string;
  proximoContatoIso: string;
}) {
  let proximoContato: Timestamp | null = null;
  if (params.proximoContatoIso) {
    const d = new Date(params.proximoContatoIso);
    if (!Number.isFinite(d.getTime())) {
      throw new HttpsError("invalid-argument", "proximoContato inválido.");
    }
    proximoContato = Timestamp.fromDate(d);
  }

  const followUp = {
    marcado: true,
    em: FieldValue.serverTimestamp(),
    por: params.adminUid,
    nota: params.nota || null,
    proximo_contato: proximoContato,
  };

  await params.eventoRef.update({
    follow_up_comercial: followUp,
    followUpComercial: followUp,
  });

  return {
    ok: true,
    followUp: {
      marcado: true,
      nota: params.nota || null,
      proximoContato: params.proximoContatoIso || null,
      por: params.adminUid,
    },
  };
}

async function nudgeOrganizador(params: {
  db: Firestore;
  eventoRef: DocumentReference;
  evento: DocumentData;
  idEvento: string;
  idOrganizador: string;
  nomeEvento: string;
  adminUid: string;
  mensagem: string;
  gerarRecomendacoes: boolean;
  limite: number;
}) {
  if (!params.idOrganizador) {
    throw new HttpsError(
      "failed-precondition",
      "Evento sem organizador vinculado para receber o aviso.",
    );
  }

  let recomendacoes: Awaited<ReturnType<typeof sugerirFornecedores>>["recomendacoes"] =
    [];
  if (params.gerarRecomendacoes) {
    const sugestao = await sugerirFornecedores({
      idEvento: params.idEvento,
      idOrganizador: params.idOrganizador,
      limite: params.limite,
      modoDemo: false,
    });
    recomendacoes = sugestao.recomendacoes;
  }

  const agora = FieldValue.serverTimestamp();
  const nudge = {
    em: agora,
    por: params.adminUid,
    mensagem: params.mensagem,
    qtd_fornecedores: recomendacoes.length,
  };

  const avisoRef = params.db
    .collection("usuarios")
    .doc(params.idOrganizador)
    .collection("avisos")
    .doc();

  const batch = params.db.batch();
  batch.update(params.eventoRef, {
    nudge_cotacao: nudge,
    nudgeCotacao: nudge,
  });
  batch.set(avisoRef, {
    tipo: "nudge_cotacao",
    titulo: "Fornecedores sugeridos para o seu evento",
    mensagem: params.mensagem,
    id_evento: params.idEvento,
    nome_evento: params.nomeEvento,
    lido: false,
    criado_em: agora,
    rota: "/fornecedores",
    qtd_fornecedores: recomendacoes.length,
    autor_admin: params.adminUid,
  });
  await batch.commit();

  let pushEnviado = false;
  try {
    const usuarioSnap = await params.db
      .collection("usuarios")
      .doc(params.idOrganizador)
      .get();
    const usuario = usuarioSnap.data() || {};
    const permite = await usuarioPermiteAviso(
      params.db,
      params.idOrganizador,
      "cotacoes",
    );
    const token = texto(usuario.fcm_token ?? usuario.fcmToken);
    if (permite && token) {
      await admin.messaging().send({
        token,
        notification: {
          title: "Avance nas cotações",
          body: params.mensagem.slice(0, 160),
        },
        data: {
          screen: "fornecedores",
          id_evento: params.idEvento,
          tipo: "nudge_cotacao",
        },
      });
      pushEnviado = true;
    }
  } catch {
    pushEnviado = false;
  }

  return {
    ok: true,
    idAviso: avisoRef.id,
    pushEnviado,
    totalRecomendacoes: recomendacoes.length,
    recomendacoes,
  };
}
