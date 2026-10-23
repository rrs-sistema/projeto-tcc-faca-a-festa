import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import { randomUUID } from "crypto";

import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { tentarGerarComissaoAposContratacao } from "../financeiro/comandosComissaoPlataforma";
import { gravarMensagemSistema } from "./mensagensSistemaCotacao";

const REGION = "southamerica-east1";

/**
 * Organizador fecha negócio com um fornecedor: atualiza cotação,
 * marca demais como perdedores e cria orçamento + gasto.
 */
export const fecharCotacao = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O", "A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const idCotacao = texto(data.idCotacao ?? data.id_cotacao);
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const nomeFornecedor = texto(data.nomeFornecedor ?? data.nome_fornecedor);

    if (!idCotacao || !idFornecedor) {
      throw new HttpsError("invalid-argument", "Cotação ou fornecedor inválido.");
    }

    const db = admin.firestore();
    const cotacaoRef = db.collection("cotacao").doc(idCotacao);
    const cotacaoSnap = await cotacaoRef.get();
    if (!cotacaoSnap.exists) {
      throw new HttpsError("not-found", "Cotação não encontrada.");
    }

    const cotacao = cotacaoSnap.data() ?? {};
    if (
      perfil.tipo !== "A" &&
      texto(cotacao.id_usuario_solicitante) !== perfil.uid
    ) {
      throw new HttpsError(
        "permission-denied",
        "Apenas o solicitante pode fechar esta cotação.",
      );
    }

    const statusAtual = texto(cotacao.status).toLowerCase();
    if (statusAtual === "concluida" || statusAtual === "cancelada") {
      throw new HttpsError(
        "failed-precondition",
        "Esta cotação já foi finalizada.",
      );
    }

    const fornecedorRef = cotacaoRef.collection("fornecedores").doc(idFornecedor);
    const fornecedorSnap = await fornecedorRef.get();
    if (!fornecedorSnap.exists) {
      throw new HttpsError("not-found", "Fornecedor não participa desta cotação.");
    }

    const statusFornecedor = texto(fornecedorSnap.data()?.status).toLowerCase();
    if (statusFornecedor !== "respondido" && statusFornecedor !== "respondida") {
      throw new HttpsError(
        "failed-precondition",
        "Só é possível contratar fornecedor que já enviou o preço.",
      );
    }

    const servicosSnap = await fornecedorRef.collection("servicos").get();
    let valorTotal = 0;
    let idServicoContratado: string | null = null;
    let nomeServicoContratado: string | null = null;

    for (const servico of servicosSnap.docs) {
      const item = servico.data();
      const valor = asNumber(item.valor_estimado);
      const quantidade = Math.max(1, asNumber(item.quantidade, 1));
      valorTotal += valor * quantidade;
      idServicoContratado ??= texto(item.id_produto_servico) || null;
      nomeServicoContratado ??= texto(item.nome_produto_servico) || null;
    }

    // Preferência: valor_cotado explícito da resposta do fornecedor.
    const valorCotado = asNumber(fornecedorSnap.data()?.valor_cotado);
    if (valorCotado > 0) {
      valorTotal = valorCotado;
    }

    if (valorTotal <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Cotação sem valor válido para contratar.",
      );
    }

    const idEvento = texto(cotacao.id_evento);
    if (!idEvento) {
      throw new HttpsError(
        "failed-precondition",
        "Cotação sem evento vinculado.",
      );
    }

    const usuarioSnap = await db.collection("usuarios").doc(perfil.uid).get();
    const nomeSolicitante =
      texto(data.nomeSolicitante ?? data.nome_solicitante) ||
      texto(usuarioSnap.data()?.nome) ||
      texto(cotacao.nome_usuario_solicitante) ||
      "Organizador";

    const categoriaNome = texto(cotacao.categoria_nome);
    const nomeFornecedorFinal =
      nomeFornecedor ||
      texto(fornecedorSnap.data()?.nome_fornecedor) ||
      "Fornecedor";

    const orcRef = db.collection("orcamento").doc();
    const gastoId = randomUUID();
    const batch = db.batch();

    const fornecedoresSnap = await cotacaoRef.collection("fornecedores").get();
    for (const doc of fornecedoresSnap.docs) {
      const id = texto(doc.data().id_fornecedor) || doc.id;
      batch.update(doc.ref, {
        status: id === idFornecedor ? "fechado" : "perdeuCotacao",
      });
    }

    batch.update(cotacaoRef, {
      status: "concluida",
      data_fechamento: FieldValue.serverTimestamp(),
      fechado_por: perfil.uid,
    });

    const valorCentavos = Math.round(valorTotal * 100);
    batch.set(orcRef, {
      id_orcamento: orcRef.id,
      id_cotacao: idCotacao,
      id_necessidade: idCotacao,
      id_evento: idEvento,
      id_fornecedor: idFornecedor,
      nome_fornecedor: nomeFornecedorFinal,
      custo_estimado: valorTotal,
      valor_contratado: valorTotal,
      valor_contratado_centavos: valorCentavos,
      id_solicitante: perfil.uid,
      nome_solicitante: nomeSolicitante,
      anotacoes: `Orçamento gerado automaticamente após fechamento da cotação "${categoriaNome}".`,
      status: "fechado",
      orcamento_fechado: true,
      alternativa_ativa: true,
      contrato_financeiro: {
        schema: 1,
        id_contrato: orcRef.id,
        id_evento: idEvento,
        id_orcamento: orcRef.id,
        id_necessidade: idCotacao,
        valor: { centavos: valorCentavos, moeda: "BRL" },
        estado_comercial: "contratado",
        estado_execucao: "nao_iniciado",
        perspectiva: "evento_pagador",
        retencao: { centavos: 0, moeda: "BRL" },
        reembolso: { centavos: 0, moeda: "BRL" },
        historico: [],
        snapshot_identidade: {
          schema: 1,
          origem: "fechar_cotacao",
          capturado_em: new Date().toISOString(),
          id_evento: idEvento,
          nome_evento: null,
          id_organizador: null,
          nome_organizador: null,
          id_contratante: perfil.uid,
          nome_contratante: nomeSolicitante,
          id_pagador: perfil.uid,
          nome_pagador: nomeSolicitante,
          id_fornecedor: idFornecedor,
          nome_fornecedor: nomeFornecedorFinal,
          id_servico: idServicoContratado,
          nome_servico: nomeServicoContratado || categoriaNome || null,
          descricao_escopo:
            categoriaNome || nomeServicoContratado || null,
          quantidade: null,
          unidade: null,
          valor_centavos: valorCentavos,
          id_operador_acompanhamento: null,
        },
        origem: "fechar_cotacao",
      },
      estado_execucao: "nao_iniciado",
      id_servico_fornecido: idServicoContratado || "",
      nome: nomeServicoContratado || categoriaNome || "",
      data_cadastro: FieldValue.serverTimestamp(),
    });
    batch.set(orcRef.collection("obrigacoes").doc("parcela-1"), {
      schema: 1,
      id_obrigacao: "parcela-1",
      id_contrato: orcRef.id,
      id_orcamento: orcRef.id,
      id_evento: idEvento,
      valor: { centavos: valorCentavos, moeda: "BRL" },
      pago_liquido: { centavos: 0, moeda: "BRL" },
      estado_liquidacao: "aberta",
      numero_parcela: 1,
      origem: "fechar_cotacao",
    });

    batch.set(orcRef.collection("orcamento_gasto").doc(gastoId), {
      id_gasto: gastoId,
      id_orcamento: orcRef.id,
      nome: `Serviço contratado – ${categoriaNome || "cotação"}`,
      custo: valorTotal,
      pago: 0,
      id_servico_contratado: idServicoContratado,
      nome_servico_contratado: nomeServicoContratado,
      id_servico: idServicoContratado,
      nome_servico: nomeServicoContratado,
      data_cadastro: FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } catch (error) {
      logger.error("Falha ao fechar cotação", {
        uid: perfil.uid,
        idCotacao,
        erro: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError("internal", "Não foi possível fechar o negócio.");
    }

    // Mensagens de sistema: vencedor e perdedores.
    const valorFmt = valorTotal.toFixed(2).replace(".", ",");
    await gravarMensagemSistema(
      db,
      idCotacao,
      idFornecedor,
      `Contrato fechado em R$ ${valorFmt}. Próximo passo: pagamento pela plataforma (declaração ao app).`,
    );
    for (const doc of fornecedoresSnap.docs) {
      const id = texto(doc.data().id_fornecedor) || doc.id;
      if (id === idFornecedor) continue;
      await gravarMensagemSistema(
        db,
        idCotacao,
        id,
        "Esta cotação foi fechada com outro fornecedor.",
      );
    }

    // Gatilho contratacao_confirmada: só gera se política ativa válida existir.
    await tentarGerarComissaoAposContratacao({
      idEvento,
      idContrato: orcRef.id,
      baseBrutaCentavos: valorCentavos,
      idFornecedor,
      idPagador: idFornecedor,
      autorId: perfil.uid,
    });

    return {
      ok: true,
      idEvento,
      idOrcamento: orcRef.id,
      valorContratado: valorTotal,
    };
  },
);

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

function asNumber(value: unknown, fallback = 0): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const n = Number(value.replace(",", "."));
    return Number.isFinite(n) ? n : fallback;
  }
  return fallback;
}
