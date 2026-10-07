import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import { prefsDesligadas } from "./preferenciasNotificacao";

const REGION = "southamerica-east1";

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

async function apagarConsulta(
  query: FirebaseFirestore.Query,
): Promise<number> {
  const snap = await query.limit(200).get();
  if (snap.empty) return 0;
  const batch = admin.firestore().batch();
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  return snap.size;
}

async function apagarRecursivo(
  ref: FirebaseFirestore.DocumentReference,
): Promise<void> {
  const subcolecoes = await ref.listCollections();
  for (const colecao of subcolecoes) {
    const docs = await colecao.limit(200).get();
    for (const doc of docs.docs) {
      await apagarRecursivo(doc.ref);
    }
  }
  await ref.delete().catch(() => undefined);
}

async function apagarPorCampo(
  colecao: string,
  campo: string,
  valor: string,
): Promise<number> {
  try {
    return await apagarConsulta(
      admin.firestore().collection(colecao).where(campo, "==", valor),
    );
  } catch (error) {
    logger.warn("Falha ao apagar coleção do titular", { colecao, campo, error });
    return 0;
  }
}

async function executarExclusao(idUsuario: string): Promise<string> {
  const db = admin.firestore();
  const eventos = await db
    .collection("evento")
    .where("id_usuario", "==", idUsuario)
    .limit(50)
    .get();

  for (const evento of eventos.docs) {
    await apagarPorCampo("convidado", "id_evento", evento.id);
    await apagarPorCampo("convidados", "id_evento", evento.id);
    await apagarPorCampo("orcamento", "id_evento", evento.id);
    await apagarRecursivo(evento.ref);
  }

  await apagarPorCampo("convidado", "id_usuario", idUsuario);
  await apagarPorCampo("cotacao", "id_usuario_solicitante", idUsuario);
  await apagarPorCampo("orcamento", "id_usuario", idUsuario);
  await apagarPorCampo("inspiracoes", "id_usuario", idUsuario);
  await apagarPorCampo("tarefa", "id_usuario", idUsuario);

  const fornecedor = db.collection("fornecedor").doc(idUsuario);
  if ((await fornecedor.get()).exists) {
    await apagarRecursivo(fornecedor);
  }

  await apagarRecursivo(db.collection("usuarios").doc(idUsuario));

  try {
    await admin.storage().bucket().deleteFiles({ prefix: `usuarios/${idUsuario}/` });
  } catch (error) {
    logger.warn("Arquivos do titular não removidos", { idUsuario, error });
  }

  try {
    await admin.auth().deleteUser(idUsuario);
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code !== "auth/user-not-found") {
      logger.warn("Auth do titular não removida", { idUsuario, error });
    }
  }

  return "Conta, eventos, convidados, cotações, fornecedor e autenticação removidos. Logs de auditoria seguem o prazo de 365 dias.";
}

async function concluirPorTipo(
  idUsuario: string,
  tipo: string,
): Promise<string> {
  const db = admin.firestore();
  const ref = db.collection("usuarios").doc(idUsuario);

  if (tipo === "anonimizacao") {
    await ref.set(
      {
        nome: "Titular anonimizado",
        cpf: FieldValue.delete(),
        foto_perfil_url: FieldValue.delete(),
        telefone: FieldValue.delete(),
        preferencias_notificacao: prefsDesligadas(),
      },
      { merge: true },
    );
    const enderecos = await ref.collection("enderecos").limit(20).get();
    const batch = db.batch();
    for (const doc of enderecos.docs) batch.delete(doc.ref);
    if (!enderecos.empty) await batch.commit();
    const fornecedor = db.collection("fornecedor").doc(idUsuario);
    if ((await fornecedor.get()).exists) {
      await fornecedor.set(
        {
          nome: "Fornecedor anonimizado",
          nome_fantasia: "Fornecedor anonimizado",
          razao_social: FieldValue.delete(),
          cnpj: FieldValue.delete(),
          telefone: FieldValue.delete(),
          email: FieldValue.delete(),
          fcm_token: FieldValue.delete(),
          fcmToken: FieldValue.delete(),
        },
        { merge: true },
      );
    }
    return "Nome, documento, contato, endereço e token de aviso foram retirados.";
  }

  if (tipo === "oposicao") {
    await ref.set({ tratamento_oposto: true }, { merge: true });
    return "Oposição registrada na conta. Auditoria e reputação deixam de ser tratados como interesse livre.";
  }

  if (tipo === "revogacao") {
    await ref.set(
      { preferencias_notificacao: prefsDesligadas() },
      { merge: true },
    );
    return "Avisos de convite, cotação, chat e avaliação desligados na conta.";
  }

  if (tipo === "exclusao") {
    throw new HttpsError(
      "failed-precondition",
      "A exclusão precisa da ação de executar, para não apagar a conta por engano.",
    );
  }

  return "Pedido marcado como concluído.";
}

export const atenderSolicitacaoLgpd = onCall(
  {
    region: REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const idUsuario = texto(data.idUsuario);
    const idSolicitacao = texto(data.idSolicitacao);
    const acao = texto(data.acao);
    if (!idUsuario || !idSolicitacao) {
      throw new HttpsError("invalid-argument", "Informe o protocolo e o titular.");
    }
    if (!["em_atendimento", "concluir", "recusar", "executar_exclusao"].includes(acao)) {
      throw new HttpsError("invalid-argument", "Ação inválida.");
    }

    const db = admin.firestore();
    const ref = db
      .collection("usuarios")
      .doc(idUsuario)
      .collection("solicitacoes_lgpd")
      .doc(idSolicitacao);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Protocolo não encontrado.");
    }

    const pedido = snap.data() ?? {};
    const tipo = texto(pedido.tipo);
    let status = "em_atendimento";
    let resultado = "Pedido em atendimento.";

    if (acao === "recusar") {
      status = "recusada";
      resultado = "Pedido recusado pelo administrador.";
    } else if (acao === "executar_exclusao") {
      if (tipo !== "exclusao") {
        throw new HttpsError(
          "failed-precondition",
          "Só um pedido de exclusão pode apagar a conta.",
        );
      }
      status = "concluida";
      resultado = await executarExclusao(idUsuario);
    } else if (acao === "concluir") {
      status = "concluida";
      resultado = await concluirPorTipo(idUsuario, tipo);
    }

    const arquivo = {
      id: idSolicitacao,
      id_usuario: idUsuario,
      nome_titular: texto(pedido.nome_titular),
      email_titular: texto(pedido.email_titular),
      tipo,
      resumo: texto(pedido.resumo),
      status,
      acao,
      resultado,
      criado_em: pedido.criado_em ?? FieldValue.serverTimestamp(),
      concluido_em: FieldValue.serverTimestamp(),
      atendido_por: perfil.uid,
    };

    await db.collection("lgpd_protocolos").doc(idSolicitacao).set(arquivo);

    if (acao !== "executar_exclusao") {
      await ref.set(
        {
          status,
          resultado,
          atualizado_em: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    return { protocolo: idSolicitacao, status, resultado };
  },
);
