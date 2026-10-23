import {
  DocumentReference,
  FieldValue,
  Firestore,
  QuerySnapshot,
  Transaction,
} from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import {
  dinheiro,
  deMapa,
  Dinheiro,
  reaisParaCentavosArredondado,
} from "./dinheiro";

export type EntradaLiquidacao = {
  idEvento: string;
  idOrcamento: string;
  chaveIdempotencia: string;
  autorId: string;
  tipo?: string;
  valorCentavos?: number;
  valorReais?: number;
  idObrigacao?: string;
  motivo?: string;
  confirmacao?: string;
};

export type ResultadoLiquidacao = {
  idLiquidacao: string;
  idempotente: boolean;
  pagoLiquido: Dinheiro;
  saldoDevidoCentavos: number;
};

const TIPOS_EXCEDEM = new Set(["credito", "adiantamento"]);

export async function registrarLiquidacao(
  db: Firestore,
  entrada: EntradaLiquidacao,
): Promise<ResultadoLiquidacao> {
  const chave = String(entrada.chaveIdempotencia ?? "").trim();
  if (!chave || chave.length > 128) {
    throw new HttpsError(
      "invalid-argument",
      "Informe uma chave de idempotência válida.",
    );
  }

  const tipo = normalizarTipo(entrada.tipo);
  const centavos = resolverCentavos(entrada);
  const orcRef = db.collection("orcamento").doc(entrada.idOrcamento);
  const idemRef = orcRef.collection("liquidacoes_idempotencia").doc(chave);
  const liqRef = orcRef.collection("liquidacoes").doc();
  const obrId = entrada.idObrigacao ?? "parcela-1";
  const obrRef = orcRef.collection("obrigacoes").doc(obrId);
  const gastosQuery = orcRef.collection("orcamento_gasto").limit(1);

  return db.runTransaction(async (tx) => {
    // Todas as leituras antes de qualquer escrita.
    const [idemSnap, orcSnap, obrSnap, gastosSnap] = await Promise.all([
      tx.get(idemRef),
      tx.get(orcRef),
      tx.get(obrRef),
      tx.get(gastosQuery),
    ]);

    if (idemSnap.exists) {
      const existente = idemSnap.data() ?? {};
      return {
        idLiquidacao: String(existente.id_liquidacao ?? ""),
        idempotente: true,
        pagoLiquido: deMapa(existente.pago_liquido) ?? dinheiro(0),
        saldoDevidoCentavos: Number(existente.saldo_devido_centavos ?? 0),
      };
    }

    if (!orcSnap.exists) {
      throw new HttpsError("not-found", "Orçamento não encontrado.");
    }
    const orc = orcSnap.data() ?? {};
    if (String(orc.id_evento ?? "") !== entrada.idEvento) {
      throw new HttpsError("failed-precondition", "Orçamento de outro evento.");
    }

    const contrato = (orc.contrato_financeiro as Record<string, unknown>) ?? {};
    const valorContrato =
      deMapa(contrato.valor)?.centavos ??
      (typeof orc.valor_contratado_centavos === "number"
        ? orc.valor_contratado_centavos
        : Math.round(
            Number(orc.valor_contratado ?? orc.custo_estimado ?? 0) * 100,
          ));

    const criarObrigacao = !obrSnap.exists;
    const obr = obrSnap.data() ?? {};
    const valorObr = criarObrigacao
      ? Math.max(0, valorContrato)
      : deMapa(obr.valor)?.centavos ?? valorContrato;
    const pagoAtual = criarObrigacao
      ? 0
      : deMapa(obr.pago_liquido)?.centavos ?? 0;
    const efeito = efeitoPago(tipo, centavos);
    const pagoNovo = pagoAtual + efeito;
    const saldoApos = valorObr - pagoNovo;

    if (efeito > 0 && saldoApos < 0 && !TIPOS_EXCEDEM.has(tipo)) {
      throw new HttpsError(
        "failed-precondition",
        "Pagamento excede o saldo. Use crédito/adiantamento explícito ou reduza o valor.",
      );
    }

    const retencao = deMapa(contrato.retencao)?.centavos ?? 0;
    const reembolso = deMapa(contrato.reembolso)?.centavos ?? 0;
    const saldoDevido = valorContrato - pagoNovo - reembolso + retencao;
    const pagoPersistido = Math.max(0, pagoNovo);

    const registro = {
      schema: 1,
      id_liquidacao: liqRef.id,
      id_orcamento: entrada.idOrcamento,
      id_evento: entrada.idEvento,
      id_obrigacao: obrId,
      id_contrato: entrada.idOrcamento,
      valor: dinheiro(centavos),
      tipo,
      chave_idempotencia: chave,
      perspectiva: "evento_pagador",
      confirmacao:
        entrada.confirmacao === "confirmacao_externa"
          ? "confirmacao_externa"
          : "declarada_manual",
      autor_id: entrada.autorId,
      motivo: entrada.motivo ?? null,
      origem: "comando_liquidacao",
      criado_em: FieldValue.serverTimestamp(),
    };

    tx.set(liqRef, registro);
    tx.set(idemRef, {
      id_liquidacao: liqRef.id,
      chave_idempotencia: chave,
      pago_liquido: dinheiro(pagoPersistido),
      saldo_devido_centavos: saldoDevido,
      criado_em: FieldValue.serverTimestamp(),
    });

    const estado =
      pagoPersistido <= 0
        ? "aberta"
        : pagoPersistido >= valorObr
          ? "quitada"
          : "parcial";

    if (criarObrigacao) {
      tx.set(obrRef, {
        schema: 1,
        id_obrigacao: obrId,
        id_contrato: entrada.idOrcamento,
        id_orcamento: entrada.idOrcamento,
        id_evento: entrada.idEvento,
        valor: dinheiro(valorObr),
        pago_liquido: dinheiro(pagoPersistido),
        estado_liquidacao: estado,
        numero_parcela: 1,
        origem: "liquidacao_auto",
      });
    } else {
      tx.update(obrRef, {
        pago_liquido: dinheiro(pagoPersistido),
        estado_liquidacao: estado,
        atualizado_em: FieldValue.serverTimestamp(),
      });
    }

    espelharGastoLegado(
      tx,
      orcRef,
      gastosSnap,
      valorObr,
      pagoPersistido,
    );

    return {
      idLiquidacao: liqRef.id,
      idempotente: false,
      pagoLiquido: dinheiro(pagoPersistido),
      saldoDevidoCentavos: saldoDevido,
    };
  });
}

function espelharGastoLegado(
  tx: Transaction,
  orcRef: DocumentReference,
  gastosSnap: QuerySnapshot,
  custoCentavos: number,
  pagoCentavos: number,
): void {
  const custo = custoCentavos / 100;
  const pago = pagoCentavos / 100;
  if (gastosSnap.empty) {
    const gastoRef = orcRef.collection("orcamento_gasto").doc();
    tx.set(gastoRef, {
      id_gasto: gastoRef.id,
      id_orcamento: orcRef.id,
      nome: "Obrigação contratual",
      custo,
      pago,
      data_cadastro: FieldValue.serverTimestamp(),
      origem: "espelho_liquidacao",
    });
    return;
  }
  tx.update(gastosSnap.docs[0].ref, {
    pago,
    pagamento_atualizado_em: FieldValue.serverTimestamp(),
  });
}

function efeitoPago(tipo: string, centavos: number): number {
  if (tipo === "reembolso" || tipo === "estorno") return -centavos;
  if (tipo === "retencao") return 0;
  return centavos;
}

function normalizarTipo(tipo: unknown): string {
  const t = String(tipo ?? "pagamento").trim().toLowerCase();
  const ok = [
    "pagamento",
    "reembolso",
    "estorno",
    "credito",
    "adiantamento",
    "retencao",
  ];
  if (!ok.includes(t)) {
    throw new HttpsError("invalid-argument", "Tipo de liquidação inválido.");
  }
  return t;
}

function resolverCentavos(entrada: EntradaLiquidacao): number {
  if (typeof entrada.valorCentavos === "number") {
    return dinheiro(entrada.valorCentavos).centavos;
  }
  if (typeof entrada.valorReais === "number") {
    return reaisParaCentavosArredondado(entrada.valorReais);
  }
  throw new HttpsError("invalid-argument", "Informe o valor da liquidação.");
}
