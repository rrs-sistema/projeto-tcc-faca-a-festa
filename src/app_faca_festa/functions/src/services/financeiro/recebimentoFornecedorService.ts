import { createHash } from "crypto";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { contratado } from "./liberacaoRepasseService";
import { dinheiro, reaisParaCentavosArredondado, LIMITE_CENTAVOS } from "./dinheiro";

type M = Record<string, any>;
const texto = (v: unknown) => String(v ?? "").trim();
function id(v: unknown): string {
  const s = texto(v);
  if (!/^[a-zA-Z0-9_-]{1,128}$/.test(s)) throw new HttpsError("invalid-argument", "Identificador da operação inválido.");
  return s;
}
function valor(v: unknown): number {
  if (typeof v !== "number" || !Number.isSafeInteger(v) || v <= 0 || v > LIMITE_CENTAVOS) throw new HttpsError("invalid-argument", "Informe centavos inteiros positivos.");
  return dinheiro(v).centavos;
}
/** Assinatura semântica: defaults, ordem das alocações e aliases de transporte normalizados. */
export function normalizarRecebimento(data: M) {
  const permitidos = ['idFornecedor','id_fornecedor','idEvento','id_evento','chaveIdempotencia','chave_idempotencia','valorCentavos','valor_centavos','valorReais','valor_reais','tipo','idOrcamento','id_orcamento','alocacoes','motivo','execucaoConfirmada','execucao_confirmada','referenciaRecebimento','referencia_recebimento','copiarPagamentoCliente','copiar_pagamento_cliente'];
  if (Object.keys(data).some(k=>!permitidos.includes(k))) throw new HttpsError("invalid-argument", "Campo não permitido no recebimento.");
  if (data.copiarPagamentoCliente === true || data.copiar_pagamento_cliente === true) throw new HttpsError("failed-precondition", "Declaração do cliente não é recebimento próprio.");
  const tipoRaw = texto(data.tipo) || 'recebimento';
  const tipo = tipoRaw === 'recebimento' ? 'recebimento_externo' : tipoRaw;
  if (!['recebimento_externo','adiantamento','estorno'].includes(tipo)) throw new HttpsError("invalid-argument", "Repasse só vem da plataforma; tipo próprio inválido.");
  const centavos = valor(data.valorCentavos ?? data.valor_centavos ?? reaisParaCentavosArredondado(Number(data.valorReais ?? data.valor_reais)));
  const informado = texto(data.idOrcamento ?? data.id_orcamento);
  if (informado && data.alocacoes != null) throw new HttpsError("invalid-argument", "Informe contrato único ou alocações, não ambos.");
  if (data.alocacoes != null && (!Array.isArray(data.alocacoes) || data.alocacoes.length > 30)) throw new HttpsError("invalid-argument", "Alocações inválidas (máximo 30).");
  const alocacoes = data.alocacoes != null ? data.alocacoes.map((a:M) => {
    if (!a || Object.keys(a).some(k=>!['idContrato','idOrcamento','valorCentavos'].includes(k))) throw new HttpsError("invalid-argument", "Alocação inválida.");
    return {id: id(a.idContrato ?? a.idOrcamento), centavos:valor(a.valorCentavos)};
  }) : informado ? [{id:id(informado),centavos}] : null;
  if (alocacoes && (new Set(alocacoes.map((a:{id:string})=>a.id)).size !== alocacoes.length || alocacoes.reduce((s:number,a:{centavos:number})=>s+a.centavos,0)>centavos)) throw new HttpsError("invalid-argument", "Alocações repetidas ou superiores ao recebimento.");
  const motivo = texto(data.motivo);
  if (motivo.length>500) throw new HttpsError("invalid-argument", "Motivo muito longo.");
  const referencia = texto(data.referenciaRecebimento ?? data.referencia_recebimento) || null;
  if (referencia) id(referencia);
  if ((tipo === 'estorno') !== !!referencia) throw new HttpsError("invalid-argument", "Estorno exige referência ao recebimento original.");
  return { idFornecedor:id(data.idFornecedor ?? data.id_fornecedor), chave:id(data.chaveIdempotencia ?? data.chave_idempotencia),
    pedido:{idEvento:id(data.idEvento ?? data.id_evento), tipo, centavos,
      alocacoes:alocacoes?.sort((a:{id:string},b:{id:string})=>a.id.localeCompare(b.id)) ?? null,
      referencia, motivo, execucaoInformada:data.execucaoConfirmada === true || data.execucao_confirmada === true} };
}
export function assinaturaRecebimento(data: M): string {
  const ordenar = (v:any):any => Array.isArray(v) ? v.map(ordenar) : v && typeof v === 'object' ? Object.fromEntries(Object.keys(v).sort().map(k=>[k,ordenar(v[k])])) : v;
  return createHash('sha256').update(JSON.stringify(ordenar(data))).digest('hex');
}

export function operacaoRecebimentoCompleta(f?:M,m?:M,a?:M):boolean {
  if(!f || !m || !a || !f.pedido || !f.assinatura_operacao) return false;
  return f.assinatura_operacao === assinaturaRecebimento({idFornecedor:f.id_fornecedor,chave:f.chave_idempotencia,pedido:f.pedido}) &&
    m.assinatura_operacao===f.assinatura_operacao && a.assinatura_operacao===f.assinatura_operacao &&
    f.valor?.centavos===f.pedido.centavos && m.valor?.centavos===f.valor.centavos &&
    m.entrada===(f.tipo!=='estorno') && m.id_recebimento_origem===f.id_recebimento && a.id_recebimento===f.id_recebimento &&
    f.id_evento===f.pedido.idEvento && m.id_evento===f.id_evento && a.id_evento===f.id_evento &&
    assinaturaRecebimento(a.pedido)===assinaturaRecebimento(f.pedido) &&
    assinaturaRecebimento({alocacoes:a.alocacoes})===assinaturaRecebimento({alocacoes:f.alocacoes});
}

export async function registrarOperacaoRecebimento(db: Firestore, data: M, autorId: string,
  opcoes: {antesCommit?: () => void} = {}) {
  const n = normalizarRecebimento(data);
  if (n.idFornecedor !== autorId) throw new HttpsError('permission-denied','Recebimento de outro fornecedor.');
  const assinatura = assinaturaRecebimento(n);
  const base = db.collection('fornecedor').doc(n.idFornecedor);
  const ref = base.collection('contas_receber').doc(n.chave);
  const movimento = base.collection('movimentos_caixa').doc(n.chave);
  const auditoria = base.collection('financeiro_auditoria').doc(n.chave);
  return db.runTransaction(async tx => {
    const [existente, espelho, audit] = await Promise.all([tx.get(ref),tx.get(movimento),tx.get(auditoria)]);
    if (existente.exists) {
      const d = existente.data()!;
      if (!d.assinatura_operacao) throw new HttpsError('failed-precondition','Operação legada sem assinatura: confira o lançamento existente.');
      if (d.assinatura_operacao !== assinatura) throw new HttpsError('already-exists','Mesma chave com payload diferente.');
      if (!operacaoRecebimentoCompleta(d,espelho.data(),audit.data())) throw new HttpsError('failed-precondition','Operação incompleta: confira os registros preservados.');
      return {ok:true,idRecebimento:ref.id,idempotente:true};
    }
    if (espelho.exists || audit.exists) throw new HttpsError('failed-precondition','Chave com projeção órfã; nenhum registro foi sobrescrito.');
    const orcs = await tx.get(db.collection('orcamento').where('id_fornecedor','==',n.idFornecedor));
    const candidatos = orcs.docs.filter(d=>d.data().id_evento === n.pedido.idEvento);
    if(n.pedido.tipo!=='estorno' && !candidatos.some(c=>contratado(c.data()))) throw new HttpsError('failed-precondition','Sem contratação ativa do fornecedor neste evento.');
    const canon = (idInformado: string) => {
      const d = candidatos.find(d=>d.id === idInformado) || candidatos.find(d=>d.data().contrato_financeiro?.id_contrato === idInformado);
      if (!d || (n.pedido.tipo !== 'estorno' && !contratado(d.data()))) throw new HttpsError('failed-precondition','Contrato de outro evento/fornecedor ou não ativo.');
      return {id_contrato:String(d.data().contrato_financeiro?.id_contrato || d.id), id_orcamento:d.id};
    };
    const alocs = (d:M) => {
      const originais=alocacoesDoFato(d);
      if(originais.some(a=>!Number.isSafeInteger(a.centavos) || a.centavos<0) || originais.reduce((s,a)=>s+a.centavos,0)>Number(d.valor?.centavos)) throw new HttpsError('failed-precondition','Alocações originais inconsistentes.');
      return originais.filter(a=>candidatos.some(c=>c.id===a.id_contrato || c.data().contrato_financeiro?.id_contrato===a.id_contrato))
        .map(a=>({...a,id_contrato:canon(a.id_contrato).id_contrato}));
    };
    let origem: FirebaseFirestore.DocumentSnapshot | null = null;
    let estornos: FirebaseFirestore.QuerySnapshot | null = null;
    if (n.pedido.referencia) {
      origem = await tx.get(base.collection('contas_receber').doc(n.pedido.referencia));
      estornos = await tx.get(base.collection('contas_receber').where('referencia_recebimento','==',n.pedido.referencia));
      if (!origem.exists || ['estorno','repasse','repasse_plataforma'].includes(origem.data()?.tipo) || origem.data()?.origem === 'repasse_plataforma' || origem.data()?.id_evento !== n.pedido.idEvento) throw new HttpsError('failed-precondition','Recebimento original inválido.');
      valor(origem.data()?.valor?.centavos);
      for(const e of estornos.docs) valor(e.data().valor?.centavos);
    }
    let entradas = n.pedido.alocacoes;
    if (entradas == null) {
      if (origem) {
        const anterior = origem.data()!;
        const totalEstornado = estornos!.docs.reduce((s,d)=>s+Number(d.data().valor?.centavos || 0),0);
        if (n.pedido.centavos !== Number(anterior.valor?.centavos) - totalEstornado) throw new HttpsError('invalid-argument','Estorno parcial exige alocação explícita.');
        const originais = alocs(anterior);
        entradas = originais.map(a=>({id:a.id_contrato,centavos:a.centavos - estornos!.docs.reduce((s,d)=>s+alocs(d.data()).filter(x=>x.id_contrato===a.id_contrato).reduce((v,x)=>v+x.centavos,0),0)})).filter(a=>a.centavos>0);
      } else {
        const ativos = candidatos.filter(d=>contratado(d.data()));
        const ids = [...new Set(ativos.map(d=>String(d.data().contrato_financeiro?.id_contrato || d.id)))];
        if (ids.length !== 1) throw new HttpsError('invalid-argument','Selecione contrato(s) ou informe explicitamente alocações vazias.');
        entradas = [{id:ids[0],centavos:n.pedido.centavos}];
      }
    }
    const alocacoes = entradas!.map((a:{id:string;centavos:number})=>({...canon(a.id),centavos:a.centavos}));
    if (new Set(alocacoes.map((a:{id_contrato:string})=>a.id_contrato)).size !== alocacoes.length) throw new HttpsError('invalid-argument','A mesma contratação aparece em dois espelhos.');
    const naoAlocado = n.pedido.centavos - alocacoes.reduce((s:number,a:{centavos:number})=>s+a.centavos,0);
    if (origem) {
      const d = origem.data()!;
      const anteriores = estornos!.docs.map(d=>d.data());
      const estornado = anteriores.reduce((s,d)=>s+Number(d.valor?.centavos || 0),0);
      if (estornado+n.pedido.centavos>Number(d.valor?.centavos)) throw new HttpsError('failed-precondition','Estorno superior ao recebimento ainda disponível.');
      const originais = alocs(d);
      for (const a of alocacoes) {
        const limite = originais.filter(o=>o.id_contrato===a.id_contrato).reduce((s,o)=>s+o.centavos,0);
        const ja = anteriores.reduce((s,d)=>s+alocs(d).filter(o=>o.id_contrato===a.id_contrato).reduce((s,o)=>s+o.centavos,0),0);
        if (a.centavos+ja>limite) throw new HttpsError('failed-precondition','Estorno excede a alocação original do contrato.');
      }
      const livreOriginal = Number(d.valor?.centavos) - originais.reduce((s,a)=>s+a.centavos,0);
      const livreEstornado = anteriores.reduce((s,d)=>s+Number(d.valor?.centavos || 0)-alocs(d).reduce((s,a)=>s+a.centavos,0),0);
      if (naoAlocado+livreEstornado>livreOriginal) throw new HttpsError('failed-precondition','Estorno não alocado superior à parcela livre original.');
      // Contenção também no documento original, sem mudar valor, autor ou datas do fato.
      tx.update(origem.ref,{estornado_centavos:estornado+n.pedido.centavos});
    }
    const comum = {schema:2, id_fornecedor:n.idFornecedor, id_evento:n.pedido.idEvento,
      id_operacao:n.chave, chave_idempotencia:n.chave, assinatura_operacao:assinatura,
      autor_id:autorId, criado_em:FieldValue.serverTimestamp(), confirmacao_bancaria:false};
    tx.create(ref,{...comum,id_recebimento:ref.id,pedido:n.pedido,valor:dinheiro(n.pedido.centavos),tipo:n.pedido.tipo,
      origem:n.pedido.tipo === 'estorno' ? 'estorno_recebimento' : 'recebimento_proprio_declarado',
      alocacoes, nao_alocado_centavos:naoAlocado,
      id_contrato:alocacoes.length === 1 ? alocacoes[0].id_contrato : null,
      id_orcamento:alocacoes.length === 1 ? alocacoes[0].id_orcamento : null,
      referencia_recebimento:n.pedido.referencia, adiantamento:n.pedido.tipo === 'adiantamento',
      execucao_informada:n.pedido.execucaoInformada,execucao_confirmada:false,receita_realizada:false,
      confirmacao:'declarada_manual',perspectiva:'fornecedor_recebedor',motivo:n.pedido.motivo});
    tx.create(movimento,{...comum,id_movimento:n.chave,id_recebimento_origem:ref.id,
      valor:dinheiro(n.pedido.centavos),entrada:n.pedido.tipo !== 'estorno',tipo:n.pedido.tipo,
      origem:n.pedido.tipo === 'estorno' ? 'estorno_recebimento' : 'recebimento_proprio_declarado'});
    tx.create(auditoria,{...comum,acao:n.pedido.tipo,id_recebimento:ref.id,pedido:n.pedido,alocacoes});
    for (const d of candidatos.filter(d=>alocacoes.some((a:{id_contrato:string})=>String(d.data().contrato_financeiro?.id_contrato || d.id)===a.id_contrato))) tx.update(d.ref,{repasse_revisao:FieldValue.increment(1)});
    opcoes.antesCommit?.();
    return {ok:true,idRecebimento:ref.id,idempotente:false};
  });
}

export function alocacoesDoFato(d:M): Array<{id_contrato:string;centavos:number}> {
  if (Array.isArray(d.alocacoes)) return d.alocacoes.map(a=>({id_contrato:String(a.id_contrato),centavos:Number(a.centavos)}));
  const id = d.id_contrato || d.id_orcamento;
  return id ? [{id_contrato:String(id),centavos:Number(d.valor?.centavos || 0)}] : [];
}
