import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { randomUUID } from "crypto";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroFornecedor } from "../../services/financeiro/autorizacaoFornecedorFinanceiro";
import { dinheiro, reaisParaCentavosArredondado } from "../../services/financeiro/dinheiro";
import { calcularResumoFornecedor } from "../../services/financeiro/resumoFornecedorService";

const REGION = "southamerica-east1";

export const registrarCustoInternoFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idEvento = texto(data.idEvento ?? data.id_evento);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe o evento.");
    }

    const tipo = texto(data.tipo) || "outro";
    const origem = texto(data.origem) || "manual";
    const centavos = resolverCentavos(data);
    const chave = texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();
    const ref = admin
      .firestore()
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("custos_internos")
      .doc(chave);

    const existente = await ref.get();
    if (existente.exists) {
      return { ok: true, idCusto: ref.id, idempotente: true };
    }

    const desembolso =
      origem === "estoque_consumo"
        ? 0
        : resolverCentavosOpcional(data.desembolsoCentavos ?? data.desembolso_centavos) ??
          (origem === "desembolso" ? centavos : 0);
    const restante =
      resolverCentavosOpcional(
        data.previstoRestanteCentavos ?? data.previsto_restante_centavos,
      ) ?? 0;

    await ref.set({
      schema: 1,
      id_custo: ref.id,
      id_fornecedor: idFornecedor,
      id_evento: idEvento,
      id_servico: texto(data.idServico ?? data.id_servico) || null,
      categoria: texto(data.categoria) || null,
      tipo,
      valor_incorrido: dinheiro(centavos),
      valor_obrigacao: dinheiro(
        resolverCentavosOpcional(data.obrigacaoCentavos ?? data.obrigacao_centavos) ?? 0,
      ),
      valor_desembolso: dinheiro(desembolso),
      previsto_restante: dinheiro(restante),
      origem,
      reutilizavel: data.reutilizavel === true,
      referencia_comprovante:
        texto(data.referenciaComprovante ?? data.referencia_comprovante) || null,
      descricao: texto(data.descricao) || null,
      autor_id: perfil.uid,
      perspectiva: "fornecedor_privado",
      chave_idempotencia: chave,
      criado_em: FieldValue.serverTimestamp(),
    });

    return { ok: true, idCusto: ref.id, idempotente: false };
  },
);

export const registrarRecebimentoFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idEvento = texto(data.idEvento ?? data.id_evento);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe o evento.");
    }

    const tipo = texto(data.tipo) || "recebimento";
    // Pagamento declarado pelo cliente NÃO vira recebimento automático aqui.
    if (data.copiarPagamentoCliente === true || data.copiar_pagamento_cliente === true) {
      throw new HttpsError(
        "failed-precondition",
        "Recebimento do fornecedor exige confirmação própria; não copie o pagamento do cliente.",
      );
    }

    const centavos = resolverCentavos(data);
    const chave =
      texto(data.chaveIdempotencia ?? data.chave_idempotencia) || randomUUID();
    const ref = admin
      .firestore()
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("contas_receber")
      .doc(chave);

    const existente = await ref.get();
    if (existente.exists) {
      return { ok: true, idRecebimento: ref.id, idempotente: true };
    }

    const adiantamento = tipo === "adiantamento";
    const execucao = data.execucaoConfirmada === true || data.execucao_confirmada === true;

    await ref.set({
      schema: 1,
      id_recebimento: ref.id,
      id_fornecedor: idFornecedor,
      id_evento: idEvento,
      id_orcamento: texto(data.idOrcamento ?? data.id_orcamento) || null,
      valor: dinheiro(centavos),
      tipo,
      adiantamento,
      // Adiantamento afeta caixa; receita realizada só com execução/entrega.
      receita_realizada: execucao && !adiantamento,
      execucao_confirmada: execucao,
      confirmacao: "declarada_manual",
      perspectiva: "fornecedor_recebedor",
      autor_id: perfil.uid,
      motivo: texto(data.motivo) || null,
      chave_idempotencia: chave,
      criado_em: FieldValue.serverTimestamp(),
    });

    // Espelho de caixa (entrada).
    await admin
      .firestore()
      .collection("fornecedor")
      .doc(idFornecedor)
      .collection("movimentos_caixa")
      .doc(chave)
      .set({
        schema: 1,
        id_movimento: chave,
        id_fornecedor: idFornecedor,
        id_evento: idEvento,
        valor: dinheiro(centavos),
        entrada: true,
        origem: tipo,
        chave_idempotencia: chave,
        criado_em: FieldValue.serverTimestamp(),
      });

    return { ok: true, idRecebimento: ref.id, idempotente: false };
  },
);

export const consultarResumoFinanceiroFornecedor = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    const idEvento = texto(data.idEvento ?? data.id_evento) || null;
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );

    const db = admin.firestore();
    const base = db.collection("fornecedor").doc(idFornecedor);

    // Vendas a partir de orçamentos do fornecedor (valor contratado — não margem).
    let orcQuery = db
      .collection("orcamento")
      .where("id_fornecedor", "==", idFornecedor);
    if (idEvento) {
      orcQuery = orcQuery.where("id_evento", "==", idEvento);
    }
    // Paralelo: cold start + 3 reads sequenciais era o principal atraso.
    const [orcs, recebimentos, custosSnap] = await Promise.all([
      orcQuery.get(),
      base.collection("contas_receber").get(),
      base.collection("custos_internos").get(),
    ]);

    const recebidoPorEvento = new Map<string, number>();
    const adiantamentoPorEvento = new Map<string, number>();
    const receitaPorEvento = new Map<string, number>();
    for (const doc of recebimentos.docs) {
      const d = doc.data();
      const ev = String(d.id_evento ?? "");
      if (idEvento && ev !== idEvento) continue;
      const centavos = Number(d.valor?.centavos ?? 0);
      const reais = centavos / 100;
      recebidoPorEvento.set(ev, (recebidoPorEvento.get(ev) ?? 0) + reais);
      if (d.adiantamento === true) {
        adiantamentoPorEvento.set(
          ev,
          (adiantamentoPorEvento.get(ev) ?? 0) + reais,
        );
      }
      if (d.receita_realizada === true || d.execucao_confirmada === true) {
        receitaPorEvento.set(ev, (receitaPorEvento.get(ev) ?? 0) + reais);
      }
    }

    const vendas = orcs.docs.map((doc) => {
      const d = doc.data();
      const ev = String(d.id_evento ?? "");
      const status = String(d.status ?? "").toLowerCase();
      const contratado =
        d.orcamento_fechado === true ||
        status === "fechado" ||
        status === "contratado";
      const valor = contratado
        ? Number(d.valor_contratado ?? d.custo_estimado ?? 0)
        : 0;
      const nome =
        String(
          d.nome_servico ??
            d.categoria_nome ??
            d.titulo ??
            d.descricao ??
            "",
        ).trim() || "Serviço contratado";
      return {
        id: doc.id,
        id_evento: ev,
        nome_servico: nome,
        status,
        valor_contratado: valor,
        recebido_confirmado: recebidoPorEvento.get(ev) ?? 0,
        adiantamento_caixa: adiantamentoPorEvento.get(ev) ?? 0,
        receita_realizada: receitaPorEvento.get(ev) ?? 0,
        execucao_confirmada: (receitaPorEvento.get(ev) ?? 0) > 0,
      };
    });

    // Evita somar o mesmo recebimento em cada orçamento do evento: normaliza por evento.
    const vendasPorEvento = new Map<string, (typeof vendas)[0]>();
    for (const v of vendas) {
      const atual = vendasPorEvento.get(v.id_evento);
      if (!atual) {
        vendasPorEvento.set(v.id_evento, { ...v });
      } else {
        atual.valor_contratado += v.valor_contratado;
      }
    }

    const custos = custosSnap.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        id_evento: String(d.id_evento ?? ""),
        incorrido: Number(d.valor_incorrido?.centavos ?? 0) / 100,
        restante_previsto: Number(d.previsto_restante?.centavos ?? 0) / 100,
        desembolso_caixa: Number(d.valor_desembolso?.centavos ?? 0) / 100,
        origem: String(d.origem ?? "manual"),
        direto: d.direto !== false,
      };
    });

    const resumo = calcularResumoFornecedor({
      vendas: [...vendasPorEvento.values()],
      custos,
      idEvento,
      saldoInicial:
        typeof data.saldoInicial === "number" ? data.saldoInicial : null,
      comissao: typeof data.comissao === "number" ? data.comissao : null,
      taxas: typeof data.taxas === "number" ? data.taxas : null,
      tributos: typeof data.tributos === "number" ? data.tributos : null,
    });

    // Lista por contrato (UI do fornecedor) — só fechados com valor.
    const contratos = vendas
      .filter((v) => v.valor_contratado > 0)
      .map((v) => {
        const recebidoEv = v.recebido_confirmado;
        const saldo = Math.max(0, v.valor_contratado - recebidoEv);
        let situacao = "aguardando_repasse";
        if (saldo <= 0.009) situacao = "recebido";
        else if (recebidoEv > 0) situacao = "parcial";
        return {
          id: v.id,
          idEvento: v.id_evento,
          nomeServico: v.nome_servico,
          valorContratado: v.valor_contratado,
          recebido: recebidoEv,
          aReceber: saldo,
          situacao,
        };
      });

    return {
      ok: true,
      idFornecedor,
      idEvento,
      ...resumo,
      contratos,
    };
  },
);

function texto(v: unknown): string {
  return String(v ?? "").trim();
}

function resolverCentavos(data: Record<string, unknown>): number {
  if (typeof data.valorCentavos === "number" || typeof data.valor_centavos === "number") {
    const c = Number(data.valorCentavos ?? data.valor_centavos);
    return dinheiro(c).centavos;
  }
  if (typeof data.valorReais === "number" || typeof data.valor_reais === "number") {
    return reaisParaCentavosArredondado(Number(data.valorReais ?? data.valor_reais));
  }
  throw new HttpsError("invalid-argument", "Informe o valor.");
}

function resolverCentavosOpcional(v: unknown): number | undefined {
  if (typeof v !== "number" || !Number.isFinite(v)) return undefined;
  if (!Number.isInteger(v)) {
    throw new HttpsError("invalid-argument", "Centavos devem ser inteiros.");
  }
  return dinheiro(v).centavos;
}
