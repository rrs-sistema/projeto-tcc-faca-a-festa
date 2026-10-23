import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroEvento } from "../../services/financeiro/autorizacaoFinanceiro";
import { calcularPrevisaoGerente } from "../../services/financeiro/previsaoGerenteService";

const REGION = "southamerica-east1";

/**
 * Consulta autorização + previsão do gerente para um evento.
 * Não reescreve fatos realizados; só calcula visão.
 */
export const consultarPrevisaoFinanceiraGerente = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = String(data.idEvento ?? data.id_evento ?? "").trim();
    if (!idEvento) {
      throw new HttpsError("invalid-argument", "Informe o evento.");
    }

    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      permitirAdminEvento: false,
    });

    const db = admin.firestore();
    const eventoSnap = await db.collection("evento").doc(idEvento).get();
    const evento = eventoSnap.data() ?? {};
    const limite =
      typeof evento.custo_estimado === "number" ? evento.custo_estimado : null;
    const reserva =
      typeof evento.reserva_contingencia === "number"
        ? evento.reserva_contingencia
        : typeof evento.reserva_contingencia_centavos === "number"
          ? evento.reserva_contingencia_centavos / 100
          : 0;

    const orcs = await db
      .collection("orcamento")
      .where("id_evento", "==", idEvento)
      .get();

    const compromissos: Record<string, unknown>[] = [];
    for (const doc of orcs.docs) {
      const d = doc.data();
      const gastos = await doc.ref.collection("orcamento_gasto").get();
      let pago = 0;
      let despesas = 0;
      for (const g of gastos.docs) {
        const gd = g.data();
        pago += numero(gd.pago);
        despesas += numero(gd.custo);
      }
      const status = String(d.status ?? "").toLowerCase();
      const contratado =
        d.orcamento_fechado === true ||
        status === "fechado" ||
        status === "contratado";
      const cancelado =
        status === "cancelado" || status === "cancelada" || d.ativo === false;
      compromissos.push({
        id: doc.id,
        id_necessidade: d.id_necessidade ?? d.id_cotacao ?? doc.id,
        estimado: numero(d.custo_estimado),
        cotado: status === "em_negociacao" ? numero(d.custo_estimado) : 0,
        contratado: contratado && !cancelado,
        valor_contratado: contratado
          ? numero(d.valor_contratado ?? d.custo_estimado)
          : 0,
        pago,
        despesas,
        cancelado,
        financeiro_valido: true,
        saldo_devido: contratado
          ? numero(d.valor_contratado ?? d.custo_estimado) - pago
          : 0,
      });
    }

    const necessidadesRaw = Array.isArray(data.necessidades)
      ? (data.necessidades as Record<string, unknown>[])
      : [];
    const necessidades = necessidadesRaw.map((n) => ({
      id: String(n.id ?? ""),
      descricao: String(n.descricao ?? n.id ?? "Necessidade"),
      quantidade_necessaria:
        typeof n.quantidade_necessaria === "number"
          ? n.quantidade_necessaria
          : typeof n.quantidadeNecessaria === "number"
            ? n.quantidadeNecessaria
            : undefined,
      quantidade_contratada:
        typeof n.quantidade_contratada === "number"
          ? n.quantidade_contratada
          : typeof n.quantidadeContratada === "number"
            ? n.quantidadeContratada
            : 0,
      preco_unitario:
        typeof n.preco_unitario === "number"
          ? n.preco_unitario
          : typeof n.precoUnitario === "number"
            ? n.precoUnitario
            : null,
      custo_estimado_total:
        typeof n.custo_estimado_total === "number"
          ? n.custo_estimado_total
          : typeof n.custoEstimadoTotal === "number"
            ? n.custoEstimadoTotal
            : null,
      coberta_por_buffet: n.coberta_por_buffet === true || n.cobertaPorBuffet === true,
      eliminada: n.eliminada === true,
    }));

    const previsao = calcularPrevisaoGerente({
      limite,
      reserva,
      compromissos,
      necessidades,
    });

    return {
      ok: true,
      idEvento,
      nomeEvento: String(evento.nome ?? evento.nome_evento ?? ""),
      ...previsao,
    };
  },
);

function numero(v: unknown): number {
  return typeof v === "number" && Number.isFinite(v) && v >= 0 ? v : 0;
}
