import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroEvento } from "../../services/financeiro/autorizacaoFinanceiro";
import {
  cancelarContrato,
  registrarOuAtualizarContrato,
} from "../../services/financeiro/contratoFinanceiroService";
import { registrarLiquidacao } from "../../services/financeiro/liquidacaoFinanceiroService";

const REGION = "southamerica-east1";

export const registrarContratoFinanceiro = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      idOrcamento,
    });

    const resultado = await registrarOuAtualizarContrato(admin.firestore(), {
      idEvento,
      idOrcamento,
      valorCentavos: asInt(data.valorCentavos ?? data.valor_centavos),
      valorReais: asNum(data.valorReais ?? data.valor_reais),
      idNecessidade: texto(data.idNecessidade ?? data.id_necessidade) || undefined,
      autorId: perfil.uid,
      motivo: texto(data.motivo) || undefined,
    });

    return {
      ok: true,
      idContrato: resultado.idContrato,
      valorCentavos: resultado.valor.centavos,
    };
  },
);

export const cancelarContratoFinanceiro = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    const motivo = texto(data.motivo);
    if (!motivo) {
      throw new HttpsError("invalid-argument", "Informe o motivo do cancelamento.");
    }
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      idOrcamento,
    });

    const resultado = await cancelarContrato(admin.firestore(), {
      idEvento,
      idOrcamento,
      autorId: perfil.uid,
      motivo,
      retencaoCentavos: asInt(data.retencaoCentavos ?? data.retencao_centavos) ?? 0,
      reembolsoCentavos:
        asInt(data.reembolsoCentavos ?? data.reembolso_centavos) ?? 0,
    });

    return {
      ok: true,
      saldoExplicadoCentavos: resultado.saldoExplicadoCentavos,
    };
  },
);

export const registrarLiquidacaoFinanceira = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      idOrcamento,
    });

    const resultado = await registrarLiquidacao(admin.firestore(), {
      idEvento,
      idOrcamento,
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
      autorId: perfil.uid,
      tipo: texto(data.tipo) || "pagamento",
      valorCentavos: asInt(data.valorCentavos ?? data.valor_centavos),
      valorReais: asNum(data.valorReais ?? data.valor_reais),
      idObrigacao: texto(data.idObrigacao ?? data.id_obrigacao) || undefined,
      motivo: texto(data.motivo) || undefined,
      confirmacao: texto(data.confirmacao) || undefined,
    });

    return {
      ok: true,
      idLiquidacao: resultado.idLiquidacao,
      idempotente: resultado.idempotente,
      pagoLiquidoCentavos: resultado.pagoLiquido.centavos,
      saldoDevidoCentavos: resultado.saldoDevidoCentavos,
    };
  },
);

function texto(value: unknown): string {
  return String(value ?? "").trim();
}

function asNum(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim()) {
    const n = Number(value.replace(",", "."));
    return Number.isFinite(n) ? n : undefined;
  }
  return undefined;
}

function asInt(value: unknown): number | undefined {
  const n = asNum(value);
  if (n === undefined) return undefined;
  if (!Number.isInteger(n)) {
    throw new HttpsError(
      "invalid-argument",
      "Valores em centavos devem ser inteiros.",
    );
  }
  return n;
}
