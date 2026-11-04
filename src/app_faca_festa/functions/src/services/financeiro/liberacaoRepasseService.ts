import { createHash } from "crypto";
import { Firestore, Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { centavosDeOrcamento } from "./dashboardAdminService";

export const COL_AUTORIZACOES = "plataforma_autorizacoes_repasses";

export function contratado(d: Record<string, any>): boolean {
  const comercial = d.contrato_financeiro?.estado_comercial;
  if ([comercial, d.status].some(s => ["cancelado", "cancelada", "estornado"].includes(s))) return false;
  return comercial === "contratado" || d.orcamento_fechado === true ||
    ["fechado", "contratado"].includes(d.status);
}

/** Comissão efetivamente registrada no contrato; nunca confia na taxa enviada pela UI. */
export function divisaoContrato(d: Record<string, any>, obrigacoes: Record<string, any>[]) {
  const valor = centavosDeOrcamento(d).contratado;
  const o = obrigacoes.length === 1 ? obrigacoes[0] : null;
  const p = o?.politica_aplicada;
  const comissao = Number(o?.valor_original?.centavos) + Number(o?.valor_ajustes_centavos ?? 0);
  const base = Number(o?.base_elegivel?.centavos);
  const liquidado = Number(o?.valor_liquidado?.centavos ?? 0);
  const retencaoRegistrada = Number(o?.liquidado_por_retencao_repasse_centavos ?? 0);
  const valida = contratado(d) && valor > 0 && o && o.status !== "estornada" &&
    Number.isSafeInteger(comissao) && comissao >= 0 && Number.isSafeInteger(base) && base >= 0 && base <= valor &&
    o.id_evento === d.id_evento && o.id_fornecedor === d.id_fornecedor &&
    Number.isInteger(p?.percentual_bps) && p.percentual_bps >= 0 && p.percentual_bps <= 10000 &&
    ["fornecedor", "organizador", "plataforma_absorve"].includes(p?.pagador) &&
    (p.pagador !== "fornecedor" || comissao <= valor) &&
    Number.isSafeInteger(liquidado) && Number.isSafeInteger(retencaoRegistrada) &&
    retencaoRegistrada >= 0 && retencaoRegistrada <= liquidado && liquidado <= comissao;
  if (!valida) return null;
  const recebidoSeparadamente = liquidado - retencaoRegistrada;
  const reservaNoContrato = p.pagador === "plataforma_absorve" ? 0 : comissao - recebidoSeparadamente;
  const retida = p.pagador === "fornecedor" ? reservaNoContrato : 0;
  return {
    valorContratadoCentavos: valor,
    percentualBps: p.percentual_bps as number,
    comissaoCentavos: comissao,
    comissaoRecebidaSeparadamenteCentavos: recebidoSeparadamente,
    comissaoReservadaNoContratoCentavos: reservaNoContrato,
    comissaoExternaOrganizadorCentavos: p.pagador === "organizador" ? recebidoSeparadamente : 0,
    direitoFornecedorCentavos: valor - retida,
    precoClienteCentavos: valor + (p.pagador === "organizador" ? comissao : 0),
    pagadorComissao: p.pagador as string,
    idObrigacao: o.id_obrigacao as string,
    politicaId: p.id_politica ?? null,
    politicaVersao: p.versao ?? null,

  };
}

export function assinaturaContrato(id: string, d: Record<string, any>, divisao: unknown): string {
  return createHash("sha256").update(JSON.stringify([id, d.id_evento, d.id_fornecedor,
    d.contrato_financeiro?.id_contrato || id, divisao])).digest("hex");
}

export function impedimentoRepasse(params: {
  orcamento: Record<string, any>;
  evento: Record<string, any>;
  casos: Record<string, any>[];
  autorizacao?: Record<string, any>;
  assinatura: string;
}): string | null {
  const { orcamento: o, evento: e, casos, autorizacao: a } = params;
  if (!contratado(o)) return "A contratação precisa estar confirmada e ativa.";
  if (["cancelado", "cancelada"].includes(e.status)) return "Evento cancelado: repasse bloqueado.";
  if (["contestado", "cancelado", "cancelado_execucao"].includes(o.contrato_financeiro?.estado_execucao || o.estado_execucao)) {
    return "Execução contestada ou cancelada: resolva a pendência antes do repasse.";
  }
  if (casos.some(c => !["fechado", "cancelado_caso"].includes(c.estado) || c.retencao_efetiva_ativa === true)) {
    return "Repasse bloqueado por mediação: conclua a análise e resolva a retenção.";
  }
  if (e.status === "finalizado") return null;
  const dono = e.id_usuario || e.idUsuario;
  if (a?.ativa === true && a.autor_id === dono && a.assinatura_contrato === params.assinatura) return null;
  return "Aguarde a finalização do evento ou a autorização explícita do organizador.";
}

/** Todas as condições são relidas dentro da transação de autorização/confirmação. */
export async function carregarContextoRepasse(db: Firestore, tx: Transaction, idOrcamento: string) {
  const ref = db.collection("orcamento").doc(idOrcamento);
  const snap = await tx.get(ref);
  if (!snap.exists) throw new HttpsError("not-found", "Contrato não encontrado.");
  const orcamento = snap.data()!;
  if (!orcamento.id_evento) throw new HttpsError("failed-precondition", "Contrato sem evento.");
  const idContrato = orcamento.contrato_financeiro?.id_contrato || idOrcamento;
  const eventoSnap = await tx.get(db.collection("evento").doc(orcamento.id_evento));
  if (!eventoSnap.exists) throw new HttpsError("not-found", "Evento não encontrado.");
  const evento = eventoSnap.data()!;
  const obrigacoes = await tx.get(db.collection("plataforma_comissao_obrigacoes").where("id_contrato", "==", idContrato));
  const casos = await tx.get(db.collection("plataforma_mediacao_casos").where("id_orcamento", "==", idOrcamento));
  const autorizacao = await tx.get(db.collection(COL_AUTORIZACOES).doc(idOrcamento));
  const divisao = divisaoContrato(orcamento, obrigacoes.docs.map(d => ({ id_obrigacao: d.id, ...d.data() })));
  const assinatura = assinaturaContrato(idOrcamento, orcamento, divisao);
  const motivo = !divisao ? "Comissão do contrato ausente ou inconsistente: confira a política e a obrigação."
    : impedimentoRepasse({ orcamento, evento, casos: casos.docs.map(d => d.data()),
      autorizacao: autorizacao.data(), assinatura });
  return { ref, orcamento, evento, divisao, assinatura, motivo, idContrato,
    casos: casos.docs.map(d => ({ ...d.data(), id: d.id })) };
}
