import { createHash } from "crypto";
import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError } from "firebase-functions/v2/https";
import { ClienteAsaas, PagamentoAsaas } from "./asaasHttp";
import {
  cobrancaConfere,
  confirmadoLimitado,
  cpfValido,
  LIMITE_PAGAMENTOS_CONTRATO,
  mapearStatusAsaas,
  reaisDeCentavos,
  referenciaExterna,
  valorCobradoCentavos,
  valorContratadoDoOrcamento,
  vencimentoPix,
  lerReferenciaExterna,
} from "./asaasPixRegras";
import { contratado } from "./liberacaoRepasseService";
import { dinheiro } from "./dinheiro";
import {
  COL_ALOCACOES,
  COL_AUDITORIA,
  COL_RECEBIMENTOS,
} from "./intermediacaoPersistenciaService";

export const COL_COBRANCAS_PIX = "plataforma_cobrancas_pix";

const JANELA_CRIANDO_MS = 120_000;

export type RespostaCobrancaPix = {
  ok: true;
  reutilizada: boolean;
  aviso: string | null;
  cobranca: {
    id: string;
    status: string;
    valorCentavos: number;
    copiaCola: string;
    qrCodeBase64: string;
    expiraEm: string | null;
    nomeServico: string | null;
  };
};

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function millis(v: unknown): number {
  if (v instanceof Timestamp) return v.toMillis();
  if (v && typeof v === "object" && "toMillis" in v) {
    const fn = (v as { toMillis?: () => number }).toMillis;
    if (typeof fn === "function") return fn.call(v);
  }
  if (typeof v === "string") {
    const t = Date.parse(v);
    return Number.isNaN(t) ? 0 : t;
  }
  return 0;
}

function iso(v: unknown): string | null {
  const ms = millis(v);
  return ms > 0 ? new Date(ms).toISOString() : null;
}

function idSeguro(v: unknown, nome: string): string {
  const t = texto(v);
  if (!t || t.length > 128 || t.includes("/") || t.includes("|")) {
    throw new HttpsError("invalid-argument", `${nome} inválido.`);
  }
  return t;
}

function respostaDe(
  id: string,
  d: FirebaseFirestore.DocumentData,
  extra: { reutilizada: boolean; aviso: string | null },
): RespostaCobrancaPix {
  return {
    ok: true,
    reutilizada: extra.reutilizada,
    aviso: extra.aviso,
    cobranca: {
      id,
      status: texto(d.status) || "PENDING",
      valorCentavos: Number(d.valor_centavos ?? 0),
      copiaCola: texto(d.copia_cola),
      qrCodeBase64: texto(d.qr_code_base64),
      expiraEm: iso(d.expira_em),
      nomeServico: texto(d.nome_servico) || null,
    },
  };
}

async function pagador(
  db: Firestore,
  entrada: { autorId: string; emailAuth: string | null; nomeAuth: string | null; cpfInformado: string | null },
): Promise<{ nome: string; email: string; cpf: string }> {
  const userRef = db.collection("usuarios").doc(entrada.autorId);
  const snap = await userRef.get();
  const data = snap.data() ?? {};
  const cpfPerfil = cpfValido(data.cpf);
  const cpfInformado = cpfValido(entrada.cpfInformado);
  const cpf = cpfPerfil ?? cpfInformado;
  if (!cpf) {
    throw new HttpsError(
      "failed-precondition",
      "Informe um CPF válido para gerar o Pix.",
    );
  }
  if (!cpfPerfil && snap.exists && cpfInformado) {
    await userRef.set({ cpf }, { merge: true });
  }
  const email = (texto(data.email) || texto(entrada.emailAuth)).toLowerCase();
  if (!email.includes("@") || email.length > 160) {
    throw new HttpsError("failed-precondition", "O organizador precisa de um e-mail válido.");
  }
  const nomeBruto = texto(data.nome) || texto(data.nome_completo) || texto(entrada.nomeAuth) || "Organizador";
  const nome = nomeBruto.replace(/[\r\n\t]/g, " ").slice(0, 80);
  return { nome, email, cpf };
}

export async function criarCobrancaPixServico(
  db: Firestore,
  entrada: {
    idEvento: string;
    idOrcamento: string;
    valorCentavos: number | null;
    cpfInformado: string | null;
    autorId: string;
    emailAuth: string | null;
    nomeAuth: string | null;
  },
  asaas: ClienteAsaas,
): Promise<RespostaCobrancaPix> {
  const idEvento = idSeguro(entrada.idEvento, "Evento");
  const idOrcamento = idSeguro(entrada.idOrcamento, "Contrato");
  const quem = await pagador(db, entrada);
  const orcRef = db.collection("orcamento").doc(idOrcamento);
  const agora = Date.now();

  const reservado = await db.runTransaction(async (tx) => {
    const orcSnap = await tx.get(orcRef);
    if (!orcSnap.exists) throw new HttpsError("not-found", "Contrato não encontrado.");
    const orc = orcSnap.data() ?? {};
    if (texto(orc.id_evento) !== idEvento) {
      throw new HttpsError("failed-precondition", "Contrato de outro evento.");
    }
    if (!contratado(orc)) {
      throw new HttpsError("failed-precondition", "O serviço ainda não está contratado.");
    }
    const alocSnap = await tx.get(
      db.collection(COL_ALOCACOES).where("id_orcamento", "==", idOrcamento).limit(50),
    );
    if (alocSnap.size >= 50) {
      throw new HttpsError("failed-precondition", "Não foi possível conferir o saldo deste contrato.");
    }
    let alocado = 0;
    for (const doc of alocSnap.docs) alocado += Number(doc.data().valor_centavos ?? 0);
    const contratadoCentavos = valorContratadoDoOrcamento(orc);
    const aPagar = Math.max(0, contratadoCentavos - confirmadoLimitado(contratadoCentavos, alocado));
    const valor = valorCobradoCentavos(entrada.valorCentavos, aPagar);
    if (!valor.ok) throw new HttpsError("failed-precondition", valor.motivo);

    const cobSnap = await tx.get(
      db.collection(COL_COBRANCAS_PIX).where("id_orcamento", "==", idOrcamento).limit(20),
    );
    if (cobSnap.size >= 20) {
      throw new HttpsError("failed-precondition", "Há cobranças demais neste contrato. Fale com a plataforma.");
    }
    let aberta: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    const presas: FirebaseFirestore.QueryDocumentSnapshot[] = [];
    let ocupados = 0;
    for (const doc of cobSnap.docs) {
      const d = doc.data();
      const status = texto(d.status);
      if (status === "PENDING" && texto(d.copia_cola) && millis(d.expira_em) > agora) {
        if (!aberta) aberta = doc;
        ocupados += 1;
        continue;
      }
      if (status === "APPROVED") ocupados += 1;
      if (status === "CRIANDO" && agora - millis(d.criado_em) < JANELA_CRIANDO_MS) {
        throw new HttpsError(
          "failed-precondition",
          "Um Pix está sendo gerado. Aguarde um instante e tente de novo.",
        );
      }
      if (status === "CRIANDO") presas.push(doc);
    }
    if (!aberta && ocupados >= LIMITE_PAGAMENTOS_CONTRATO) {
      throw new HttpsError(
        "failed-precondition",
        "Este serviço já tem dois pagamentos. O contratado pode ser pago em até duas vezes.",
      );
    }
    for (const doc of presas) {
      tx.update(doc.ref, {
        status: "FALHA",
        atualizado_em: FieldValue.serverTimestamp(),
      });
    }
    if (aberta) {
      const d = aberta.data();
      const mesmoValor = Number(d.valor_centavos ?? 0) === valor.centavos;
      return {
        tipo: "reuso" as const,
        id: aberta.id,
        dados: d,
        aviso: mesmoValor
          ? null
          : "Há um Pix em aberto. Pague esse valor ou aguarde expirar para gerar outro.",
      };
    }

    const ref = db.collection(COL_COBRANCAS_PIX).doc();
    const prazo = vencimentoPix(new Date(agora));
    const nomeServico = texto(orc.nome_servico) || texto(orc.nome) || "serviço";
    const idContrato = texto((orc.contrato_financeiro as { id_contrato?: string } | undefined)?.id_contrato) || idOrcamento;
    tx.set(ref, {
      schema: 1,
      id_evento: idEvento,
      id_orcamento: idOrcamento,
      id_contrato: idContrato,
      id_fornecedor: texto(orc.id_fornecedor) || null,
      id_pagador: entrada.autorId,
      nome_servico: nomeServico.slice(0, 80),
      valor_centavos: valor.centavos,
      status: "CRIANDO",
      gateway: "ASAAS",
      gateway_payment_id: null,
      external_reference: referenciaExterna(idOrcamento, ref.id),
      due_date: prazo.dueDate,
      expira_em: Timestamp.fromDate(prazo.expiraEm),
      copia_cola: "",
      qr_code_base64: "",
      aplicado: false,
      criado_em: FieldValue.serverTimestamp(),
      atualizado_em: FieldValue.serverTimestamp(),
    });
    return {
      tipo: "nova" as const,
      id: ref.id,
      valorCentavos: valor.centavos,
      dueDate: prazo.dueDate,
      nomeServico,
      referencia: referenciaExterna(idOrcamento, ref.id),
    };
  });

  if (reservado.tipo === "reuso") {
    return respostaDe(reservado.id, reservado.dados, {
      reutilizada: true,
      aviso: reservado.aviso,
    });
  }

  const ref = db.collection(COL_COBRANCAS_PIX).doc(reservado.id);
  let pixId = "";
  try {
    const customerId = await asaas.garantirCliente({
      nome: quem.nome,
      email: quem.email,
      cpf: quem.cpf,
      referencia: `FESTA_ORG|${entrada.autorId}`,
    });
    const descricao = `Faça a Festa - ${reservado.nomeServico}`.replace(/[\r\n]/g, " ").slice(0, 140);
    const pix = await asaas.criarPix({
      customerId,
      valorReais: reaisDeCentavos(reservado.valorCentavos),
      dueDate: reservado.dueDate,
      descricao,
      referencia: reservado.referencia,
    });
    pixId = pix.id;
    const gravado = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const atual = snap.data() ?? {};
      if (atual.aplicado === true || atual.status === "APPROVED") return atual;
      const proximo = {
        status: "PENDING",
        gateway_payment_id: pix.id,
        gateway_status: pix.status,
        copia_cola: pix.payload,
        qr_code_base64: pix.encodedImage,
        atualizado_em: FieldValue.serverTimestamp(),
      };
      tx.update(ref, proximo);
      return {
        ...atual,
        ...proximo,
        copia_cola: pix.payload,
        qr_code_base64: pix.encodedImage,
        status: "PENDING",
      };
    });
    return respostaDe(reservado.id, gravado, { reutilizada: false, aviso: null });
  } catch (e) {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const atual = snap.data() ?? {};
      if (atual.aplicado === true || atual.status === "APPROVED" || atual.status === "PENDING") {
        return;
      }
      tx.set(ref, {
        status: "FALHA",
        ...(pixId ? { gateway_payment_id: pixId } : {}),
        atualizado_em: FieldValue.serverTimestamp(),
      }, { merge: true });
    }).catch(() => undefined);
    if (e instanceof HttpsError) throw e;
    logger.error("Falha ao criar Pix Asaas", { id: reservado.id });
    throw new HttpsError("internal", "Não foi possível gerar o Pix. Tente novamente.");
  }
}

export async function aplicarPagamentoAsaas(
  db: Firestore,
  pagamento: PagamentoAsaas,
): Promise<{ status: string; aplicado: boolean }> {
  const parsed = lerReferenciaExterna(pagamento.externalReference);
  if (!parsed) throw new HttpsError("failed-precondition", "Cobrança de outro produto.");
  const ref = db.collection(COL_COBRANCAS_PIX).doc(parsed.cobrancaId);
  const status = mapearStatusAsaas(pagamento.status);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Cobrança não encontrada.");
    const d = snap.data() ?? {};
    if (texto(d.id_orcamento) !== parsed.idOrcamento) {
      throw new HttpsError("failed-precondition", "Cobrança não corresponde ao contrato.");
    }
    if (texto(d.external_reference) !== pagamento.externalReference) {
      throw new HttpsError("failed-precondition", "Referência da cobrança não confere.");
    }
    const gatewaySalvo = texto(d.gateway_payment_id);
    if (d.aplicado === true) {
      if (status !== "APPROVED") {
        tx.update(ref, {
          status_gateway: status,
          estorno_pendente: status === "REFUNDED",
          atualizado_em: FieldValue.serverTimestamp(),
        });
      }
      return { status: texto(d.status) || "APPROVED", aplicado: true };
    }
    if (status !== "APPROVED") {
      tx.update(ref, {
        status: status === "PENDING" ? (texto(d.copia_cola) ? "PENDING" : texto(d.status) || "CRIANDO") : status,
        gateway_payment_id: gatewaySalvo || pagamento.id,
        gateway_status: pagamento.status,
        atualizado_em: FieldValue.serverTimestamp(),
      });
      return { status, aplicado: false };
    }

    const confere = cobrancaConfere({
      valorEsperadoCentavos: Number(d.valor_centavos ?? 0),
      valorPago: pagamento.value,
      referenciaEsperada: texto(d.external_reference),
      referenciaRecebida: pagamento.externalReference,
      pagamentoIdEsperado: gatewaySalvo,
      pagamentoIdRecebido: pagamento.id,
    });
    if (!confere.ok) {
      tx.update(ref, {
        status: "REJECTED",
        gateway_payment_id: gatewaySalvo || pagamento.id,
        gateway_status: pagamento.status,
        motivo_rejeicao: confere.motivo,
        atualizado_em: FieldValue.serverTimestamp(),
      });
      return { status: "REJECTED", aplicado: false };
    }

    const orcRef = db.collection("orcamento").doc(parsed.idOrcamento);
    const orcSnap = await tx.get(orcRef);
    if (!orcSnap.exists || !contratado(orcSnap.data() ?? {})) {
      throw new HttpsError("failed-precondition", "Contrato indisponível para confirmar o Pix.");
    }
    const alocSnap = await tx.get(
      db.collection(COL_ALOCACOES).where("id_orcamento", "==", parsed.idOrcamento).limit(50),
    );
    let alocado = 0;
    for (const doc of alocSnap.docs) alocado += Number(doc.data().valor_centavos ?? 0);
    const valor = Number(d.valor_centavos ?? 0);
    const restante = Math.max(0, valorContratadoDoOrcamento(orcSnap.data() ?? {}) - alocado);
    const alocar = Math.min(valor, restante);
    const recId = createHash("sha256").update(`asaas:${pagamento.id}`).digest("hex");
    const alocId = createHash("sha256").update(`asaas-aloc:${pagamento.id}`).digest("hex");
    const recRef = db.collection(COL_RECEBIMENTOS).doc(recId);
    const recExistente = await tx.get(recRef);
    if (!recExistente.exists) {
      tx.set(recRef, {
        schema: 1,
        id_recebimento: recId,
        id_evento: texto(d.id_evento),
        id_pagador: texto(d.id_pagador) || null,
        valor: dinheiro(valor),
        valor_centavos: valor,
        nivel_confirmacao: "fonte_externa",
        referencia: pagamento.id,
        origem: "asaas_pix",
        origem_legado_pago: false,
        alocado_centavos: alocar,
        chave_idempotencia: `asaas:${pagamento.id}`,
        operador_id: texto(d.id_pagador) || "asaas",
        confirmado_por: "asaas",
        criado_em: FieldValue.serverTimestamp(),
      });
    }
    if (alocar > 0) {
      const alocRef = db.collection(COL_ALOCACOES).doc(alocId);
      const alocExistente = await tx.get(alocRef);
      if (!alocExistente.exists) {
        tx.set(alocRef, {
          schema: 1,
          id_alocacao: alocId,
          id_recebimento: recId,
          id_contrato: texto(d.id_contrato) || parsed.idOrcamento,
          id_orcamento: parsed.idOrcamento,
          id_evento: texto(d.id_evento),
          id_fornecedor: texto(d.id_fornecedor) || null,
          valor: dinheiro(alocar),
          valor_centavos: alocar,
          origem: "asaas_pix",
          criterio: "pix_asaas",
          chave_idempotencia: `asaas-aloc:${pagamento.id}`,
          operador_id: texto(d.id_pagador) || "asaas",
          criado_em: FieldValue.serverTimestamp(),
        });
      }
    }
    tx.update(ref, {
      status: "APPROVED",
      aplicado: true,
      gateway_payment_id: pagamento.id,
      gateway_status: pagamento.status,
      recebimento_id: recId,
      alocado_centavos: alocar,
      aprovado_em: FieldValue.serverTimestamp(),
      atualizado_em: FieldValue.serverTimestamp(),
    });
    tx.set(db.collection(COL_AUDITORIA).doc(), {
      schema: 1,
      acao: "confirmar_pix_asaas",
      autor_id: texto(d.id_pagador) || "asaas",
      id_cobranca: parsed.cobrancaId,
      id_orcamento: parsed.idOrcamento,
      valor_centavos: valor,
      alocado_centavos: alocar,
      gateway_payment_id: pagamento.id,
      criado_em: FieldValue.serverTimestamp(),
    });
    return { status: "APPROVED", aplicado: true };
  });
}

export async function consultarCobrancaPixServico(
  db: Firestore,
  cobrancaId: string,
  asaas: ClienteAsaas,
): Promise<RespostaCobrancaPix> {
  const id = idSeguro(cobrancaId, "Cobrança");
  const ref = db.collection(COL_COBRANCAS_PIX).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Cobrança não encontrada.");
  const d = snap.data() ?? {};
  const gatewayId = texto(d.gateway_payment_id);
  if (!gatewayId || d.aplicado === true || d.status === "FALHA") {
    return respostaDe(id, d, { reutilizada: false, aviso: null });
  }
  const pagamento = await asaas.consultarPagamento(gatewayId);
  await aplicarPagamentoAsaas(db, pagamento);
  const atualizado = await ref.get();
  return respostaDe(id, atualizado.data() ?? d, { reutilizada: false, aviso: null });
}

export async function dadosDaCobranca(
  db: Firestore,
  cobrancaId: string,
): Promise<{ idEvento: string; idOrcamento: string; idPagador: string }> {
  const id = idSeguro(cobrancaId, "Cobrança");
  const snap = await db.collection(COL_COBRANCAS_PIX).doc(id).get();
  if (!snap.exists) throw new HttpsError("not-found", "Cobrança não encontrada.");
  const d = snap.data() ?? {};
  return {
    idEvento: texto(d.id_evento),
    idOrcamento: texto(d.id_orcamento),
    idPagador: texto(d.id_pagador),
  };
}
