import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import { admin } from "../../shared/firebaseAdmin";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";

const REGION = "southamerica-east1";
const MAX_OBS = 2000;
const MAX_SERVICOS = 40;
const MAX_FORNECEDORES = 15;

type ServicoEntrada = {
  idFornecedor: string;
  idProdutoServico: string;
  quantidade: number;
};

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

function precoEfetivo(data: Record<string, unknown>): number {
  const promo = asNumber(data.preco_promocao);
  if (promo > 0) return promo;
  return asNumber(data.preco);
}

/**
 * Cria cotação + fornecedores + serviços em lote atômico.
 * Preços vêm de `fornecedor_servico` (não confiar no client).
 */
export const criarCotacao = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    cors: true,
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["O", "A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const categoriaNome = texto(data.categoriaNome ?? data.categoria_nome);
    const observacao = texto(data.observacao).slice(0, MAX_OBS);
    const valorEstimadoTotal = Math.max(
      0,
      asNumber(data.valorEstimadoTotal ?? data.valor_estimado_total),
    );

    if (!idEvento) {
      throw new HttpsError(
        "failed-precondition",
        "Selecione um evento antes de enviar a cotação.",
      );
    }

    const eventoSnap = await admin.firestore().collection("evento").doc(idEvento).get();
    if (!eventoSnap.exists) {
      throw new HttpsError("not-found", "Evento não encontrado.");
    }
    const evento = eventoSnap.data() ?? {};
    if (perfil.tipo !== "A" && evento.id_usuario !== perfil.uid) {
      throw new HttpsError(
        "permission-denied",
        "Você só pode cotar para o seu próprio evento.",
      );
    }

    const fornecedoresIds = normalizarIds(data.fornecedoresSelecionados ?? data.fornecedores);
    const servicos = normalizarServicos(data.servicos);
    if (fornecedoresIds.length === 0) {
      throw new HttpsError("invalid-argument", "Selecione pelo menos um fornecedor.");
    }
    if (servicos.length === 0) {
      throw new HttpsError("invalid-argument", "Selecione ao menos um serviço.");
    }

    const dataLimite = parseDataLimite(data.dataLimiteResposta ?? data.data_limite_resposta);

    const usuarioSnap = await admin.firestore().collection("usuarios").doc(perfil.uid).get();
    const nomeUsuario = texto(usuarioSnap.data()?.nome) || "Organizador";

    const db = admin.firestore();
    const cotacaoRef = db.collection("cotacao").doc();
    const batch = db.batch();

    batch.set(cotacaoRef, {
      id_evento: idEvento,
      id_usuario_solicitante: perfil.uid,
      nome_usuario_solicitante: nomeUsuario,
      observacao,
      valor_estimado_total: valorEstimadoTotal,
      data_limite_resposta: Timestamp.fromDate(dataLimite),
      data_envio: FieldValue.serverTimestamp(),
      status: "pendente",
      visualizado: false,
      categoria_nome: categoriaNome,
    });

    for (const idFornecedor of fornecedoresIds) {
      const fornecedorSnap = await db.collection("fornecedor").doc(idFornecedor).get();
      if (!fornecedorSnap.exists) {
        throw new HttpsError(
          "not-found",
          `Fornecedor não encontrado (${idFornecedor}).`,
        );
      }
      const fornecedor = fornecedorSnap.data() ?? {};
      const fornecedorRef = cotacaoRef.collection("fornecedores").doc(idFornecedor);

      batch.set(fornecedorRef, {
        id_fornecedor: idFornecedor,
        nome_fornecedor: texto(fornecedor.razao_social) || "Fornecedor",
        email: texto(fornecedor.email),
        telefone: texto(fornecedor.telefone),
        status: "aguardando",
        data_envio: FieldValue.serverTimestamp(),
        respondido: false,
      });

      const servicosDoFornecedor = servicos.filter((s) => s.idFornecedor === idFornecedor);
      if (servicosDoFornecedor.length === 0) {
        throw new HttpsError(
          "invalid-argument",
          "Há fornecedor sem serviços selecionados.",
        );
      }

      for (const item of servicosDoFornecedor) {
        const vinculoSnap = await db
          .collection("fornecedor_servico")
          .where("id_fornecedor", "==", item.idFornecedor)
          .where("id_produto_servico", "==", item.idProdutoServico)
          .limit(1)
          .get();

        if (vinculoSnap.empty) {
          throw new HttpsError(
            "failed-precondition",
            "Serviço não disponível para este fornecedor.",
          );
        }

        const vinculo = vinculoSnap.docs[0].data() as Record<string, unknown>;
        if (vinculo.ativo === false) {
          throw new HttpsError(
            "failed-precondition",
            "Um dos serviços selecionados está inativo.",
          );
        }

        const preco = precoEfetivo(vinculo);
        const catalogoSnap = await db
          .collection("servico_produto")
          .doc(item.idProdutoServico)
          .get();
        const nomeServico =
          texto(catalogoSnap.data()?.nome) ||
          texto(vinculo.nome_produto_servico) ||
          "Serviço";

        const servicoRef = fornecedorRef.collection("servicos").doc(item.idProdutoServico);
        batch.set(servicoRef, {
          id_produto_servico: item.idProdutoServico,
          nome_produto_servico: nomeServico,
          quantidade: item.quantidade,
          valor_estimado: preco,
          subtotal: item.quantidade * preco,
          status: "pendente",
          data_adicionado: FieldValue.serverTimestamp(),
        });
      }
    }

    try {
      await batch.commit();
    } catch (error) {
      logger.error("Falha ao gravar cotação", {
        uid: perfil.uid,
        idEvento,
        erro: error instanceof Error ? error.message : String(error),
      });
      throw new HttpsError("internal", "Não foi possível enviar a cotação.");
    }

    return {
      ok: true,
      idCotacao: cotacaoRef.id,
      notificacaoEnviada: false,
    };
  },
);

function normalizarIds(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  const ids = raw
    .map((v) => texto(v))
    .filter((v) => v.length > 0);
  return [...new Set(ids)].slice(0, MAX_FORNECEDORES);
}

function normalizarServicos(raw: unknown): ServicoEntrada[] {
  if (!Array.isArray(raw)) return [];
  const lista: ServicoEntrada[] = [];
  for (const item of raw.slice(0, MAX_SERVICOS)) {
    if (!item || typeof item !== "object") continue;
    const row = item as Record<string, unknown>;
    const idFornecedor = texto(row.idFornecedor ?? row.id_fornecedor);
    const idProdutoServico = texto(
      row.idProdutoServico ?? row.id_produto_servico,
    );
    const quantidade = Math.max(1, Math.floor(asNumber(row.quantidade, 1)));
    if (!idFornecedor || !idProdutoServico) continue;
    lista.push({ idFornecedor, idProdutoServico, quantidade });
  }
  return lista;
}

function parseDataLimite(raw: unknown): Date {
  const agora = new Date();
  const fallback = new Date(agora.getTime() + 7 * 24 * 60 * 60 * 1000);
  if (raw == null || raw === "") return fallback;

  if (typeof raw === "string" || typeof raw === "number") {
    const parsed = new Date(raw);
    if (!Number.isNaN(parsed.getTime()) && parsed.getTime() >= agora.getTime() - 60_000) {
      return parsed;
    }
  }
  return fallback;
}
