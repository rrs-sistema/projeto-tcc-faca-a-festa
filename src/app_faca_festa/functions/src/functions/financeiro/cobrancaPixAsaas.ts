import { timingSafeEqual } from "crypto";
import { logger } from "firebase-functions";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret, defineString } from "firebase-functions/params";
import { onCall } from "../../shared/callableComMfa";
import { HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroEvento } from "../../services/financeiro/autorizacaoFinanceiro";
import { criarClienteHttpAsaas } from "../../services/financeiro/asaasHttp";
import {
  lerReferenciaExterna,
  referenciaDesteProduto,
} from "../../services/financeiro/asaasPixRegras";
import {
  COL_COBRANCAS_PIX,
  aplicarPagamentoAsaas,
  consultarCobrancaPixServico,
  criarCobrancaPixServico,
  dadosDaCobranca,
} from "../../services/financeiro/cobrancaPixAsaasService";

const REGION = "southamerica-east1";
const ASAAS_API_KEY = defineSecret("ASAAS_API_KEY");
const ASAAS_WEBHOOK_TOKEN = defineSecret("ASAAS_WEBHOOK_TOKEN");
const ASAAS_AMBIENTE = defineString("ASAAS_AMBIENTE", { default: "sandbox" });

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function clienteAsaas() {
  const apiKey = texto(ASAAS_API_KEY.value());
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "Pagamento Pix ainda não está disponível. A plataforma precisa configurar a conta Asaas.",
    );
  }
  return criarClienteHttpAsaas({
    apiKey,
    ambiente: ASAAS_AMBIENTE.value() || "sandbox",
  });
}

function tokenConfere(recebido: string, esperado: string): boolean {
  const a = Buffer.from(recebido);
  const b = Buffer.from(esperado);
  if (a.length === 0 || a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

export const criarCobrancaPixServicoFn = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    cors: true,
    secrets: [ASAAS_API_KEY, ASAAS_WEBHOOK_TOKEN],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      idOrcamento,
      permitirAdminEvento: false,
    });
    const bruto = data.valorCentavos ?? data.valor_centavos;
    const valorCentavos = bruto == null || bruto === ""
      ? null
      : typeof bruto === "number" && Number.isInteger(bruto)
        ? bruto
        : NaN;
    if (valorCentavos !== null && !Number.isInteger(valorCentavos)) {
      throw new HttpsError("invalid-argument", "Informe o valor do Pix em centavos.");
    }
    const token = request.auth?.token as { email?: unknown; name?: unknown } | undefined;
    return criarCobrancaPixServico(admin.firestore(), {
      idEvento,
      idOrcamento,
      valorCentavos,
      cpfInformado: texto(data.cpf) || null,
      autorId: perfil.uid,
      emailAuth: texto(token?.email) || null,
      nomeAuth: texto(token?.name) || null,
    }, clienteAsaas());
  },
);

export const consultarCobrancaPixServicoFn = onCall(
  {
    region: REGION,
    timeoutSeconds: 60,
    cors: true,
    secrets: [ASAAS_API_KEY, ASAAS_WEBHOOK_TOKEN],
  },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const id = texto(data.cobrancaId ?? data.id);
    const previa = await dadosDaCobranca(admin.firestore(), id);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, previa.idEvento, {
      idOrcamento: previa.idOrcamento,
      permitirAdminEvento: false,
    });
    return consultarCobrancaPixServico(admin.firestore(), id, clienteAsaas());
  },
);

/**
 * Webhook Asaas. Header `asaas-access-token` com o secret ASAAS_WEBHOOK_TOKEN.
 * Eventos: PAYMENT_CONFIRMED e PAYMENT_RECEIVED.
 * Referências `FESTA|...` isolam estas cobranças de outros produtos na mesma conta.
 */
export const asaasWebhookFacaFesta = onRequest(
  {
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
    invoker: "public",
    secrets: [ASAAS_API_KEY, ASAAS_WEBHOOK_TOKEN],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }
    const esperado = texto(ASAAS_WEBHOOK_TOKEN.value());
    const apiKey = texto(ASAAS_API_KEY.value());
    if (!esperado || !apiKey) {
      res.status(503).send("asaas_not_configured");
      return;
    }
    const recebido = texto(req.header("asaas-access-token"));
    if (!tokenConfere(recebido, esperado)) {
      res.status(401).send("invalid_token");
      return;
    }

    const body = (req.body ?? {}) as Record<string, unknown>;
    const payment = (body.payment && typeof body.payment === "object")
      ? body.payment as Record<string, unknown>
      : body;
    const referenciaInicial = texto(payment.externalReference ?? payment.external_reference);
    if (!referenciaDesteProduto(referenciaInicial)) {
      res.status(200).send("ignored");
      return;
    }
    const parsed = lerReferenciaExterna(referenciaInicial);
    const paymentId = texto(payment.id);
    if (!parsed || !paymentId) {
      res.status(200).send("ignored_without_payment");
      return;
    }

    const existe = await admin.firestore().collection(COL_COBRANCAS_PIX).doc(parsed.cobrancaId).get();
    if (!existe.exists) {
      res.status(200).send("ignored_unknown");
      return;
    }

    try {
      const fresco = await criarClienteHttpAsaas({
        apiKey,
        ambiente: ASAAS_AMBIENTE.value() || "sandbox",
      }).consultarPagamento(paymentId);
      const referenciaFresca = lerReferenciaExterna(fresco.externalReference);
      if (!referenciaFresca || referenciaFresca.cobrancaId !== parsed.cobrancaId) {
        res.status(500).send("reference_mismatch");
        return;
      }
      await aplicarPagamentoAsaas(admin.firestore(), fresco);
      res.status(200).send("ok");
    } catch (e) {
      logger.error("Falha ao confirmar Pix Asaas", {
        cobrancaId: parsed.cobrancaId,
        code: e instanceof HttpsError ? e.code : "unknown",
      });
      res.status(500).send("processing_error");
    }
  },
);
