import { consultarPlanejamentoComFatos } from "../../services/financeiro/planejamentoFornecedorService";
import { createHash } from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { randomUUID } from "crypto";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { exigirAcessoFinanceiroFornecedor } from "../../services/financeiro/autorizacaoFornecedorFinanceiro";
import { dinheiro, reaisParaCentavosArredondado } from "../../services/financeiro/dinheiro";
import { registrarOperacaoRecebimento, normalizarRecebimento, assinaturaRecebimento, operacaoRecebimentoCompleta } from "../../services/financeiro/recebimentoFornecedorService";
import { calcularResumoFornecedor, projetarCaixaRecebimentos } from "../../services/financeiro/resumoFornecedorService";

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


    const desembolso =
      origem === "estoque_consumo"
        ? 0
        : resolverCentavosOpcional(data.desembolsoCentavos ?? data.desembolso_centavos) ??
          (origem === "desembolso" ? centavos : 0);
    const restante =
      resolverCentavosOpcional(
        data.previstoRestanteCentavos ?? data.previsto_restante_centavos,
      ) ?? 0;

    const assinatura = createHash("sha256").update(JSON.stringify(data)).digest("hex");
    return admin.firestore().runTransaction(async tx => {
    const existente = await tx.get(ref);
    if(existente.exists){if(existente.data()?.assinatura_operacao!==assinatura)throw new HttpsError("already-exists","Custo legado/divergente: confira o registro original.");return {ok:true,idCusto:ref.id,idempotente:true};}
    const obrigacao = resolverCentavosOpcional(data.obrigacaoCentavos ?? data.obrigacao_centavos) ?? 0;
    if(obrigacao>0 && desembolso>obrigacao)throw new HttpsError("invalid-argument","Desembolso excede obrigação.");
    tx.create(ref,{
      assinatura_operacao:assinatura,
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

    if(obrigacao>0)tx.create(ref.parent.parent!.collection("contas_pagar").doc(ref.id),{schema:2,id_custo:ref.id,id_obrigacao:ref.id,id_fornecedor:idFornecedor,id_evento:idEvento,valor:dinheiro(obrigacao),pago_liquido:dinheiro(desembolso),vencimento:null,origem,descricao:texto(data.descricao)||null,status:desembolso===obrigacao?"paga":desembolso?"parcial":"aberta",autor_id:perfil.uid,criado_em:FieldValue.serverTimestamp()});
    tx.create(ref.parent.parent!.collection("financeiro_auditoria").doc("custo_"+ref.id),{acao:"registrar_custo",id_custo:ref.id,assinatura_operacao:assinatura,autor_id:perfil.uid,criado_em:FieldValue.serverTimestamp()});
    return { ok: true, idCusto: ref.id, idempotente: false };
    });
  },
);

export const registrarRecebimentoFornecedor = onCall(
  {region:REGION,timeoutSeconds:60,cors:true}, async request => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idFornecedor = texto(data.idFornecedor ?? data.id_fornecedor);
    await exigirAcessoFinanceiroFornecedor(admin.firestore(),perfil,idFornecedor);
    return registrarOperacaoRecebimento(admin.firestore(),data,perfil.uid);
  });

export const consultarOperacaoRecebimentoFornecedor = onCall(
  {region:REGION,timeoutSeconds:30,cors:true}, async request => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, any>;
    const idFornecedor = texto(data.idFornecedor);
    await exigirAcessoFinanceiroFornecedor(admin.firestore(),perfil,idFornecedor);
    const chave = texto(data.chaveIdempotencia);
    if (!/^[a-zA-Z0-9_-]{1,128}$/.test(chave)) throw new HttpsError('invalid-argument','Chave inválida.');
    const base=admin.firestore().collection('fornecedor').doc(idFornecedor);
    return admin.firestore().runTransaction(async tx => {
      const [d,m,a]=await Promise.all([tx.get(base.collection('contas_receber').doc(chave)),tx.get(base.collection('movimentos_caixa').doc(chave)),tx.get(base.collection('financeiro_auditoria').doc(chave))]);
      if (!d.exists) {
        if(m.exists || a.exists) throw new HttpsError('failed-precondition','Operação inconsistente: projeção sem fato.');
        return {ok:true,encontrado:false};
      }
      const assinatura=d.data()?.assinatura_operacao;
      if (!operacaoRecebimentoCompleta(d.data(),m.data(),a.data())) throw new HttpsError('failed-precondition','Operação legada ou incompleta: reconciliação manual necessária.');
      if (data.pedido && assinaturaRecebimento(normalizarRecebimento({...data.pedido,idFornecedor,chaveIdempotencia:chave})) !== assinatura) throw new HttpsError('already-exists','Payload da operação pendente diverge.');
      return {ok:true,encontrado:true,idRecebimento:d.id};
    },{readOnly:true});
  });

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
    const {planejamento,visoes,recebimentos,custos:custosSnap,movimentos:movimentosSnap} =
      await consultarPlanejamentoComFatos(db,idFornecedor,{idEvento});
    const selecionados = visoes.filter(v => !idEvento || v.idEvento === idEvento);
    if (selecionados.some(v => v.ativo && !v.disponivel)) {
      throw new HttpsError("failed-precondition", "Comissão contratada ausente ou inconsistente. Valores líquidos indisponíveis; confira a obrigação do contrato.");
    }
    const aliases = new Map<string,string>();
    for (const v of visoes) { aliases.set(v.idContrato,v.idContrato); for (const alias of v.aliases) aliases.set(alias,v.idContrato); }
    const caixa = projetarCaixaRecebimentos(recebimentos.docs.map(d=>({id:d.id,data:d.data()})),movimentosSnap.docs.map(d=>({id:d.id,data:d.data()})),aliases,idEvento);
    const contratos = selecionados.map(v => {
      const declarado = caixa.porContrato.get(v.idContrato) || 0;
      const saldo = v.liquidoCentavos == null ? null : v.liquidoCentavos - v.repasseConfirmadoCentavos - declarado;
      return { id:v.idContrato, idContrato:v.idContrato, idOrcamento:v.idOrcamento,
        idEvento:v.idEvento, nomeServico:v.nomeServico, revisao:v.revisao, revisaoComissao:v.revisaoComissao,
        valorContratado:v.brutoCentavos/100, comissao:v.comissaoCentavos == null ? null : v.comissaoCentavos/100,
        outrasDeducoes:0, liquidoPrevisto:v.liquidoCentavos == null ? null : v.liquidoCentavos/100,
        repasseAutorizado:v.repasseAutorizadoCentavos/100, repasseConfirmado:v.repasseConfirmadoCentavos/100, recebido:(v.repasseConfirmadoCentavos+declarado)/100,
        recebimentoProprioDeclarado:declarado/100,
        aReceber:saldo == null ? null : saldo/100, saldoContrato:saldo == null ? null : saldo/100,
        repassePendente:v.saldoCentavos == null ? null : v.saldoCentavos/100,
        creditoExcedente:saldo != null && saldo < 0 ? -saldo/100 : 0,
        comissaoRetida:v.comissaoRetidaCentavos == null ? null : v.comissaoRetidaCentavos/100,
        comissaoSeparada:v.comissaoSeparadaCentavos == null ? null : v.comissaoSeparadaCentavos/100,
        comissaoPrevistaRetencao:v.comissaoPrevistaRetencaoCentavos == null ? null : v.comissaoPrevistaRetencaoCentavos/100,
        situacao:!v.ativo ? "cancelado" : saldo != null && saldo<0 ? "credito_excedente" : saldo === 0 ? "recebido" : v.repasseConfirmadoCentavos+declarado > 0 ? "parcial" : "aguardando_repasse",
      };
    });
    const ativos = selecionados.filter(v => v.ativo);
    const vendas = ativos.map(v => ({ id:v.idContrato, id_evento:v.idEvento,
      valor_contratado:v.brutoCentavos/100, recebido_confirmado:(v.repasseConfirmadoCentavos+(caixa.porContrato.get(v.idContrato)||0))/100,
      liquido_previsto:v.liquidoCentavos!/100,
      execucao_confirmada:v.documento.contrato_financeiro?.estado_execucao === "aceito",
      receita_realizada:v.documento.contrato_financeiro?.estado_execucao === "aceito" ? (v.liquidoCentavos!-(v.divisao?.pagadorComissao==="fornecedor"?v.divisao.comissaoRecebidaSeparadamenteCentavos:0))/100 : 0 }));

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
      vendas,
      custos,
      receitaRealizadaLiquidaDeComissao:true,
      idEvento,
      saldoInicial:
        typeof data.saldoInicial === "number" ? data.saldoInicial : null,
      comissao: ativos.reduce((s,v) => s + (v.divisao?.pagadorComissao === "fornecedor" ? v.comissaoCentavos! : 0),0)/100,
      taxas: typeof data.taxas === "number" ? data.taxas : null,
      tributos: typeof data.tributos === "number" ? data.tributos : null,
    });

    const entradas = selecionados.reduce((s,v)=>s+v.repasseConfirmadoCentavos,0) + caixa.entradasCentavos;
    const saidas = Math.round(resumo.saidasCaixa*100) + caixa.saidasCentavos;
    const saldos = contratos.filter(c=>c.situacao !== 'cancelado').map(c=>Math.round((c.saldoContrato || 0)*100));
    const novosMovimentos=planejamento.movimentos as Array<{valorCentavos:number}>;
    const caixaPlanejado={entradasCaixa:novosMovimentos.filter(m=>m.valorCentavos>0).reduce((s,m)=>s+m.valorCentavos,0)/100,saidasCaixa:-novosMovimentos.filter(m=>m.valorCentavos<0).reduce((s,m)=>s+m.valorCentavos,0)/100,movimentoLiquido:planejamento.movimentoLiquidoCentavos/100};

    return {
      ok:true,idFornecedor,idEvento,...resumo,
      contratado:ativos.reduce((s,v)=>s+v.brutoCentavos,0)/100,
      recebido:(selecionados.reduce((s,v)=>s+v.repasseConfirmadoCentavos,0)+caixa.proprioLiquidoCentavos)/100,
      repasseConfirmado:selecionados.reduce((s,v)=>s+v.repasseConfirmadoCentavos,0)/100,
      aReceber:saldos.filter(s=>s>0).reduce((s,v)=>s+v,0)/100,
      creditoExcedente:-saldos.filter(s=>s<0).reduce((s,v)=>s+v,0)/100,
      saldoContrato:saldos.reduce((s,v)=>s+v,0)/100,
      saldoFinal:typeof data.saldoInicial === 'number' ? (Math.round(data.saldoInicial*100)+entradas-saidas)/100 : null,
      adiantamentosCaixa:caixa.adiantamentosCentavos/100,
      recebimentoNaoAlocado:caixa.naoAlocadoCentavos/100,
      repasseLegadoNaoConciliado:caixa.repasseLegadoNaoConciliadoCentavos/100,
      legadoCaixaNaoConciliado:caixa.movimentoLegadoNaoConciliadoCentavos/100,
      completo:resumo.completo && caixa.repasseLegadoNaoConciliadoCentavos === 0 && caixa.movimentoLegadoNaoConciliadoCentavos === 0,
      contratos,
      eventos:planejamento.resultados.map((r:{idEvento:string;nomeEvento:string|null})=>({idEvento:r.idEvento,nomeEvento:r.nomeEvento})),
      liquidoPrevisto:ativos.reduce((s,v)=>s+v.liquidoCentavos!,0)/100,
      comissaoDescontadaFornecedor:ativos.reduce((s,v)=>s+(v.divisao?.pagadorComissao === "fornecedor" ? v.comissaoCentavos! : 0),0)/100,
      comissaoContratada:ativos.reduce((s,v)=>s+(v.comissaoCentavos || 0),0)/100,
      repasseAutorizado:ativos.reduce((s,v)=>s+v.repasseAutorizadoCentavos,0)/100,
      recebimentoProprioDeclarado:caixa.proprioLiquidoCentavos/100,
      origem:"contratos_repasses",
      ...caixaPlanejado,
      resultadoDiretoPrevisto:planejamento.consolidado.resultadoDiretoPrevistoCentavos==null?resumo.resultadoDiretoPrevisto:planejamento.consolidado.resultadoDiretoPrevistoCentavos/100,
      resultadoDiretoRealizado:planejamento.consolidado.resultadoDiretoRealizadoCentavos==null?resumo.resultadoDiretoRealizado:planejamento.consolidado.resultadoDiretoRealizadoCentavos/100,
      ...('saldoInicial' in planejamento.config?{saldoFinal:planejamento.saldoAtualInformadoCentavos==null?null:planejamento.saldoAtualInformadoCentavos/100}:{}),
      planejamentoRevisao:planejamento.revisao,
      planejamentoCompleto:planejamento.completo,

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
