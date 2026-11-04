import { prepararLiberacaoAgenda, validarInicioAgenda } from "../agenda/agendaFornecedorService";
import { transacaoIdempotente } from "../../shared/transacaoIdempotente";
import { projetarCaixaRecebimentos } from "./resumoFornecedorService";
import { visoesFinanceirasFornecedor } from "./visaoFinanceiraContratoService";
/**
 * Persistência do acompanhamento das partes + execução.
 */

import { createHash } from "crypto";
import { contratado } from "./liberacaoRepasseService";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import {
  EstadoExecucaoParte,
  montarVisaoFornecedor,
  montarVisaoOrganizador,
  NivelPagamentoPlataforma,
  transicionarExecucao,
  VisaoContratoFornecedor,
  VisaoContratoOrganizador,
} from "./acompanhamentoPartesService";
import {
  COL_ALOCACOES,
  COL_RECEBIMENTOS,
  COL_REPASSES,
} from "./intermediacaoPersistenciaService";
import { parseEstadoExecucao } from "./contratacaoIdentidadeService";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function parseData(v: unknown): string | null {
  if (!v) return null;
  if (typeof v === "string") return v;
  if (typeof v === "object" && v !== null && "toDate" in v) {
    try {
      return (v as { toDate: () => Date }).toDate().toISOString();
    } catch {
      return null;
    }
  }
  return null;
}

async function agregadosContrato(
  db: Firestore,
  idOrcamento: string,
): Promise<{
  declarado: number;
  alocado: number;
  repasseAutorizado: number;
  repasseConfirmado: number;
  estadoRepasse: string;
}> {
  const [declSnap, alocSnap, repSnap] = await Promise.all([
    db
      .collection(COL_RECEBIMENTOS)
      .where("id_orcamento_declarado", "==", idOrcamento)
      .limit(50)
      .get()
,
    db
      .collection(COL_ALOCACOES)
      .where("id_orcamento", "==", idOrcamento)
      .limit(50)
      .get()
,
    db
      .collection(COL_REPASSES)
      .where("id_orcamento", "==", idOrcamento)
      .limit(50)
      .get()
,
  ]);

  let declarado = 0;
  if (declSnap) {
    for (const d of declSnap.docs) {
      const x = d.data();
      if (String(x.nivel_confirmacao ?? "") === "declaracao") {
        declarado += Number(x.valor_centavos ?? 0);
      }
    }
  }
  // Também declarações no próprio orçamento.
  const orc = await db.collection("orcamento").doc(idOrcamento).get();
  const od = orc.data() ?? {};
  declarado += Number(od.pagamento_declarado_centavos ?? 0);

  let alocado = 0;
  if (alocSnap) {
    for (const d of alocSnap.docs) {
      alocado += Number(d.data().valor_centavos ?? 0);
    }
  }

  let repasseAutorizado = 0;
  let repasseConfirmado = 0;
  let estadoRepasse = "sem_repasse";
  if (repSnap) {
    for (const d of repSnap.docs) {
      const x = d.data();
      const st = String(x.estado ?? "");
      const v = Number(x.valor_centavos ?? 0);
      if (st === "confirmado") {
        repasseConfirmado += v;
        estadoRepasse = "confirmado";
      } else if (st === "autorizado" || st === "em_processamento") {
        repasseAutorizado += v;
        if (estadoRepasse === "sem_repasse") estadoRepasse = st;
      } else if (st === "elegivel_pendente" && estadoRepasse === "sem_repasse") {
        estadoRepasse = "elegivel_pendente";
      }
    }
  }

  return { declarado, alocado, repasseAutorizado, repasseConfirmado, estadoRepasse };
}

function nomeUsuario(u: Record<string, unknown> | null): string | null {
  if (!u) return null;
  return (
    texto(u.nome) ||
    texto(u.nome_completo) ||
    texto(u.display_name) ||
    null
  );
}

function nomeForn(f: Record<string, unknown> | null): string | null {
  if (!f) return null;
  return (
    texto(f.nome_fornecedor) ||
    texto(f.nomeFantasia) ||
    texto(f.nome_fantasia) ||
    texto(f.nome) ||
    null
  );
}

export async function listarAcompanhamentoOrganizador(
  db: Firestore,
  params: { idEvento: string; uid: string },
): Promise<{
  linhas: VisaoContratoOrganizador[];
  completo: boolean;
  aviso: string | null;
}> {
  const ev = await db.collection("evento").doc(params.idEvento).get();
  if (!ev.exists) throw new HttpsError("not-found", "Evento não encontrado.");
  const dono = texto(ev.data()?.id_usuario);
  if (dono !== params.uid) {
    // solicitante de algum orçamento também pode ver só os seus — filtrado abaixo
  }

  const orcSnap = await db
    .collection("orcamento")
    .where("id_evento", "==", params.idEvento)
    .limit(100)
    .get();

  const nomeEvento =
    texto(ev.data()?.nome_evento) ||
    texto(ev.data()?.nome) ||
    null;

  const linhas: VisaoContratoOrganizador[] = [];
  for (const doc of orcSnap.docs) {
    const d = doc.data();
    const solicitante = texto(d.id_solicitante);
    if (dono !== params.uid && solicitante !== params.uid) continue;

    const status = texto(d.status).toLowerCase();
    const contratado =
      d.orcamento_fechado === true ||
      status === "fechado" ||
      status === "contratado";
    if (!contratado) continue;

    const idForn = texto(d.id_fornecedor);
    const forn = idForn
      ? (await db.collection("fornecedor").doc(idForn).get()).data() ?? null
      : null;
    const agg = await agregadosContrato(db, doc.id);
    const exec = parseEstadoExecucao(
      d.contrato_financeiro && typeof d.contrato_financeiro === "object"
        ? (d.contrato_financeiro as { estado_execucao?: string }).estado_execucao
        : d.estado_execucao,
    ) as EstadoExecucaoParte;

    linhas.push(
      montarVisaoOrganizador({
        idContrato: texto((d.contrato_financeiro as { id_contrato?: string })?.id_contrato) || doc.id,
        idOrcamento: doc.id,
        idEvento: params.idEvento,
        nomeEvento,
        nomeFornecedor: nomeForn(forn as Record<string, unknown> | null),
        nomeServico:
          texto(d.nome_servico) ||
          texto(d.nome) ||
          null,
        escopo: texto(d.anotacoes) || null,
        valorContratadoCentavos:
          Number(d.valor_contratado_centavos ?? 0) ||
          Math.round(Number(d.valor_contratado ?? d.valor ?? 0) * 100),
        declaradoCentavos: agg.declarado,
        confirmadoAlocadoCentavos: agg.alocado,
        estadoRepasse: agg.estadoRepasse as "sem_repasse",
        estadoExecucao: exec,
        parcelasConhecidas: true,
        politicaLiberacaoAtiva: false,
      }),
    );
  }

  return {
    linhas,
    completo: orcSnap.size < 100,
    aviso:
      orcSnap.size >= 100
        ? "Lista limitada; não é inventário total."
        : null,
  };
}

export async function listarAcompanhamentoFornecedor(
  db: Firestore,
  params: { idFornecedor: string },
): Promise<{
  linhas: VisaoContratoFornecedor[];
  completo: boolean;
  aviso: string | null;
}> {
  const visoes = await visoesFinanceirasFornecedor(db, params.idFornecedor);
  const privado=await db.runTransaction(async tx=>Promise.all([
    tx.get(db.collection('fornecedor').doc(params.idFornecedor).collection('contas_receber')),
    tx.get(db.collection('fornecedor').doc(params.idFornecedor).collection('movimentos_caixa')),
  ]),{readOnly:true});
  const aliases=new Map<string,string>();
  for(const v of visoes) {aliases.set(v.idContrato,v.idContrato);for(const a of v.aliases) aliases.set(a,v.idContrato);}
  const caixa=projetarCaixaRecebimentos(privado[0].docs.map(d=>({id:d.id,data:d.data()})),privado[1].docs.map(d=>({id:d.id,data:d.data()})),aliases);
  const politica = await db.collection("plataforma_liberacao_repasses").where("ativa", "==", true).limit(1).get();
  const linhas: VisaoContratoFornecedor[] = [];
  for (const v of visoes) {
    if (!v.ativo) continue;
    if (!v.divisao) throw new HttpsError("failed-precondition", "Comissão contratada ausente ou inconsistente; valores líquidos indisponíveis.");
    const d = v.documento;
    const doc = {id:v.idOrcamento};
    const idEvento = texto(d.id_evento);
    const ev = idEvento
      ? (await db.collection("evento").doc(idEvento).get()).data()
      : null;
    const idSol = texto(d.id_solicitante) || texto(ev?.id_usuario);
    const user = idSol
      ? (await db.collection("usuarios").doc(idSol).get()).data()
      : null;

    const agg = await agregadosContrato(db, doc.id);
    const exec = parseEstadoExecucao(
      d.contrato_financeiro && typeof d.contrato_financeiro === "object"
        ? (d.contrato_financeiro as { estado_execucao?: string }).estado_execucao
        : d.estado_execucao,
    ) as EstadoExecucaoParte;

    const valor = v.brutoCentavos;

    linhas.push({
      ...montarVisaoFornecedor({
        idContrato: v.idContrato,
        idOrcamento: doc.id,
        idEvento,
        nomeEvento:
          texto(ev?.nome_evento) || texto(ev?.nome) || null,
        dataEvento: parseData(ev?.data) || parseData(d.data_evento),
        nomeContratante: nomeUsuario(user as Record<string, unknown> | null),
        nomeServico: texto(d.nome_servico) || texto(d.nome) || null,
        escopo: texto(d.anotacoes) || null,
        valorContratadoCentavos: valor,
        percentualBps: v.divisao.percentualBps,
        modoComissao: v.divisao.pagadorComissao === "fornecedor" ? "descontada_fornecedor" : v.divisao.pagadorComissao === "organizador" ? "adicionada_cliente" : "absorvida_plataforma",
        alocadoPlataformaCentavos: agg.alocado,
        repasseAutorizadoCentavos: v.repasseAutorizadoCentavos,
        repasseConfirmadoCentavos: v.repasseConfirmadoCentavos,
        politicaLiberacaoAtiva: !politica.empty,
        estadoExecucao: exec,
        divisaoAplicada: {comissaoPrevistaCentavos:v.comissaoCentavos!, direitoFornecedorPrevistoCentavos:v.liquidoCentavos!},
        revisao:v.revisao,
        comissaoDescontadaNoRepasse:v.divisao.pagadorComissao === "fornecedor" && v.liquidoCentavos! < v.brutoCentavos,
      }),
      recebimentoProprioCentavos:caixa.porContrato.get(v.idContrato) || 0,
      saldoContratoCentavos:v.liquidoCentavos! - v.repasseConfirmadoCentavos - (caixa.porContrato.get(v.idContrato) || 0),
    });
  }

  return {
    linhas,
    completo: true,
    aviso: "Repasse confirmado é registro operacional manual, não confirmação bancária automática.",
  };
}

export async function declararPagamentoCliente(
  db: Firestore,
  entrada: {
    idOrcamento: string;
    idEvento: string;
    valorCentavos: number;
    chaveIdempotencia: string;
    autorId: string;
    referenciaComprovante?: string | null;
  },
): Promise<{
  ok: true;
  nivel: NivelPagamentoPlataforma;
  confirmado: false;
  idempotente: boolean;
}> {
  const chave = texto(entrada.chaveIdempotencia);
  if (!chave) {
    throw new HttpsError("invalid-argument", "Informe chave de idempotência.");
  }
  if (!Number.isInteger(entrada.valorCentavos) || entrada.valorCentavos <= 0) {
    throw new HttpsError("invalid-argument", "Valor inválido.");
  }

  const col = db.collection("plataforma_pagamentos_declarados");
  const existentes = await col.where("chave_idempotencia", "==", chave).limit(1).get();
  if (!existentes.empty) {
    return {
      ok: true,
      nivel: "declarado",
      confirmado: false,
      idempotente: true,
    };
  }

  const orcRef = db.collection("orcamento").doc(entrada.idOrcamento);
  const orc = await orcRef.get();
  if (!orc.exists) throw new HttpsError("not-found", "Contrato não encontrado.");

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orcRef);
    const atual = Number(snap.data()?.pagamento_declarado_centavos ?? 0);
    tx.set(col.doc(), {
      schema: 1,
      id_evento: entrada.idEvento,
      id_orcamento: entrada.idOrcamento,
      valor_centavos: entrada.valorCentavos,
      nivel_confirmacao: "declaracao",
      referencia_comprovante: entrada.referenciaComprovante ?? null,
      chave_idempotencia: chave,
      autor_id: entrada.autorId,
      confirmado: false,
      criado_em: FieldValue.serverTimestamp(),
    });
    tx.update(orcRef, {
      pagamento_declarado_centavos: atual + entrada.valorCentavos,
      pagamento_declarado_em: FieldValue.serverTimestamp(),
    });
  });

  return {
    ok: true,
    nivel: "declarado",
    confirmado: false,
    idempotente: false,
  };
}

export async function atualizarExecucaoContrato(db: Firestore, entrada: {
 idOrcamento:string; acao:"agendar"|"iniciar"|"informar_entrega"|"aceitar"|"contestar"|"decisao_operador";
 autorId:string; papel:"fornecedor"|"cliente"|"admin"; motivo?:string; novoEstadoOperador?:EstadoExecucaoParte;
 chaveIdempotencia:string; versaoEsperada?:number; dataAgendada?:string;
}):Promise<{estado:EstadoExecucaoParte;idempotente:boolean}> {
 const chave=texto(entrada.chaveIdempotencia);
 if(!chave||chave.length>200||chave.includes("/"))throw new HttpsError("invalid-argument","Chave obrigatória.");
 const assinatura=createHash("sha256").update(JSON.stringify([entrada.acao,entrada.autorId,entrada.papel,entrada.motivo||null,entrada.novoEstadoOperador||null,entrada.versaoEsperada??null,entrada.dataAgendada||null])).digest("hex");
 const ref=db.doc(`orcamento/${entrada.idOrcamento}`),histCol=ref.collection("execucao_historico"),hist=histCol.doc(createHash("sha256").update(JSON.stringify([entrada.autorId,chave])).digest("hex"));
 return transacaoIdempotente(db,async tx=>{
   const previa=await tx.get(hist);
   if(previa.exists){if(previa.data()?.assinatura!==assinatura)throw new HttpsError("already-exists","Chave reutilizada com outra ação.");return {estado:previa.data()!.estado_novo as EstadoExecucaoParte,idempotente:true};}
   const snap=await tx.get(ref);if(!snap.exists)throw new HttpsError("not-found","Contrato não encontrado.");
   const d=snap.data()!,cf={...(d.contrato_financeiro||{})};
   const ev=await tx.get(db.doc(`evento/${d.id_evento}`));
   const perfil=await tx.get(db.doc(`usuarios/${entrada.autorId}`));
   if(!perfil.exists||perfil.data()?.ativo===false)throw new HttpsError("permission-denied","Perfil indisponível.");
   const eFornecedor=d.id_fornecedor===entrada.autorId,eCliente=[d.id_solicitante,ev.data()?.id_usuario].includes(entrada.autorId);
   const fornecedorAcao=["agendar","iniciar","informar_entrega"].includes(entrada.acao),clienteAcao=["aceitar","contestar"].includes(entrada.acao);
   if((fornecedorAcao&&(!eFornecedor||entrada.papel!=="fornecedor"))||(clienteAcao&&(!eCliente||eFornecedor||entrada.papel!=="cliente"))||
      (entrada.acao==="decisao_operador"&&(entrada.papel!=="admin"||perfil.data()?.tipo!=="A")))throw new HttpsError("permission-denied","Autoria incompatível com a transição.");
   if(!contratado(d)||["cancelado","cancelada"].includes(ev.data()?.status))throw new HttpsError("failed-precondition","Contratação não está ativa.");
   const antigos=await tx.get(histCol.where("chave_idempotencia","==",chave));
   if(!antigos.empty){const h=antigos.docs[0].data();if(h.acao!==entrada.acao||h.autor_id!==entrada.autorId||h.papel!==entrada.papel)throw new HttpsError("already-exists","Chave legada pertence a outra manifestação.");return {estado:h.estado_novo as EstadoExecucaoParte,idempotente:true};}
   if(entrada.versaoEsperada!=null&&entrada.versaoEsperada!==(d.execucao_revisao||0))throw new HttpsError("aborted","Execução mudou. Recarregue antes de agir.");
   if(entrada.acao==="agendar"&&(!entrada.dataAgendada||!Number.isFinite(Date.parse(entrada.dataAgendada))||Date.parse(entrada.dataAgendada)<=Date.now()))throw new HttpsError("invalid-argument","Informe data de agendamento futura.");
   const atual=parseEstadoExecucao(cf.estado_execucao||d.estado_execucao) as EstadoExecucaoParte;
   let novo:EstadoExecucaoParte;try{novo=transicionarExecucao({atual,acao:entrada.acao,novoEstadoOperador:entrada.novoEstadoOperador}).novo;}catch(e){throw new HttpsError("failed-precondition",e instanceof Error?e.message:"Transição inválida.");}
   if(entrada.acao==="iniciar")await validarInicioAgenda(db,tx,d,snap.id);
   let participacao:FirebaseFirestore.DocumentReference|null=null;
   if(d.id_cotacao){const pr=db.doc(`cotacao/${d.id_cotacao}/fornecedores/${d.id_fornecedor}`),ps=await tx.get(pr);if(ps.exists&&(ps.data()?.id_orcamento===snap.id||ps.data()?.status==="fechado"))participacao=pr;}
   const liberarAgenda=novo==="cancelado_execucao"?await prepararLiberacaoAgenda(db,tx,d,snap.id,entrada.autorId):()=>{};liberarAgenda();
   tx.update(ref,{contrato_financeiro:{...cf,estado_execucao:novo},estado_execucao:novo,execucao_revisao:(d.execucao_revisao||0)+1,...(entrada.acao==="agendar"?{agendamento_operacional:entrada.dataAgendada}: {})});
   tx.create(hist,{schema:2,acao:entrada.acao,estado_anterior:atual,estado_novo:novo,autor_id:entrada.autorId,papel:entrada.papel,motivo:texto(entrada.motivo)||null,chave_idempotencia:chave,assinatura,data_agendada:entrada.dataAgendada||null,criado_em:FieldValue.serverTimestamp()});
   if(participacao)tx.update(participacao,{id_orcamento:snap.id,estado_execucao:novo,jornada_revisao:FieldValue.increment(1)});
   return {estado:novo,idempotente:false};
 });
}
