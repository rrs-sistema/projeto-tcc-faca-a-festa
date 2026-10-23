import {createHash} from "crypto";
import {Firestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
type M = Record<string, any>;
const fail = (s: string): never => {throw new HttpsError("failed-precondition", s);};
const fields = ["schema","motor_minimo","id","versao","tipo","nome","aliases","alimento_receita","servicos","formatos","periodos","publicos","obtencoes","papel","unidade","estado_consumo","estado_compra","contexto","limitacoes","fonte","verificado_em","revisao_editorial","minimo","maximo","padrao","itens","origem_legado","aprovado_por","aprovado_em","hora_inicio","hora_fim","duracao_minima","duracao_maxima","infraestrutura"];
export function validarReferenciaContextual(r: M): void {
  if (!r || typeof r !== "object" || Array.isArray(r) || Object.keys(r).some(k => !fields.includes(k)) || r.schema !== 1 || r.motor_minimo !== 1 || typeof r.id !== "string" || !/^[a-z0-9_\-]{1,120}$/.test(r.id) || !Number.isInteger(r.versao) || r.versao < 1 || r.versao > 1000000 || !["porcao","modelo","rendimento"].includes(r.tipo)) fail("Schema, identidade ou versão incompatível.");
  for (const k of ["nome","alimento_receita","contexto","limitacoes","fonte","revisao_editorial"]) if (typeof r[k] !== "string" || !r[k].trim() || r[k].length > 4000) fail(`Confira ${k}.`);
  try {const url = new URL(r.fonte); if (!["https:","codigo:"].includes(url.protocol) || url.protocol === "codigo:" && !url.pathname) throw Error();} catch (_) {fail("Informe a fonte HTTPS ou a origem no código.");}
  const options: M = {servicos:["refeicao","lanche"],formatos:["buffet","empratado","volante","autosservico"],periodos:["manha","tarde","noite","qualquer"],publicos:["todos","adultos","criancas","bebes"],obtencoes:["servir","pronto","preparar"]};
  for (const k of ["aliases",...Object.keys(options)]) if (!Array.isArray(r[k]) || !r[k].length || r[k].length > 30 || r[k].some((s:any) => typeof s !== "string" || !s.trim() || s.length > 160 || options[k] && !options[k].includes(s))) fail(`Confira ${k}.`);
  if (!["principal","acompanhamento","bebida","outro"].includes(r.papel) || !["quilo","litro","unidade"].includes(r.unidade) || !["cru","seco","pronto"].includes(r.estado_consumo) || !["cru","seco","pronto"].includes(r.estado_compra)) fail("Papel, unidade ou estado incompatível.");
  if (r.tipo !== "modelo") {
    for (const k of ["minimo","maximo","padrao"]) if (typeof r[k] !== "number" || !Number.isFinite(r[k]) || r[k] <= 0 || r[k] > 10000) fail("Faixa inválida.");
    if (r.minimo > r.padrao || r.padrao > r.maximo) fail("Porção fora da faixa.");
  } else if (!Array.isArray(r.itens) || !r.itens.length || r.itens.length > 30 || r.itens.some((i:any) => !i || Object.keys(i).some(k => !["nome","tipo"].includes(k)) || typeof i.nome !== "string" || !i.nome.trim() || i.nome.length > 120 || !["comida","bebida","bolo","sobremesa","outro"].includes(i.tipo))) fail("Itens de modelo inválidos.");
  if(r.tipo === "modelo" && (r.servicos.length !== 1 || r.formatos.length !== 1)) fail("O modelo deve declarar um serviço e um formato.");
  for (const k of ["verificado_em","aprovado_em"]) if (r[k] != null && (typeof r[k] !== "string" || !Number.isFinite(Date.parse(r[k])))) fail("Data editorial inválida.");
  if (r.aprovado_por != null && typeof r.aprovado_por !== "string") fail("Aprovação inválida.");
  if(r.infraestrutura!=null&&(!Array.isArray(r.infraestrutura)||r.infraestrutura.length>4||r.infraestrutura.some((k:any)=>!["cozinha","refrigeracao","aquecimento","equipe_preparo"].includes(k))))fail("Infraestrutura editorial inválida.");
  for(const k of ["duracao_minima","duracao_maxima"]) if(r[k]!=null && (!Number.isInteger(r[k])||r[k]<1||r[k]>1440)) fail("Duração editorial inválida.");
  if(r.duracao_minima!=null&&r.duracao_maxima!=null&&r.duracao_minima>r.duracao_maxima) fail("Intervalo de duração inválido.");
  for(const k of ["hora_inicio","hora_fim"]) if(r[k]!=null && (typeof r[k]!=="string"||!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(r[k]))) fail("Faixa horária inválida.");
  if((r.hora_inicio==null)!==(r.hora_fim==null)||r.hora_inicio!=null&&r.hora_inicio>r.hora_fim) fail("Intervalo horário inválido.");
}
export async function editarCatalogoContextual(db: Firestore, uid: string | undefined, input: any): Promise<M> {
  if (!uid) throw new HttpsError("unauthenticated","Entre na conta administrativa.");
  if (["selecionar","desativar"].includes(input?.acao)) return selecionarVersaoCatalogo(db,uid,input);
  const r = input?.referencia, acao = input?.acao, esperada = input?.versao_esperada, pedido = input?.pedido;
  validarReferenciaContextual(r);
  if (!["rascunho","aprovar","publicar"].includes(acao) || !Number.isInteger(esperada) || esperada < 0 || r.versao !== esperada + 1 || typeof pedido !== "string" || !/^[a-zA-Z0-9_-]{1,120}$/.test(pedido) || Buffer.byteLength(JSON.stringify(input)) > 100000) fail("Confirmação editorial inválida.");
  const assinatura = createHash("sha256").update(JSON.stringify({r,esperada,acao})).digest("hex");
  return db.runTransaction(async tx => {
    const usuario = await tx.get(db.doc(`usuarios/${uid}`));
    if (usuario.data()?.tipo !== "A" || usuario.data()?.ativo !== true) throw new HttpsError("permission-denied","Somente administrador ativo pode revisar o catálogo.");
    const ref = db.doc(`calculadora_itens_base/${r.id}`), doc = await tx.get(ref), anterior = doc.data() ?? {};
    const reciboRef = ref.collection("edicoes_contextuais").doc(pedido), recibo = await tx.get(reciboRef);
    if (recibo.exists) {if (recibo.data()?.assinatura !== assinatura) fail("Este pedido já confirmou outros dados."); return recibo.data()!.resultado;}
    if ((anterior.governanca_contextual?.ultima_versao ?? anterior.referencia_contextual?.versao ?? 0) !== esperada) fail("Uma nova versão foi publicada. Atualize antes de revisar.");
    const conteudo = {...r,aprovado_por:null,aprovado_em:null};
    const hashConteudo = createHash("sha256").update(JSON.stringify(conteudo)).digest("hex");
    const validacaoRef = ref.collection("validacoes_contextuais").doc(String(r.versao));
    const validacao = await tx.get(validacaoRef);
    if (acao === "publicar" && validacao.data()?.assinatura !== hashConteudo) fail("Aprove esta revisão antes de publicar; atualize o cliente editorial.");
    const agora = Timestamp.now().toDate().toISOString();
    const resultado = {...r, aprovado_por: acao === "publicar" ? validacao.data()!.responsavel : null, aprovado_em: acao === "publicar" ? validacao.data()!.em : null};
    const base = {id:r.id,nome:r.nome,descricao:r.contexto,categoria_padrao:"comida",tipo_item:"outro",unidade_padrao:r.unidade,publico_alvo:r.publicos[0],ativo:true,ordem:anterior.ordem ?? 0,icone:"",tags:[],created_at:anterior.created_at ?? Timestamp.now(),updated_at:Timestamp.now()};
    if (acao === "publicar") {
      const vref = ref.collection("versoes_contextuais").doc(String(r.versao)), existente = await tx.get(vref);
      if (existente.exists) fail("Essa versão já existe e é imutável.");
      tx.create(vref, resultado);
      tx.set(ref, {...base,referencia_contextual:resultado,referencia_rascunho:null}, {merge:true});
      tx.set(ref,{governanca_contextual:{schema:1,estado:"publicada",ultima_versao:r.versao,versao_selecionada:r.versao,responsavel:uid,em:agora}},{merge:true});
      if (anterior.referencia_contextual?.versao != null) tx.set(ref.collection("estados_contextuais").doc(String(anterior.referencia_contextual.versao)),{estado:"substituida",substituida_por:r.versao,responsavel:uid,em:agora});
      tx.set(ref.collection("estados_contextuais").doc(String(r.versao)),{estado:"publicada",responsavel:uid,em:agora});
    } else {
      tx.set(ref,{...base,referencia_rascunho:resultado,governanca_contextual:{
        schema:1,estado:acao === "aprovar" ? "aprovada" : "rascunho",
        ultima_versao:esperada,versao_selecionada:anterior.referencia_contextual?.versao ?? null,responsavel:uid,em:agora}},{merge:true});
      if (acao === "aprovar") tx.set(validacaoRef,{assinatura:hashConteudo,responsavel:uid,papel:"administrador",fonte:r.fonte,versao:r.versao,em:agora});
      else if (validacao.exists) tx.delete(validacaoRef);
    }
    tx.create(reciboRef,{assinatura,resultado,usuario:uid});
    return resultado;
  });
}

async function selecionarVersaoCatalogo(db: Firestore, uid: string, input: M): Promise<M> {
  const {id,acao,versao_alvo:alvo,versao_esperada:esperada,pedido} = input;
  if (typeof id !== "string" || !/^[a-z0-9_\-]{1,120}$/.test(id) ||
      !Number.isInteger(esperada) || esperada < 1 ||
      (acao === "selecionar" && (!Number.isInteger(alvo) || alvo < 1)) ||
      typeof pedido !== "string" || !/^[a-zA-Z0-9_-]{1,120}$/.test(pedido)) fail("Seleção editorial inválida.");
  const assinatura = createHash("sha256").update(JSON.stringify({id,acao,alvo:alvo ?? null,esperada})).digest("hex");
  return db.runTransaction(async tx => {
    const user = await tx.get(db.doc(`usuarios/${uid}`));
    if (user.data()?.tipo !== "A" || user.data()?.ativo !== true) throw new HttpsError("permission-denied","Somente administrador ativo pode selecionar publicações.");
    const ref = db.doc(`calculadora_itens_base/${id}`), doc = await tx.get(ref), d = doc.data() ?? {};
    const reciboRef = ref.collection("edicoes_contextuais").doc(pedido), recibo = await tx.get(reciboRef);
    if (recibo.exists) {if (recibo.data()?.assinatura !== assinatura) fail("Pedido já utilizado."); return recibo.data()!.resultado;}
    if ((d.governanca_contextual?.ultima_versao ?? d.referencia_contextual?.versao) !== esperada) fail("Catálogo mudou; atualize a seleção.");
    let selecionada = null;
    if (acao === "selecionar") {
      const versao = await tx.get(ref.collection("versoes_contextuais").doc(String(alvo)));
      if (!versao.exists) fail("Selecione uma versão publicada existente.");
      selecionada = versao.data()!;
      validarReferenciaContextual(selecionada);
      if (!selecionada.aprovado_por || !selecionada.aprovado_em) fail("Versão sem aprovação.");
    }
    const resultado = {id,versao_selecionada:selecionada?.versao ?? null,estado:selecionada ? "publicada" : "desativada"};
    tx.set(ref,{referencia_contextual:selecionada,governanca_contextual:{schema:1,ultima_versao:esperada,...resultado,responsavel:uid,em:Timestamp.now().toDate().toISOString()}},{merge:true});
    tx.create(reciboRef,{assinatura,resultado,usuario:uid});
    return resultado;
  });
}
