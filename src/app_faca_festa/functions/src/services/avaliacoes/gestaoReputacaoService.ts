import { transacaoIdempotente } from "../../shared/transacaoIdempotente";
import { createHash } from "crypto";
import { FieldPath, FieldValue, Firestore, Transaction } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { aplicarModeracaoAvaliacao, registrosConfiaveis } from "./avaliacaoVerificadaService";

const hash=(v:unknown)=>createHash("sha256").update(JSON.stringify(v)).digest("hex");
function identificador(v:unknown):string {
  if(typeof v!=="string" || !v.trim() || v.length>200 || v.includes("/")) throw new HttpsError("invalid-argument","Identificador inválido.");
  return v.trim();
}
function texto(v:unknown,min:number,max:number):string {
  if(typeof v!=="string" || v.length>max || v.trim().length<min) throw new HttpsError("invalid-argument",`Texto deve ter entre ${min} e ${max} caracteres.`);
  return v.trim();
}
function campos(d:any, permitidos:string[]) {
  if(!d || typeof d!=="object" || Array.isArray(d) || Object.keys(d).some(k=>!permitidos.includes(k))) throw new HttpsError("invalid-argument","Campos não permitidos.");
}
const instante=(v:any):string|null=>v?.toDate ? v.toDate().toISOString() : null;
const versao=(v:unknown)=>{if(!Number.isSafeInteger(v)||Number(v)<0)throw new HttpsError("invalid-argument","Versão inválida.");return Number(v);};
function filtros(d:any) {
  const nota=d.nota==null?null:Number(d.nota);
  if(nota!==null&&(!Number.isInteger(nota)||nota<1||nota>5))throw new HttpsError("invalid-argument","Filtro de nota inválido.");
  const periodo=(v:any)=>{
    if(v==null)return null;
    if(typeof v!=="string"||!/^\d{4}-\d{2}-\d{2}T/.test(v)||!Number.isFinite(Date.parse(v)))throw new HttpsError("invalid-argument","Período inválido.");
    return new Date(v).toISOString();
  };
  const de=periodo(d.de),ate=periodo(d.ate),resposta=d.resposta||"todas",tipo=d.tipo||"fornecedor";
  if((de&&ate&&de>ate)||!["todas","respondida","pendente"].includes(resposta)||!["fornecedor","servico","todos"].includes(tipo))throw new HttpsError("invalid-argument","Filtros inválidos.");
  return {nota,de,ate,resposta,tipo};
}
function corresponde(d:any,r:any,f:ReturnType<typeof filtros>) {
  const data=instante(d.data);
  return (f.nota===null||d.nota===f.nota)&&(!f.de||(data!==null&&data>=f.de))&&(!f.ate||(data!==null&&data<f.ate))&&
    (f.tipo==="todos"||d.tipo===f.tipo||(f.tipo==="fornecedor"&&!d.tipo))&&
    (f.resposta==="todas"||(f.resposta==="respondida")===!!r);
}
async function resposta(tx:Transaction,ref:FirebaseFirestore.DocumentReference) {
  const s=await tx.get(ref.collection("respostas_publicas").doc("atual"));return s.exists?s.data()!:null;
}
async function andamento(tx:Transaction,ref:FirebaseFirestore.DocumentReference) {
  const s=await tx.get(ref.collection("denuncia_compartilhada").doc("atual"));return s.exists?s.data()!:null;
}
export async function consultarGestaoReputacao(db:Firestore,uid:string,d:any) {
  campos(d,["idFornecedor","nota","de","ate","resposta","tipo","cursor","limite","idAvaliacao"]);
  const fornecedor=identificador(d.idFornecedor);if(uid!==fornecedor)throw new HttpsError("permission-denied","Somente o fornecedor acessa sua gestão.");
  const f=filtros(d),limite=d.limite==null?10:Number(d.limite);
  if(!Number.isInteger(limite)||limite<1||limite>30)throw new HttpsError("invalid-argument","Limite de 1 a 30.");
  const foco=d.idAvaliacao?identificador(d.idAvaliacao):null;
  const contexto=hash([uid,fornecedor,f,foco]);let ultimo:string|undefined;
  if(d.cursor!=null){
    try{const c=JSON.parse(Buffer.from(d.cursor,"base64url").toString());if(c.contexto!==contexto)throw Error();ultimo=identificador(c.ultimo);}catch{throw new HttpsError("invalid-argument","Cursor não corresponde aos filtros/sessão.");}
  }
  return db.runTransaction(async tx=>{
    // Keyset por ID: não perde registros com data legada ausente. A data é filtrada explicitamente.
    let q=db.collection(`fornecedor/${fornecedor}/avaliacoes`).orderBy(FieldPath.documentId()).limit(limite);
    if(foco)q=q.where(FieldPath.documentId(),"==",foco);
    if(ultimo)q=q.startAfter(ultimo);
    const pagina=await tx.get(q),confiaveis=await registrosConfiaveis(tx,pagina.docs);
    const itens=[];
    for(const doc of pagina.docs){
      const a=doc.data(),r=await resposta(tx,doc.ref),denuncia=await andamento(tx,doc.ref);
      if(!corresponde(a,r,f))continue;
      const verificada=confiaveis.some(x=>x.id===doc.id);
      let servico=verificada?"Fornecedor":"Serviço não comprovado",idServico=verificada?a.id_servico:null;
      if(verificada&&!idServico&&a.id_orcamento){
        const orc=await tx.get(db.doc(`orcamento/${identificador(a.id_orcamento)}`));
        if(orc.data()?.id_fornecedor===fornecedor&&(orc.data()?.contrato_financeiro?.id_contrato||orc.id)===a.id_contrato){
          idServico=orc.data()?.id_produto_servico||orc.data()?.id_servico;
          servico=String(orc.data()?.nome_servico||"Serviço contratado");
        }
      }
      if(idServico){const catalogo=await tx.get(db.doc(`servico_produto/${identificador(idServico)}`));servico=String(catalogo.data()?.nome||"Serviço contratado");}
      itens.push({id:doc.id,nota:Number.isFinite(a.nota)?a.nota:null,comentario:String(a.comentario||""),data:instante(a.data),
        verificada,tipo:a.tipo||"legado",servico,
        // Nunca inclui ID/nome do evento, nome completo do cliente, telefone ou custo privado.
        contexto:verificada?`Contratação verificada · referência ${hash(a.id_contrato).slice(0,8)}`:"Histórico sem comprovação de entrega",
        cliente:"Cliente",situacao:a.moderacao||"publicada",
        resposta:r?{texto:r.texto,autorId:r.autor_id,versao:r.versao,data:instante(r.atualizado_em)}:null,
        denuncia:denuncia?{situacao:denuncia.situacao,decisao:denuncia.decisao||null,fundamentacao:denuncia.fundamentacao_compartilhada||null,data:instante(denuncia.atualizado_em)}:null});
    }
    const all=await tx.get(db.collection(`fornecedor/${fornecedor}/avaliacoes`));
    const validos=await registrosConfiaveis(tx,all.docs);const base:Record<string,any>[]=[];
    for(const a of validos){const doc=all.docs.find(x=>x.id===a.id)!;const r=await resposta(tx,doc.ref);if(a.moderacao!=="oculta"&&corresponde(a,r,f))base.push(a);}
    const distribuicao=[1,2,3,4,5].map(n=>({nota:n,quantidade:base.filter(a=>a.nota===n).length}));
    const meses=new Map<string,{periodo:string;quantidade:number;soma:number}>();
    for(const a of base){const mes=instante(a.data)?.slice(0,7);if(!mes)continue;const m=meses.get(mes)||{periodo:mes,quantidade:0,soma:0};m.quantidade++;m.soma+=a.nota;meses.set(mes,m);}
    const cursor=!foco&&pagina.size===limite?Buffer.from(JSON.stringify({contexto,ultimo:pagina.docs[pagina.size-1].id})).toString("base64url"):null;
    return {itens,cursor,resumo:{quantidade:base.length,media:base.length?base.reduce((s,a)=>s+a.nota,0)/base.length:null,distribuicao,
      periodos:[...meses.values()].sort((a,b)=>a.periodo.localeCompare(b.periodo)).map(m=>({periodo:m.periodo,quantidade:m.quantidade,media:m.soma/m.quantidade})),
      base:"Avaliações verificadas publicadas, do objeto e filtros selecionados. Meses em UTC. Sem dados não significa ausência de problemas."}};
  },{readOnly:true});
}
function opRef(db:Firestore,uid:string,chave:string){return db.doc(`reputacao_operacoes/${uid}/operacoes/${hash(chave)}`);}
async function anterior(tx:Transaction,ref:FirebaseFirestore.DocumentReference,assinatura:string){
  const s=await tx.get(ref);if(!s.exists)return null;
  if(s.data()?.assinatura!==assinatura)throw new HttpsError("already-exists","Chave reutilizada com conteúdo diferente.");
  return {...s.data()!.resultado,idempotente:true};
}
export async function responderReputacao(db:Firestore,uid:string,d:any){
  campos(d,["idFornecedor","idAvaliacao","texto","versaoEsperada","chave"]);
  const fornecedor=identificador(d.idFornecedor),avaliacao=identificador(d.idAvaliacao),chave=identificador(d.chave),conteudo=texto(d.texto,3,1000),esperada=versao(d.versaoEsperada);
  if(uid!==fornecedor)throw new HttpsError("permission-denied","Outro fornecedor não responde em seu nome.");
  const assinatura=hash(["responder",fornecedor,avaliacao,conteudo,esperada]),op=opRef(db,uid,chave);
  return transacaoIdempotente(db,async tx=>{
    const idem=await anterior(tx,op,assinatura);if(idem)return idem;
    const ref=db.doc(`fornecedor/${fornecedor}/avaliacoes/${avaliacao}`),a=await tx.get(ref),atual=await resposta(tx,ref);
    if(!a.exists||a.data()?.moderacao==="oculta")throw new HttpsError("failed-precondition","Comentário indisponível para resposta.");
    if((atual?.versao||0)!==esperada)throw new HttpsError("aborted","A resposta mudou. Recarregue antes de editar.");
    const agora=FieldValue.serverTimestamp(),versaoNova=esperada+1;
    const registro={texto:conteudo,autor_id:uid,versao:versaoNova,criado_em:atual?.criado_em||agora,atualizado_em:agora};
    tx.set(ref.collection("respostas_publicas").doc("atual"),registro);
    tx.update(ref,{resposta_revisao:versaoNova});
    tx.create(ref.collection("respostas_historico").doc(String(versaoNova)),{...registro,anterior:atual||null,chave});
    const resultado={versao:versaoNova,idempotente:false};
    tx.create(op,{assinatura,resultado,autor_id:uid,acao:"responder",criado_em:agora});return resultado;
  });
}
export const MOTIVOS_DENUNCIA=["ofensa","dados_pessoais","conteudo_falso","fora_do_contexto","outro"];
export async function denunciarReputacao(db:Firestore,uid:string,d:any){
  campos(d,["idFornecedor","idAvaliacao","motivo","descricao","chave"]);
  const fornecedor=identificador(d.idFornecedor),avaliacao=identificador(d.idAvaliacao),chave=identificador(d.chave),descricao=texto(d.descricao,10,1000);
  if(uid!==fornecedor)throw new HttpsError("permission-denied","Somente o fornecedor denuncia neste fluxo.");
  if(!MOTIVOS_DENUNCIA.includes(d.motivo))throw new HttpsError("invalid-argument","Motivo inválido.");
  const assinatura=hash(["denunciar",fornecedor,avaliacao,d.motivo,descricao]),op=opRef(db,uid,chave),caso=db.doc(`denuncias_avaliacoes/${hash([fornecedor,avaliacao])}`);
  return transacaoIdempotente(db,async tx=>{
    const idem=await anterior(tx,op,assinatura);if(idem)return idem;
    const ref=db.doc(`fornecedor/${fornecedor}/avaliacoes/${avaliacao}`),a=await tx.get(ref),existe=await tx.get(caso);
    if(!a.exists)throw new HttpsError("not-found","Avaliação não encontrada.");
    if(existe.exists)throw new HttpsError("already-exists","Já existe uma denúncia rastreável para esta avaliação.");
    const agora=FieldValue.serverTimestamp();
    tx.create(caso,{id_fornecedor:fornecedor,id_avaliacao:avaliacao,autor_id:uid,id_cliente_avaliacao:a.data()?.id_cliente||null,motivo:d.motivo,descricao,situacao:"aberta",versao:1,criado_em:agora,atualizado_em:agora});
    tx.create(caso.collection("historico").doc("1"),{acao:"denunciar",autor_id:uid,motivo:d.motivo,descricao,criado_em:agora});
    tx.set(ref.collection("denuncia_compartilhada").doc("atual"),{situacao:"aberta",atualizado_em:agora});
    const resultado={id:caso.id,idempotente:false};tx.create(op,{assinatura,resultado,autor_id:uid,acao:"denunciar",criado_em:agora});return resultado;
  });
}
export async function listarFilaReputacao(db:Firestore,d:any,uid:string){
  campos(d,["cursor","limite","situacao"]);const limite=d.limite==null?10:Number(d.limite);
  if(!Number.isInteger(limite)||limite<1||limite>30||![undefined,"todas","aberta","em_analise","encerrada"].includes(d.situacao))throw new HttpsError("invalid-argument","Filtro inválido.");
  let q=db.collection("denuncias_avaliacoes").orderBy(FieldPath.documentId()).limit(limite);
  if(d.cursor)q=q.startAfter(identificador(d.cursor));
  const s=await q.get(),itens=[];
  for(const doc of s.docs){const c=doc.data();if(c.id_fornecedor===uid||c.id_cliente_avaliacao===uid)continue;if(d.situacao&&d.situacao!=="todas"&&d.situacao!==c.situacao)continue;
    const a=await db.doc(`fornecedor/${c.id_fornecedor}/avaliacoes/${c.id_avaliacao}`).get();
    const h=await doc.ref.collection("historico").orderBy(FieldPath.documentId()).get();
    itens.push({id:doc.id,...c,criado_em:instante(c.criado_em),atualizado_em:instante(c.atualizado_em),avaliacao:{comentario:a.data()?.comentario||"",nota:a.data()?.nota||null},
      historico:h.docs.map(x=>({...x.data(),criado_em:instante(x.data().criado_em)}))});
  }
  return {itens,cursor:s.size===limite?s.docs[s.size-1].id:null};
}
export async function decidirDenunciaReputacao(db:Firestore,uid:string,d:any){
  campos(d,["idCaso","acao","decisao","fundamentacao","notaInterna","versaoEsperada","chave"]);
  const casoId=identificador(d.idCaso),chave=identificador(d.chave),esperada=versao(d.versaoEsperada);
  if(!["analisar","encerrar"].includes(d.acao)||![undefined,"manter","ocultar","restaurar"].includes(d.decisao))throw new HttpsError("invalid-argument","Ação inválida.");
  const fundamentacao=texto(d.fundamentacao,10,1000),notaInterna=texto(d.notaInterna||"",0,2000);
  if(d.acao==="encerrar"&&!d.decisao)throw new HttpsError("invalid-argument","Informe a decisão.");
  const assinatura=hash(["decidir",casoId,d.acao,d.decisao||null,fundamentacao,notaInterna,esperada]),op=opRef(db,uid,chave);
  return transacaoIdempotente(db,async tx=>{
    const idem=await anterior(tx,op,assinatura);if(idem)return idem;
    const ref=db.doc(`denuncias_avaliacoes/${casoId}`),s=await tx.get(ref),c=s.data();
    if(!c)throw new HttpsError("not-found","Denúncia não encontrada.");
    const a=await tx.get(db.doc(`fornecedor/${c.id_fornecedor}/avaliacoes/${c.id_avaliacao}`));
    if(uid===c.id_fornecedor||uid===a.data()?.id_cliente)throw new HttpsError("permission-denied","Parte interessada não modera o próprio caso.");
    if(c.versao!==esperada)throw new HttpsError("aborted","O caso mudou. Recarregue a fila.");
    if(c.situacao==="encerrada")throw new HttpsError("failed-precondition","Decisão encerrada é preservada.");
    if(d.acao==="encerrar"&&d.decisao!=="manter")await aplicarModeracaoAvaliacao(db,tx,uid,{idFornecedor:c.id_fornecedor,idAvaliacao:c.id_avaliacao,ocultar:d.decisao==="ocultar",motivo:fundamentacao},true);
    const agora=FieldValue.serverTimestamp(),situacao=d.acao==="encerrar"?"encerrada":"em_analise",nova=esperada+1;
    const alteracao={situacao,versao:nova,decisao:d.acao==="encerrar"?d.decisao:null,fundamentacao_compartilhada:fundamentacao,nota_interna:notaInterna,moderador_id:uid,atualizado_em:agora};
    tx.update(ref,alteracao);tx.create(ref.collection("historico").doc(String(nova)),{...alteracao,acao:d.acao,autor_id:uid,criado_em:agora});
    tx.set(db.doc(`fornecedor/${c.id_fornecedor}/avaliacoes/${c.id_avaliacao}/denuncia_compartilhada/atual`),{situacao,decisao:alteracao.decisao,fundamentacao_compartilhada:fundamentacao,atualizado_em:agora});
    const resultado={versao:nova,idempotente:false};tx.create(op,{assinatura,resultado,autor_id:uid,acao:"decidir",criado_em:agora});return resultado;
  });
}
function comando(fn:(db:Firestore,uid:string,d:any)=>Promise<any>,moderador=false){return onCall({region:"southamerica-east1"},async req=>{
  const p=await exigirUsuarioAutenticado(req.auth?.uid);
  if(moderador&&req.auth?.token.moderar_avaliacoes!==true)throw new HttpsError("permission-denied","Permissão específica de moderação necessária.");
  return fn(admin.firestore(),p.uid,req.data);
});}
export const consultarGestaoReputacaoFn=comando(consultarGestaoReputacao);
export const responderReputacaoFn=comando(responderReputacao);
export const denunciarReputacaoFn=comando(denunciarReputacao);
export const listarFilaReputacaoFn=comando((db,uid,d)=>listarFilaReputacao(db,d,uid),true);
export const decidirDenunciaReputacaoFn=comando(decidirDenunciaReputacao,true);
export const consultarPermissaoReputacaoFn=onCall({region:"southamerica-east1"},async req=>{await exigirUsuarioAutenticado(req.auth?.uid);return {moderar:req.auth?.token.moderar_avaliacoes===true};});

export const historicoRespostaReputacaoFn=comando(async (db,uid,d)=>{
  campos(d,["idFornecedor","idAvaliacao"]);const f=identificador(d.idFornecedor),a=identificador(d.idAvaliacao);
  if(uid!==f)throw new HttpsError("permission-denied","Histórico restrito ao fornecedor.");
  const s=await db.collection(`fornecedor/${f}/avaliacoes/${a}/respostas_historico`).get();
  return {itens:s.docs.map(x=>({versao:x.data().versao,texto:x.data().texto,autorId:x.data().autor_id,data:instante(x.data().atualizado_em)})).sort((a,b)=>a.versao-b.versao)};
});
