import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroEvento } from "../../services/financeiro/autorizacaoFinanceiro";
import { precoPorMargemSobreVenda } from "../../services/financeiro/precificacaoFornecedorService";
import {
  simularOrcamento,
  tetoCompartilhadoParaFornecedor,
} from "../../services/financeiro/simulacaoOrcamentoService";

const REGION = "southamerica-east1";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

/**
 * Simulação determinística do orçamento do evento.
 * NÃO grava contrato, compra, reserva, pagamento ou comissão.
 * IA/cliente apenas consome o resultado explicável.
 */
export const simularOrcamentoEvento = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento);

    const limite =
      typeof data.limiteCentavos === "number"
        ? data.limiteCentavos
        : typeof data.limite_centavos === "number"
          ? data.limite_centavos
          : typeof data.limite === "number"
            ? Math.round(data.limite * 100)
            : null;
    if (limite == null || !Number.isInteger(limite) || limite < 0) {
      throw new HttpsError("invalid-argument", "Informe o limite confirmado.");
    }

    const compromissos = Array.isArray(data.compromissos)
      ? (data.compromissos as Record<string, unknown>[])
      : [];
    const necessidades = Array.isArray(data.necessidades)
      ? (data.necessidades as Array<{
          id: string;
          descricao: string;
          eliminada?: boolean;
          cobertaPorBuffet?: boolean;
        }>)
      : [];
    const alternativasPorNecessidade =
      data.alternativasPorNecessidade &&
      typeof data.alternativasPorNecessidade === "object"
        ? (data.alternativasPorNecessidade as Record<
            string,
            Array<{
              id: string;
              idNecessidade: string;
              rotulo: string;
              precoCentavos: number;
              vigente?: boolean;
              compativelCatalogo?: boolean;
              historicoValido?: boolean;
            }>
          >)
        : {};

    const resultado = simularOrcamento({
      limiteCentavos: limite,
      compromissos,
      necessidades,
      alternativasPorNecessidade,
      despesasCentavos:
        typeof data.despesasCentavos === "number" ? data.despesasCentavos : 0,
      reservaCentavos:
        typeof data.reservaCentavos === "number" ? data.reservaCentavos : 0,
    });

    return {
      ok: true,
      ...resultado,
      // Garantia explícita de não efeito colateral.
      efeitos: {
        contrato: false,
        compra: false,
        reserva: false,
        pagamento: false,
        comissao: false,
      },
      origem: "simularOrcamentoEvento",
    };
  },
);

/** Precificação privada do fornecedor (próprios custos). */
export const calcularPrecoFornecedor = onCall(
  { region: REGION, timeoutSeconds: 30, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    if (perfil.tipo !== "F" && perfil.tipo !== "A") {
      throw new HttpsError("permission-denied", "Sem permissão de precificação.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    const custos = Number(data.custosCentavos ?? data.custos_centavos);
    const margem = Number(data.margemSobreVenda ?? data.margem_sobre_venda);
    const taxas = Number(data.taxasSobreVenda ?? data.taxas_sobre_venda ?? 0);
    if (!Number.isInteger(custos)) {
      throw new HttpsError("invalid-argument", "Informe custos em centavos.");
    }
    try {
      const r = precoPorMargemSobreVenda(custos, margem, taxas);
      return { ok: true, ...r, alteraFinanceiro: false };
    } catch (e) {
      const err = e as { code?: string; message?: string };
      if (err.code === "failed-precondition") {
        throw new HttpsError("failed-precondition", err.message || "Denominador inválido.");
      }
      throw new HttpsError("invalid-argument", err.message || "Precificação inválida.");
    }
  },
);

/** Teto do serviço compartilhado — sem limite global do cliente. */
export const consultarTetoCotacaoFornecedor = onCall(
  { region: REGION, timeoutSeconds: 30, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor) || perfil.uid;
    if (perfil.uid !== idFornecedor && perfil.tipo !== "A") {
      throw new HttpsError(
        "permission-denied",
        "Fornecedor não autorizado não acessa teto/limite.",
      );
    }
    try {
      const teto = tetoCompartilhadoParaFornecedor({
        idFornecedor,
        idNecessidade: texto(data.idNecessidade ?? data.id_necessidade),
        tetoCentavos:
          typeof data.tetoCentavos === "number"
            ? data.tetoCentavos
            : typeof data.teto_centavos === "number"
              ? data.teto_centavos
              : null,
        compartilhadoExplicitamente: data.compartilhadoExplicitamente === true,
        solicitanteUid: perfil.uid,
        idFornecedorSolicitante: idFornecedor,
      });
      if (!teto) {
        return {
          ok: true,
          teto: null,
          mensagem:
            "Teto não compartilhado explicitamente — limite global do cliente não é exposto.",
        };
      }
      return { ok: true, teto, limiteGlobalClienteExposto: false };
    } catch (e) {
      const err = e as { code?: string; message?: string };
      if (err.code === "permission-denied") {
        throw new HttpsError("permission-denied", err.message || "Negado.");
      }
      throw new HttpsError("invalid-argument", err.message || "Falha no teto.");
    }
  },
);
