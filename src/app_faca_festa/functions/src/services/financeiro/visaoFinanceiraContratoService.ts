import { Firestore, Transaction } from "firebase-admin/firestore";
import { createHash } from "crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { contratado, divisaoContrato } from "./liberacaoRepasseService";
import { centavosDeOrcamento } from "./dashboardAdminService";

/** Projeção de leitura; não persiste nem duplica fatos financeiros. */
export async function visoesFinanceirasFornecedor(db: Firestore, idFornecedor: string, transacao?: Transaction) {
  const ler = async (tx: Transaction) => {
    const snap = await tx.get(db.collection("orcamento").where("id_fornecedor", "==", idFornecedor));
    const unicos = new Map<string, typeof snap.docs[number]>();
    for (const doc of snap.docs) {
      const d = doc.data();
      if (!contratado(d) && !d.orcamento_fechado && !d.contrato_financeiro) continue;
      const id = String(d.contrato_financeiro?.id_contrato || doc.id);
      const anterior = unicos.get(id);
      if (anterior && centavosDeOrcamento(anterior.data()).contratado !== centavosDeOrcamento(d).contratado) {
        throw new HttpsError("failed-precondition", "Espelhos conflitantes da mesma contratação: confira os valores.");
      }
      if (!anterior || doc.id === id) unicos.set(id, doc);
    }
    const linhas = [];
    for (const [idContrato, doc] of unicos) {
      const d = doc.data();
      const aliases = snap.docs.filter(x => String(x.data().contrato_financeiro?.id_contrato || x.id) === idContrato).map(x => x.id);
      const [obrigacoes, ...repasses] = await Promise.all([
        tx.get(db.collection("plataforma_comissao_obrigacoes").where("id_contrato", "==", idContrato)),
        ...aliases.map(alias => tx.get(db.collection("plataforma_repasses").where("id_orcamento", "==", alias))),
      ]);
      const reps = repasses.flatMap(r => r.docs);
      let confirmado = 0, autorizado = 0;
      for (const r of reps) {
        const p = r.data();
        if (p.id_fornecedor && p.id_fornecedor !== idFornecedor) throw new HttpsError("failed-precondition", "Repasse com vínculo inconsistente.");
        if (!Number.isSafeInteger(p.valor_centavos) || p.valor_centavos < 0) throw new HttpsError("failed-precondition", "Valor de repasse indisponível.");
        if (p.estado === "confirmado") confirmado += p.valor_centavos;
        if (["autorizado", "em_processamento"].includes(p.estado)) autorizado += p.valor_centavos;
      }
      const ativo = contratado(d);
      const divisao = divisaoContrato(d, obrigacoes.docs.map(o => ({...o.data(), id_obrigacao:o.id})));
      const bruto = centavosDeOrcamento(d).contratado;
      if (!Number.isSafeInteger(bruto) || bruto < 0) throw new HttpsError("failed-precondition", "Valor contratado indisponível.");
      const obrigacao = obrigacoes.size === 1 ? obrigacoes.docs[0].data() : null;
      const revisao = createHash("sha256").update(JSON.stringify([doc.updateTime, ...obrigacoes.docs.map(o=>o.updateTime), ...reps.map(r=>r.updateTime)])).digest("hex");
      linhas.push({idContrato, idOrcamento:doc.id, aliases, repasses:reps, idEvento:String(d.id_evento || ""),
        nomeServico:String(d.nome_servico || d.nome || d.categoria_nome || "Serviço contratado"),
        ativo, disponivel: !!divisao, brutoCentavos:bruto,
        obrigacaoComissaoId:obrigacoes.size===1?obrigacoes.docs[0].id:null,pagadorComissao:obrigacao?.politica_aplicada?.pagador??null,
        comissaoCentavos:divisao?.comissaoCentavos ?? null,
        comissaoRetidaCentavos: obrigacao ? Number(obrigacao.liquidado_por_retencao_repasse_centavos || 0) : null,
        comissaoSeparadaCentavos:divisao?.comissaoRecebidaSeparadamenteCentavos ?? null,
        comissaoPrevistaRetencaoCentavos:divisao ? (divisao.pagadorComissao === "plataforma_absorve" ? 0 : Math.max(0, divisao.comissaoCentavos - Number(obrigacao?.valor_liquidado?.centavos || 0))) : null,
        outrasDeducoesCentavos:0, liquidoCentavos:divisao?.direitoFornecedorCentavos ?? null,
        repasseAutorizadoCentavos:autorizado, repasseConfirmadoCentavos:confirmado,
        saldoCentavos:divisao ? Math.max(0,divisao.direitoFornecedorCentavos-confirmado) : null,
        revisao, revisaoComissao:obrigacoes.size === 1 ? obrigacoes.docs[0].updateTime.toDate().toISOString() : null, divisao, documento:d});
    }
    return linhas;
  };
  return transacao ? ler(transacao) : db.runTransaction(ler, {readOnly:true});
}
