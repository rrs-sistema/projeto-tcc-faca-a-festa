import { logger } from "firebase-functions";
import { HttpsError } from "firebase-functions/v2/https";

export type PagamentoAsaas = {
  id: string;
  status: string;
  value: number;
  externalReference: string;
};

export type ClienteAsaas = {
  garantirCliente(args: {
    nome: string;
    email: string;
    cpf: string;
    referencia: string;
  }): Promise<string>;
  criarPix(args: {
    customerId: string;
    valorReais: number;
    dueDate: string;
    descricao: string;
    referencia: string;
  }): Promise<{ id: string; status: string; payload: string; encodedImage: string }>;
  consultarPagamento(id: string): Promise<PagamentoAsaas>;
};

export function urlBaseAsaas(ambiente: string): string {
  const normalizado = ambiente.trim().toLowerCase();
  if (normalizado === "producao" || normalizado === "production" || normalizado === "prod") {
    return "https://api.asaas.com/v3";
  }
  return "https://api-sandbox.asaas.com/v3";
}

function mensagemAsaas(data: unknown, status: number): string {
  const erros = (data as { errors?: Array<{ description?: string }> } | null)?.errors;
  const desc = typeof erros?.[0]?.description === "string" ? erros[0].description.trim() : "";
  if (desc && desc.length <= 180 && !/token|api[_ ]?key|secret/i.test(desc)) return desc;
  if (status === 401 || status === 403) return "Pagamento Pix indisponível no momento.";
  return "Não foi possível falar com o Asaas.";
}

async function asaasFetch<T>(
  base: string,
  apiKey: string,
  path: string,
  method: string,
  body?: unknown,
): Promise<T> {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      access_token: apiKey,
      "User-Agent": "FacaAFesta/1.0 (Firebase Functions)",
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const erros = (data as { errors?: Array<{ code?: string }> } | null)?.errors;
    logger.error("Asaas HTTP", {
      status: response.status,
      codes: Array.isArray(erros) ? erros.map((e) => e.code ?? "").join(",") : "",
    });
    const codigo = response.status === 400 || response.status === 422
      ? "invalid-argument"
      : response.status === 401 || response.status === 403
        ? "failed-precondition"
        : "internal";
    throw new HttpsError(codigo, mensagemAsaas(data, response.status));
  }
  return data as T;
}

export function criarClienteHttpAsaas(params: {
  apiKey: string;
  ambiente: string;
}): ClienteAsaas {
  const base = urlBaseAsaas(params.ambiente);
  const apiKey = params.apiKey;

  return {
    async garantirCliente(args) {
      const lista = await asaasFetch<{ data?: Array<{ id?: string }> }>(
        base,
        apiKey,
        `/customers?externalReference=${encodeURIComponent(args.referencia)}`,
        "GET",
      );
      const existente = String(lista?.data?.[0]?.id ?? "").trim();
      const corpo = {
        name: args.nome,
        email: args.email,
        cpfCnpj: args.cpf,
        externalReference: args.referencia,
        notificationDisabled: true,
      };
      if (!existente) {
        const criado = await asaasFetch<{ id?: string }>(base, apiKey, "/customers", "POST", corpo);
        const id = String(criado?.id ?? "").trim();
        if (!id) throw new HttpsError("internal", "Asaas não retornou o cliente da cobrança.");
        return id;
      }
      try {
        await asaasFetch(base, apiKey, `/customers/${encodeURIComponent(existente)}`, "PUT", corpo);
      } catch (e) {
        logger.warn("Asaas não atualizou o cliente existente", {
          code: e instanceof HttpsError ? e.code : "unknown",
        });
      }
      return existente;
    },

    async criarPix(args) {
      const payment = await asaasFetch<{ id?: string; status?: string }>(
        base,
        apiKey,
        "/payments",
        "POST",
        {
          customer: args.customerId,
          billingType: "PIX",
          value: args.valorReais,
          dueDate: args.dueDate,
          description: args.descricao,
          externalReference: args.referencia,
        },
      );
      const id = String(payment?.id ?? "").trim();
      if (!id) throw new HttpsError("internal", "Asaas não retornou o identificador do Pix.");
      const qr = await asaasFetch<{ payload?: string; encodedImage?: string }>(
        base,
        apiKey,
        `/payments/${encodeURIComponent(id)}/pixQrCode`,
        "GET",
      );
      const payload = String(qr?.payload ?? "").trim();
      if (!payload) throw new HttpsError("internal", "Asaas não devolveu o código Pix.");
      return {
        id,
        status: String(payment.status ?? "PENDING"),
        payload,
        encodedImage: String(qr?.encodedImage ?? ""),
      };
    },

    async consultarPagamento(id) {
      const payment = await asaasFetch<{
        id?: string;
        status?: string;
        value?: number;
        externalReference?: string;
      }>(base, apiKey, `/payments/${encodeURIComponent(id)}`, "GET");
      const paymentId = String(payment?.id ?? "").trim();
      if (!paymentId) throw new HttpsError("internal", "Asaas não devolveu a cobrança.");
      return {
        id: paymentId,
        status: String(payment.status ?? ""),
        value: Number(payment.value ?? 0),
        externalReference: String(payment.externalReference ?? ""),
      };
    },
  };
}
