import {createHash} from "crypto";
import {Firestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
type M=Record<string,any>;
const mapa=(v:any):M=>v&&typeof v==="object"&&!Array.isArray(v)?v:{};
const falha=(s:string):never=>{throw new HttpsError("failed-precondition",s);};
const id=(s:any)=>typeof s==="string"&&s.length>0&&s.length<=200&&!s.includes("/");
const canon=(v:any):string=>Array.isArray(v)?`[${v.map(canon).join(",")}]`:v&&typeof v==="object"?`{${Object.keys(v).sort().map(k=>`${JSON.stringify(k)}:${canon(v[k])}`).join(",")}}`:JSON.stringify(v??null);
const numero=(v:any)=>{if(!Number.isInteger(v)||v<0||v>1000000)falha("Informe pessoas inteiras entre zero e um milhão.");return v;};
const campos=["id","id_evento","id_modelo","id_cardapio","titulo","data_local","hora_local","fuso","duracao_minutos","formato"];
export function validarOcorrencia(o:M,inicio?:string,fim?:string):void {
 if(!o||typeof o!=="object"||Array.isArray(o)||Object.keys(o).some(k=>!campos.includes(k))||![o.id,o.id_evento,o.id_modelo,o.id_cardapio].every(id)||o.id!==o.id_cardapio||o.id_modelo===o.id_cardapio)falha("Confira o vínculo da ocorrência.");
 if(typeof o.titulo!=="string"||!o.titulo.trim()||o.titulo.length>120||!["nao_definido","buffet","empratado","volante","autosservico"].includes(o.formato))falha("Confira nome e formato do serviço.");
 if(o.data_local!=null&&(!/^\d{4}-\d{2}-\d{2}$/.test(o.data_local)||!Number.isFinite(Date.parse(o.data_local))||new Date(o.data_local).toISOString().slice(0,10)!==o.data_local))falha("Data inválida.");
 if(o.hora_local!=null&&!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(o.hora_local))falha("Horário inválido.");
 if(o.duracao_minutos!=null&&(!Number.isInteger(o.duracao_minutos)||o.duracao_minutos<1||o.duracao_minutos>1440))falha("Confira a duração do serviço.");
 if(o.fuso!=null) {try {if(typeof o.fuso!=="string"||!o.fuso)throw Error();new Intl.DateTimeFormat("pt-BR",{timeZone:o.fuso});}catch(_){falha("Fuso IANA inválido.");}}
 if(o.data_local!=null) {
  if(inicio&&o.data_local<inicio||fim&&o.data_local>fim)falha("A data do serviço deve estar dentro do período do evento.");
  if(o.hora_local!=null&&o.duracao_minutos!=null&&fim) {
   const termino=Date.parse(`${o.data_local}T${o.hora_local}:00Z`)+o.duracao_minutos*60000;
   if(termino>Date.parse(`${fim}T00:00:00Z`)+86400000)falha("O intervalo termina fora do período do evento.");
  }
  if(o.hora_local&&o.fuso) {
   const formatter=new Intl.DateTimeFormat("sv-SE",{timeZone:o.fuso,year:"numeric",month:"2-digit",day:"2-digit",hour:"2-digit",minute:"2-digit",hourCycle:"h23"});
   const alvo=`${o.data_local} ${o.hora_local}`,civil=Date.parse(`${o.data_local}T${o.hora_local}:00Z`);
   let instante=civil;
   for(let i=0;i<3;i++) {const local=formatter.format(new Date(instante)).replace(",","");const diferenca=Date.parse(local.replace(" ","T")+":00Z")-civil;instante-=diferenca;}
   if(formatter.format(new Date(instante)).replace(",","")!==alvo)falha("Esse horário não existe no fuso declarado.");
  }
 }
}
export function validarAgenda(agenda:any,evento?:string):void {
 if(agenda==null)return;
 if(!Array.isArray(agenda)||agenda.length>20)falha("Use até 20 ocorrências por evento.");
 const ids=new Set<string>();for(const o of agenda){validarOcorrencia(o);if(ids.has(o.id)||evento&&o.id_evento!==evento)falha("Ocorrência repetida ou de outro evento.");ids.add(o.id);}
}
export function itensDoModelo(itens:M[]):M[] {return itens.map(i=>({id_item:i.id_item,nome:i.nome,tipo:i.tipo??"outro",publico_alvo:i.publico_alvo??"todos",unidade:i.unidade??"un"})).sort((a,b)=>a.id_item.localeCompare(b.id_item));}
function validarConfig(cfg:M):void {
 for(const k of ["publico","publico_extra"])if(cfg[k]!=null){if(typeof cfg[k]!=="object"||Array.isArray(cfg[k])||Object.keys(cfg[k]).some(a=>!["adultos","criancas","bebes"].includes(a)))falha("Público inválido.");for(const a of ["adultos","criancas","bebes"])numero(cfg[k][a]);}
 if(cfg.servico!=null&&!["refeicao","lanche"].includes(cfg.servico))falha("Escolha refeição ou intervalo/lanche.");
}
const dia=(t:any):string|undefined=>t instanceof Timestamp?t.toDate().toISOString().slice(0,10):typeof t==="string"?t.slice(0,10):undefined;
export async function confirmarAgendaServico(db:Firestore,uid:string|undefined,raw:any):Promise<M> {
 if(!uid)throw new HttpsError("unauthenticated","Entre na conta do organizador.");
 const evento=raw?.evento,acao=mapa(raw?.acao),o=mapa(acao.ocorrencia),pedido=acao.pedido;
 if(!id(evento)||!id(pedido)||acao.tipo!=="agenda"||!Number.isInteger(acao.revisao)||acao.revisao<0||Buffer.byteLength(JSON.stringify(raw))>160000)falha("Confirmação de agenda inválida.");
 validarOcorrencia(o);if(o.id_evento!==evento)falha("A ocorrência pertence a outro evento.");
 const entrada=mapa(acao.config);if(Object.keys(entrada).some(k=>!["publico","publico_extra","servico"].includes(k)))falha("Edite os grupos na configuração desta ocorrência.");validarConfig(entrada);
 const assinatura=createHash("sha256").update(canon(acao)).digest("hex");
 return db.runTransaction(async tx=>{
  const ev=await tx.get(db.doc(`evento/${evento}`));if(ev.data()?.id_usuario!==uid)throw new HttpsError("permission-denied","Somente o organizador pode confirmar a agenda.");
  const ref=db.doc(`calculadora_operacao/${evento}`),recibo=ref.collection("agenda_confirmacoes").doc(pedido);
  const opDoc=await tx.get(ref),recebido=await tx.get(recibo),op=opDoc.data()??{};
  if(op.versao!=null&&op.versao!==1)falha("Atualize o leitor antes de alterar esta operação.");
  if(recebido.exists){if(recebido.data()?.assinatura!==assinatura)falha("A identidade desta confirmação já foi usada com outros dados.");return op;}
  if((op.revisao??0)!==acao.revisao)falha("O planejamento mudou em outro acesso. Revise a agenda antes de confirmar.");
  validarAgenda(op.agenda,evento);
  const agenda:M[]=[...(op.agenda??[])],anterior=agenda.find(a=>a.id===o.id);
  if(anterior&&(anterior.id_modelo!==o.id_modelo||anterior.id_cardapio!==o.id_cardapio))falha("O vínculo de uma ocorrência é estável.");
  validarOcorrencia(o,dia(ev.data()?.data),dia(ev.data()?.data_fim)??dia(ev.data()?.data));
  const modeloRef=db.doc(`cardapios/${o.id_modelo}`),destinoRef=db.doc(`cardapios/${o.id_cardapio}`);
  const modelo=await tx.get(modeloRef),destino=await tx.get(destinoRef);
  if(!anterior&&(modelo.data()?.id_evento!==evento||modelo.data()?.ativo===false||modelo.data()?.id_modelo))falha("Selecione um modelo deste evento.");
  if(anterior&&(!destino.exists||destino.data()?.id_evento!==evento||destino.data()?.id_modelo!==o.id_modelo)||!anterior&&destino.exists)falha("A ocorrência mudou. Atualize a agenda.");
  if(!anterior){const menus=await tx.get(db.collection("cardapios").where("id_evento","==",evento).limit(21));if(menus.size>=20)falha("O evento atingiu o limite de 20 cardápios, incluindo modelos. Organize o conjunto antes de criar outra ocorrência.");}
  let fontes:M[]=[];
  if(!anterior){const itens=await tx.get(modeloRef.collection("itens").limit(61));if(itens.size>60)falha("Use até 60 itens no modelo.");fontes=itens.docs.map(d=>({...d.data(),id_item:d.id}));}
  if(!anterior&&canon(itensDoModelo(fontes))!==canon(acao.fonte_itens))falha("Os itens do modelo mudaram. Atualize a proposta da ocorrência.");
  if(!anterior&&acao.somente_modelo!==true&&acao.somente_modelo!==false)falha("Confira se o original será modelo ou serviço sem agenda.");
  const refeicoes={...mapa(op.refeicoes)},cfg={...mapa(refeicoes[o.id_cardapio]),...entrada};validarConfig(cfg);
  let herdado=mapa(op.configuracao_planejamento).base==="manual"?mapa(mapa(op.configuracao_planejamento).publico):{adultos:ev.data()?.total_adultos??0,criancas:ev.data()?.total_criancas??0,bebes:ev.data()?.total_bebes??0};
  const base=mapa(op.configuracao_planejamento).base;
  if(cfg.publico==null&&["todos","confirmados","nao_recusados"].includes(base)) {
   const convidados=await tx.get(db.collection("convidado").where("id_evento","==",evento).limit(121));if(convidados.size>120)falha("Há muitos convidados para esta conferência.");
   herdado={adultos:0,criancas:0,bebes:0};for(const d of convidados.docs){const c=d.data();if(base==="confirmados"&&c.status!=="confirmado"||base==="nao_recusados"&&c.status==="recusado")continue;const k=c.tipo_convidado==="crianca"?"criancas":c.tipo_convidado==="bebe"?"bebes":"adultos";herdado[k]++;}
  }
  for(const k of ["adultos","criancas","bebes"]) {
   const total=numero((cfg.publico??herdado)[k])+numero(mapa(cfg.publico_extra)[k]??0);
   if(total>1000000||(cfg.grupos??[]).reduce((s:number,g:M)=>s+numero(g[k]),0)>total)falha("Os grupos excedem o público desta ocorrência.");
  }
  const nova=agenda.filter(a=>a.id!==o.id);nova.push(o);validarAgenda(nova,evento);
  const exec={...mapa(op.execucao)},regras=[...(exec.regras??[])];
  if(!anterior) {
   if(acao.somente_modelo&& (fontes.some(i=>i.confirmado===true||(i.quantidade_final??0)>0||(i.disponibilidade?.comprado??0)>0||(i.disponibilidade?.estoque??0)>0)||Object.values(mapa(op.lotes)).some((l:any)=>Object.values(mapa(l.reservas)).some((r:any)=>r.refeicao===o.id_modelo))))falha("O original possui quantidades finais, compras ou reservas. Mantenha-o como serviço sem agenda para preservar os fatos.");
   for(const r of exec.regras??[])if(r.premissas?.id_cardapio===o.id_modelo){
    const meta={...r.premissas,id_evento:evento,id_cardapio:o.id_cardapio,id_ocorrencia:o.id,numero_servicos_modelo:r.premissas.numero_servicos??1,numero_servicos:1};delete meta.publico_refeicao;delete meta.destino_publico;
    regras.push({...r,id:`menu_${o.id_cardapio}_${meta.id_item_cardapio}`,premissas:meta});
   }
   if(regras.length>60)falha("O evento excede 60 regras salvas. Reduza o conjunto antes de criar outra ocorrência.");
  }
  refeicoes[o.id_cardapio]=cfg;
  const resultado={...op,id_evento:evento,id_usuario:uid,versao:1,revisao:acao.revisao+1,agenda:nova,refeicoes,execucao:{...exec,regras,contexto_desatualizado:true}};
  if(!anterior){
   const m=modelo.data()!;tx.create(destinoRef,{id_cardapio:o.id_cardapio,id_evento:evento,id_modelo:o.id_modelo,titulo:o.titulo,escopo:"refeicao",publico_alvo:m.publico_alvo??"todos",ativo:true,total_itens:fontes.length,total_comidas:fontes.filter(i=>i.tipo==="comida").length,total_bebidas:fontes.filter(i=>i.tipo==="bebida").length,total_sobremesas:fontes.filter(i=>["sobremesa","bolo"].includes(i.tipo)).length});
   for(const i of fontes)tx.create(destinoRef.collection("itens").doc(i.id_item),{...itensDoModelo([i])[0],id_evento:evento,id_cardapio:o.id_cardapio,quantidade_sugerida:0,quantidade_final:0,confirmado:false,gerado_pela_calculadora:false});
   if(acao.somente_modelo)tx.update(modeloRef,{somente_modelo:true});
  }else tx.update(destinoRef,{titulo:o.titulo});
  tx.set(ref,resultado);tx.create(recibo,{assinatura,id_evento:evento,id_usuario:uid,aplicado_em:Timestamp.now()});return resultado;
 });
}
