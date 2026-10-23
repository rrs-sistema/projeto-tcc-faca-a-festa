import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo } from "../../shared/auth";
import { exigirAcessoFinanceiroEvento } from "../../services/financeiro/autorizacaoFinanceiro";
import { exigirAcessoFinanceiroFornecedor } from "../../services/financeiro/autorizacaoFornecedorFinanceiro";
import {
  acaoExibidaEhSegura,
  rotulosAcaoPermitidos,
  CTAS_INTEGRACAO_AUSENTE,
} from "../../services/financeiro/acompanhamentoPartesService";
import {
  atualizarExecucaoContrato,
  declararPagamentoCliente,
  listarAcompanhamentoFornecedor,
  listarAcompanhamentoOrganizador,
} from "../../services/financeiro/acompanhamentoPersistenciaService";
import { abrirCasoMediacao } from "../../services/financeiro/mediacaoPersistenciaService";
import { CategoriaCaso } from "../../services/financeiro/mediacaoOperacionalService";

const REGION = "southamerica-east1";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function inteiro(v: unknown, nome: string): number {
  if (typeof v !== "number" || !Number.isInteger(v) || v <= 0) {
    throw new HttpsError("invalid-argument", `Informe ${nome} inteiro positivo.`);
  }
  return v;
}

/** Sem gateway/saque/garantia nesta entrega. */
const INTEGRACAO = {
  temGatewayPagamento: false,
  temSaque: false,
  temGarantia: false,
};

export const consultarAcompanhamentoOrganizadorFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento);

    const r = await listarAcompanhamentoOrganizador(admin.firestore(), {
      idEvento,
      uid: perfil.uid,
    });
    const acoes = rotulosAcaoPermitidos(INTEGRACAO);
    return {
      ok: true,
      ...r,
      acoes_permitidas: acoes,
      acoes_bloqueadas: [...CTAS_INTEGRACAO_AUSENTE].filter(
        (a) => !acaoExibidaEhSegura(a, acoes),
      ),
      aviso_integracao:
        "Não há cobrança/saque automático. Use declaração e comprovante; upload não confirma sozinho.",
    };
  },
);

export const consultarAcompanhamentoFornecedorFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor =
      texto(data.idFornecedor ?? data.id_fornecedor) || perfil.uid;
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor,
    );

    const r = await listarAcompanhamentoFornecedor(admin.firestore(), {
      idFornecedor,
    });
    const acoes = rotulosAcaoPermitidos(INTEGRACAO);
    return {
      ok: true,
      ...r,
      acoes_permitidas: acoes,
      acoes_bloqueadas: [...CTAS_INTEGRACAO_AUSENTE].filter(
        (a) => !acaoExibidaEhSegura(a, acoes),
      ),
      aviso:
        "Valores pagos pelo cliente ao APP não entram como caixa próprio. "
        + "Repasse da plataforma é origem distinta de recebimento próprio.",
      aviso_integracao:
        "Sem botão Sacar/Pagamento garantido — integração não configurada.",
    };
  },
);

export const declararPagamentoPlataformaFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idEvento = texto(data.idEvento ?? data.id_evento);
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      idOrcamento,
    });

    const r = await declararPagamentoCliente(admin.firestore(), {
      idOrcamento,
      idEvento,
      valorCentavos: inteiro(
        data.valorCentavos ?? data.valor_centavos,
        "valorCentavos",
      ),
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
      autorId: perfil.uid,
      referenciaComprovante: texto(
        data.referenciaComprovante ?? data.referencia_comprovante,
      ) || null,
    });
    return {
      ...r,
      aviso:
        "Declaração registrada. Não confirma recebimento pela plataforma nem libera repasse.",
    };
  },
);

export const informarEntregaFornecedorFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    const orc = await admin.firestore().collection("orcamento").doc(idOrcamento).get();
    if (!orc.exists) throw new HttpsError("not-found", "Contrato não encontrado.");
    const idFornecedor = texto(orc.data()?.id_fornecedor);
    await exigirAcessoFinanceiroFornecedor(
      admin.firestore(),
      perfil,
      idFornecedor || perfil.uid,
    );

    const r = await atualizarExecucaoContrato(admin.firestore(), {
      idOrcamento,
      acao: "informar_entrega",
      autorId: perfil.uid,
      papel: "fornecedor",
      motivo: texto(data.motivo) || "Entrega informada pelo fornecedor",
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
    });
    return {
      ok: true,
      ...r,
      aviso: "Entrega informada. Aceite do cliente é ação separada.",
    };
  },
);

export const registrarAceiteClienteFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    const orc = await admin.firestore().collection("orcamento").doc(idOrcamento).get();
    if (!orc.exists) throw new HttpsError("not-found", "Contrato não encontrado.");
    const idEvento = texto(orc.data()?.id_evento);
    await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
      idOrcamento,
    });
    const contestar = data.contestar === true;
    const r = await atualizarExecucaoContrato(admin.firestore(), {
      idOrcamento,
      acao: contestar ? "contestar" : "aceitar",
      autorId: perfil.uid,
      papel: "cliente",
      motivo: texto(data.motivo) || (contestar ? "Contestação" : "Aceite"),
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
    });
    return {
      ok: true,
      ...r,
      aviso: contestar
        ? "Contestação registrada. Não executa reembolso silencioso."
        : "Aceite registrado. Pagamento prévio não substitui esta ação.",
    };
  },
);

export const abrirCasoMediacaoParteFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    const orc = await admin.firestore().collection("orcamento").doc(idOrcamento).get();
    if (!orc.exists) throw new HttpsError("not-found", "Contrato não encontrado.");
    const d = orc.data()!;
    const idEvento = texto(d.id_evento);
    const idFornecedor = texto(d.id_fornecedor);
    const idContratante = texto(d.id_solicitante);

    const isForn = idFornecedor === perfil.uid;
    const isCli =
      idContratante === perfil.uid ||
      (await admin.firestore().collection("evento").doc(idEvento).get())
        .data()?.id_usuario === perfil.uid;

    if (!isForn && !isCli && perfil.tipo !== "A") {
      throw new HttpsError("permission-denied", "Sem vínculo com este contrato.");
    }
    if (isCli) {
      await exigirAcessoFinanceiroEvento(admin.firestore(), perfil, idEvento, {
        idOrcamento,
      });
    }
    if (isForn) {
      await exigirAcessoFinanceiroFornecedor(
        admin.firestore(),
        perfil,
        idFornecedor,
      );
    }
    if (perfil.tipo === "A") exigirTipo(perfil, ["A"]);

    return abrirCasoMediacao(admin.firestore(), {
      idEvento,
      idContrato: texto((d.contrato_financeiro as { id?: string })?.id) || idOrcamento,
      idOrcamento,
      idFornecedor: idFornecedor || null,
      idContratante: idContratante || null,
      categoria: (texto(data.categoria) || "divergencia_servico") as CategoriaCaso,
      motivo: texto(data.motivo),
      descricao: texto(data.descricao),
      chaveIdempotencia: texto(
        data.chaveIdempotencia ?? data.chave_idempotencia,
      ),
      autorId: perfil.uid,
    });
  },
);
