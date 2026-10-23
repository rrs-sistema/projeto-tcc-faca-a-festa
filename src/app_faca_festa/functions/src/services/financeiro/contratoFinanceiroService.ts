import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { dinheiro, deMapa, deReaisLegado, Dinheiro, reaisParaCentavosArredondado } from "./dinheiro";
import {
  montarSnapshotAceite,
  nomeEventoDeDoc,
  nomeFornecedorDeDoc,
  nomeUsuarioDeDoc,
} from "./contratacaoIdentidadeService";

export type EntradaContrato = {
  idEvento: string;
  idOrcamento: string;
  valorCentavos?: number;
  valorReais?: number;
  idNecessidade?: string;
  autorId: string;
  motivo?: string;
};

export type EntradaCancelamento = {
  idEvento: string;
  idOrcamento: string;
  autorId: string;
  motivo: string;
  retencaoCentavos?: number;
  reembolsoCentavos?: number;
};

export async function registrarOuAtualizarContrato(
  db: Firestore,
  entrada: EntradaContrato,
): Promise<{ idContrato: string; valor: Dinheiro }> {
  const ref = db.collection("orcamento").doc(entrada.idOrcamento);
  const centavos = resolverCentavos(entrada);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Orçamento não encontrado.");
    }
    const data = snap.data() ?? {};
    if (String(data.id_evento ?? "") !== entrada.idEvento) {
      throw new HttpsError("failed-precondition", "Orçamento de outro evento.");
    }

    const anterior = (data.contrato_financeiro as Record<string, unknown>) ?? {};
    const historico = Array.isArray(anterior.historico)
      ? [...anterior.historico]
      : [];
    if (anterior.valor || data.valor_contratado != null) {
      historico.push({
        tipo: "alteracao_aprovada",
        autor_id: entrada.autorId,
        em: new Date().toISOString(),
        motivo: entrada.motivo ?? "Atualização de contrato",
        valor_anterior: anterior.valor ?? deReaisLegado(data.valor_contratado),
        valor_novo: dinheiro(centavos),
      });
    }

    // Leituras auxiliares na mesma transação (evento/fornecedor/usuário).
    const idFornecedor =
      typeof data.id_fornecedor === "string" ? data.id_fornecedor.trim() : "";
    const idSolicitante =
      typeof data.id_solicitante === "string" ? data.id_solicitante.trim() : "";
    const eventoRef = db.collection("evento").doc(entrada.idEvento);
    const eventoSnap = await tx.get(eventoRef);
    const eventoData = (eventoSnap.data() ?? {}) as Record<string, unknown>;
    const idOrganizador =
      typeof eventoData.id_usuario === "string"
        ? eventoData.id_usuario.trim()
        : "";

    const fornSnap = idFornecedor
      ? await tx.get(db.collection("fornecedor").doc(idFornecedor))
      : null;
    const orgSnap = idOrganizador
      ? await tx.get(db.collection("usuarios").doc(idOrganizador))
      : null;
    const solSnap =
      idSolicitante && idSolicitante !== idOrganizador
        ? await tx.get(db.collection("usuarios").doc(idSolicitante))
        : orgSnap;

    const snapshotExistente = anterior.snapshot_identidade;
    const snapshot =
      snapshotExistente && typeof snapshotExistente === "object"
        ? snapshotExistente
        : montarSnapshotAceite({
            origem: "comando_contrato",
            idEvento: entrada.idEvento,
            nomeEvento: nomeEventoDeDoc(eventoData),
            idOrganizador: idOrganizador || null,
            nomeOrganizador: nomeUsuarioDeDoc(
              orgSnap?.data() as Record<string, unknown> | undefined,
            ),
            idContratante: idSolicitante || idOrganizador || null,
            nomeContratante:
              (typeof data.nome_solicitante === "string" &&
              data.nome_solicitante.trim()
                ? data.nome_solicitante.trim()
                : null) ||
              nomeUsuarioDeDoc(
                solSnap?.data() as Record<string, unknown> | undefined,
              ),
            idPagador: idSolicitante || idOrganizador || null,
            nomePagador:
              nomeUsuarioDeDoc(
                solSnap?.data() as Record<string, unknown> | undefined,
              ) || null,
            idFornecedor: idFornecedor || null,
            nomeFornecedor:
              (typeof data.nome_fornecedor === "string" &&
              data.nome_fornecedor.trim()
                ? data.nome_fornecedor.trim()
                : null) ||
              nomeFornecedorDeDoc(
                fornSnap?.data() as Record<string, unknown> | undefined,
              ),
            idServico:
              (typeof data.id_servico_fornecido === "string" &&
              data.id_servico_fornecido.trim()
                ? data.id_servico_fornecido.trim()
                : null) ||
              (typeof data.id_servico === "string" && data.id_servico.trim()
                ? data.id_servico.trim()
                : null),
            nomeServico:
              (typeof data.nome === "string" && data.nome.trim()
                ? data.nome.trim()
                : null) ||
              (typeof data.nome_servico === "string" && data.nome_servico.trim()
                ? data.nome_servico.trim()
                : null),
            descricaoEscopo:
              typeof data.anotacoes === "string" ? data.anotacoes : null,
            valorCentavos: centavos,
          });

    const contrato = {
      schema: 1,
      id_contrato: entrada.idOrcamento,
      id_evento: entrada.idEvento,
      id_orcamento: entrada.idOrcamento,
      id_necessidade: entrada.idNecessidade ?? data.id_necessidade ?? null,
      valor: dinheiro(centavos),
      estado_comercial: "contratado",
      estado_execucao: anterior.estado_execucao ?? "nao_iniciado",
      perspectiva: "evento_pagador",
      retencao: deMapa(anterior.retencao) ?? dinheiro(0),
      reembolso: deMapa(anterior.reembolso) ?? dinheiro(0),
      historico,
      snapshot_identidade: snapshot,
      origem: "comando_contrato",
      atualizado_em: FieldValue.serverTimestamp(),
    };

    tx.update(ref, {
      contrato_financeiro: contrato,
      valor_contratado: centavos / 100,
      valor_contratado_centavos: centavos,
      orcamento_fechado: true,
      status: "fechado",
      alternativa_ativa: true,
      estado_execucao: data.estado_execucao ?? "nao_iniciado",
    });

    const obrigacaoRef = ref.collection("obrigacoes").doc("parcela-1");
    const obrSnap = await tx.get(obrigacaoRef);
    if (!obrSnap.exists) {
      tx.set(obrigacaoRef, {
        schema: 1,
        id_obrigacao: "parcela-1",
        id_contrato: entrada.idOrcamento,
        id_orcamento: entrada.idOrcamento,
        id_evento: entrada.idEvento,
        valor: dinheiro(centavos),
        pago_liquido: dinheiro(0),
        estado_liquidacao: "aberta",
        numero_parcela: 1,
        origem: "contrato",
      });
    } else {
      const pago = deMapa(obrSnap.data()?.pago_liquido)?.centavos ?? 0;
      tx.update(obrigacaoRef, {
        valor: dinheiro(centavos),
        estado_liquidacao:
          pago <= 0 ? "aberta" : pago >= centavos ? "quitada" : "parcial",
      });
    }

    return { idContrato: entrada.idOrcamento, valor: dinheiro(centavos) };
  });
}

export async function cancelarContrato(
  db: Firestore,
  entrada: EntradaCancelamento,
): Promise<{ saldoExplicadoCentavos: number }> {
  const ref = db.collection("orcamento").doc(entrada.idOrcamento);
  const retencao = entrada.retencaoCentavos ?? 0;
  const reembolso = entrada.reembolsoCentavos ?? 0;
  if (retencao < 0 || reembolso < 0) {
    throw new HttpsError("invalid-argument", "Retenção/reembolso inválidos.");
  }

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Orçamento não encontrado.");
    }
    const data = snap.data() ?? {};
    if (String(data.id_evento ?? "") !== entrada.idEvento) {
      throw new HttpsError("failed-precondition", "Orçamento de outro evento.");
    }

    const anterior = (data.contrato_financeiro as Record<string, unknown>) ?? {};
    const valor =
      deMapa(anterior.valor) ??
      deReaisLegado(data.valor_contratado) ??
      deReaisLegado(data.custo_estimado) ??
      dinheiro(0);
    const historico = Array.isArray(anterior.historico)
      ? [...anterior.historico]
      : [];
    historico.push({
      tipo: "cancelamento",
      autor_id: entrada.autorId,
      em: new Date().toISOString(),
      motivo: entrada.motivo,
      retencao: dinheiro(retencao),
      reembolso: dinheiro(reembolso),
      valor_contrato: valor,
    });

    // Pagamentos já registrados permanecem; saldo explicado:
    // valor - pago_liquido - reembolso + retencao (pago lido das obrigações).
    const obrRef = ref.collection("obrigacoes").doc("parcela-1");
    const obr = await tx.get(obrRef);
    const pago = deMapa(obr.data()?.pago_liquido)?.centavos ?? 0;
    const saldo = valor.centavos - pago - reembolso + retencao;

    tx.update(ref, {
      status: "cancelado",
      orcamento_fechado: false,
      contrato_financeiro: {
        ...anterior,
        schema: 1,
        id_contrato: entrada.idOrcamento,
        id_evento: entrada.idEvento,
        id_orcamento: entrada.idOrcamento,
        valor,
        estado_comercial: "cancelado",
        perspectiva: "evento_pagador",
        retencao: dinheiro(retencao),
        reembolso: dinheiro(reembolso),
        historico,
        cancelado_em: Timestamp.now().toDate().toISOString(),
        motivo_cancelamento: entrada.motivo,
        origem: anterior.origem ?? "comando_contrato",
      },
    });

    if (obr.exists) {
      tx.update(obrRef, {
        estado_liquidacao: "cancelada",
        retencao: dinheiro(retencao),
        reembolso: dinheiro(reembolso),
      });
    }

    return { saldoExplicadoCentavos: saldo };
  });
}

function resolverCentavos(entrada: EntradaContrato): number {
  if (typeof entrada.valorCentavos === "number") {
    return dinheiro(entrada.valorCentavos).centavos;
  }
  if (typeof entrada.valorReais === "number") {
    return reaisParaCentavosArredondado(entrada.valorReais);
  }
  throw new HttpsError("invalid-argument", "Informe o valor do contrato.");
}
