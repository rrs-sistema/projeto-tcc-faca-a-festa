import { transacaoIdempotente } from "../../shared/transacaoIdempotente";
import { createHash } from "crypto";
import { FieldValue, Firestore, Transaction } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { contratado } from "../financeiro/liberacaoRepasseService";

const id = (v: unknown): string => {
  if (typeof v !== "string" || !v.trim() || v.length > 200 || v.includes("/")) throw new HttpsError("invalid-argument", "Identificador inválido.");
  return v.trim();
};
export function identidadeAvaliacao(uid: string, contrato: string, objeto: string) {
  return createHash("sha256").update(JSON.stringify([uid, contrato, objeto])).digest("hex");
}
export function reputacaoVerificada(d: Record<string, any>, tipo = "fornecedor") {
  return d.schema === 2 && d.verificada === true && typeof d.id_contrato === "string" && !!d.id_contrato &&
    typeof d.id_cliente === "string" && !!d.id_cliente && typeof d.id_fornecedor === "string" && !!d.id_fornecedor && d.tipo === tipo && d.moderacao !== "oculta" &&
    Number.isInteger(d.nota) && d.nota >= 1 && d.nota <= 5;
}
export function resumoVerificado(dados: Record<string, any>[], tipo = "fornecedor") {
  const validos = dados.filter(d => reputacaoVerificada(d, tipo));
  const soma = validos.reduce((s, d) => s + d.nota, 0);
  return { schema: 2, soma, quantidade: validos.length, media: validos.length ? soma / validos.length : 0 };
}
// O histórico inicial nunca foi gravável pelo cliente; flags legadas isoladas não são prova.
export async function registrosConfiaveis(tx: Transaction, docs: FirebaseFirestore.QueryDocumentSnapshot[]) {
  const resultado: Record<string, any>[] = [];
  for (const doc of docs) {
    const d=doc.data();
    if (!["fornecedor","servico"].includes(d.tipo) || !reputacaoVerificada({...d,moderacao:"publicada"},d.tipo) ||
        doc.id !== identidadeAvaliacao(d.id_cliente,d.id_contrato,d.tipo === "servico" ? `servico:${d.id_servico}` : "fornecedor")) continue;
    const h=await tx.get(doc.ref.collection("historico").doc("criacao"));
    if (h.data()?.acao === "criar" && ["id_contrato","id_cliente","id_fornecedor","id_servico","tipo","nota","comentario"].every(k=>h.data()?.[k] === d[k])) resultado.push(d);
  }
  return resultado;
}
async function elegivel(db: Firestore, tx: Transaction, uid: string, ref: FirebaseFirestore.DocumentReference, fornecedor: string, servico?: string) {
  const snap = await tx.get(ref); const o = snap.data();
  if (!o || o.id_fornecedor !== fornecedor || uid === fornecedor) throw new HttpsError("permission-denied", "Contratação não pertence às partes.");
  const ev = await tx.get(db.collection("evento").doc(id(o.id_evento)));
  const dono = ev.data()?.id_usuario || ev.data()?.idUsuario;
  const clientes = [dono, o.id_solicitante].filter(Boolean);
  if (!clientes.includes(uid)) throw new HttpsError("permission-denied", "Somente o contratante pode avaliar.");
  const historico = await tx.get(ref.collection("execucao_historico"));
  const prova = historico.docs.some(h => {
    const d = h.data(); return d.estado_novo === "aceito" &&
      ((d.acao === "aceitar" && clientes.includes(d.autor_id) && d.papel === "cliente") ||
       (d.acao === "resolver_mediacao" && d.papel === "admin"));
  });
  if (!contratado(o) || (o.contrato_financeiro?.estado_execucao || o.estado_execucao) !== "aceito" || !prova ||
      ["cancelado", "cancelada"].includes(ev.data()?.status)) throw new HttpsError("failed-precondition", "É necessário aceite da entrega registrado na jornada.");
  if (servico && ![o.id_servico, o.id_produto_servico, o.id_fornecedor_servico].includes(servico) &&
      o.id_fornecedor_servico !== `${fornecedor}_${servico}`) throw new HttpsError("failed-precondition", "O objeto não corresponde ao serviço contratado.");
  return { o, evento: ev.data()!, contrato: String(o.contrato_financeiro?.id_contrato || snap.id) };
}
export async function listarContratosAvaliaveis(db: Firestore, uid: string, data: any) {
  const fornecedor = id(data.idFornecedor), evento = id(data.idEvento);
  const servico = data.idServico ? id(data.idServico) : undefined;
  return db.runTransaction(async tx => {
    const e = await tx.get(db.collection("evento").doc(evento));
    if (!e.exists || uid === fornecedor) return [];
    const docs = await tx.get(db.collection("orcamento").where("id_evento", "==", evento));
    const unicos = new Map<string, {idContrato:string; idOrcamento:string; nome:string}>();
    for (const doc of docs.docs) {
      if (doc.data().id_fornecedor !== fornecedor) continue;
      try {
        const c = await elegivel(db, tx, uid, doc.ref, fornecedor, servico);
        const objeto = servico ? `servico:${servico}` : "fornecedor";
        const a = await tx.get(db.doc(`fornecedor/${fornecedor}/avaliacoes/${identidadeAvaliacao(uid,c.contrato,objeto)}`));
        if (!a.exists) unicos.set(c.contrato, {idContrato:c.contrato,idOrcamento:doc.id,nome:String(c.o.nome_servico || c.o.nome || c.contrato)});
      } catch (e) { if (!(e instanceof HttpsError)) throw e; }
    }
    return [...unicos.values()];
  }, {readOnly:true});
}
export async function registrarAvaliacao(db: Firestore, uid: string, data: any) {
  const permitidos = ["idFornecedor","idOrcamento","idServico","nota","comentario"];
  if (!data || Object.keys(data).some(k=>!permitidos.includes(k))) throw new HttpsError("invalid-argument", "Campos não permitidos; autoria e datas vêm da sessão/servidor.");
  const fornecedor = id(data.idFornecedor), orcamento = id(data.idOrcamento);
  const servico = data.idServico == null ? undefined : id(data.idServico);
  if (!Number.isInteger(data.nota) || data.nota < 1 || data.nota > 5 || typeof data.comentario !== "string" || data.comentario.length > 500) throw new HttpsError("invalid-argument", "Nota inteira de 1 a 5 e comentário de até 500 caracteres.");
  const comentario = data.comentario.trim();
  if (comentario.length > 0 && comentario.length < 3) throw new HttpsError("invalid-argument", "Comentário opcional com 3 a 500 caracteres.");
  return transacaoIdempotente(db, async tx => {
    const c = await elegivel(db,tx,uid,db.collection("orcamento").doc(orcamento),fornecedor,servico);
    const tipo = servico ? "servico" : "fornecedor";
    const chave = identidadeAvaliacao(uid,c.contrato,servico ? `servico:${servico}` : "fornecedor");
    const ref = db.doc(`fornecedor/${fornecedor}/avaliacoes/${chave}`);
    const anterior = await tx.get(ref);
    if (anterior.exists) {
      const h=await tx.get(ref.collection("historico").doc("criacao"));
      if (h.data()?.acao !== "criar" || h.data()?.id_cliente !== uid || h.data()?.id_contrato !== c.contrato) throw new HttpsError("failed-precondition", "Registro legado sem comprovação. Histórico preservado sem reclassificação automática.");
      if (anterior.data()?.nota !== data.nota || anterior.data()?.comentario !== comentario) throw new HttpsError("already-exists", "Avaliação já registrada. Nota e comentário são imutáveis.");
      return {id:chave,idempotente:true};
    }
    const perfil = await tx.get(db.doc(`usuarios/${uid}`));
    const f = await tx.get(db.doc(`fornecedor/${fornecedor}`));
    if (!f.exists || !perfil.exists || perfil.data()?.ativo === false) throw new HttpsError("permission-denied", "Perfil indisponível.");
    const existentes = await tx.get(db.collection(`fornecedor/${fornecedor}/avaliacoes`));
    const sr = servico ? db.doc(`fornecedor_servico/${fornecedor}_${servico}`) : null;
    if (sr) { const s = await tx.get(sr); if (!s.exists || s.data()?.id_fornecedor !== fornecedor) throw new HttpsError("failed-precondition", "Serviço indisponível."); }
    const registro = {schema:2,verificada:true,tipo,id:chave,id_contrato:c.contrato,id_orcamento:orcamento,
      id_fornecedor:fornecedor,id_servico:servico || null,id_cliente:uid,
      nome_cliente:String(perfil.data()?.nome || "Cliente"),id_evento:c.o.id_evento,
      nome_evento:String(c.evento.nome || c.evento.nome_evento || ""),nota:data.nota,comentario,
      data:FieldValue.serverTimestamp(),moderacao:"publicada"};
    const todos = [...await registrosConfiaveis(tx,existentes.docs),registro];
    const resumo = resumoVerificado(todos);
    tx.create(ref,registro);
    tx.create(ref.collection("historico").doc("criacao"),{...registro,acao:"criar",autor_id:uid});
    tx.update(f.ref,{reputacao_verificada:resumo,mediaAvaliacoes:resumo.media,media_avaliacoes:resumo.media,
      totalAvaliacoes:resumo.quantidade,total_avaliacoes:resumo.quantidade,avaliacoesAtualizadasEm:FieldValue.serverTimestamp()});
    if (sr) tx.update(sr,{reputacao_verificada:resumoVerificado(todos.filter(d=>d.id_servico === servico),"servico")});
    return {id:chave,idempotente:false};
  });
}
export const registrarAvaliacaoVerificada = onCall({region:"southamerica-east1"},async req=>{
  const p = await exigirUsuarioAutenticado(req.auth?.uid); return registrarAvaliacao(admin.firestore(),p.uid,req.data);
});
export const consultarContratosAvaliaveis = onCall({region:"southamerica-east1"},async req=>{
  const p = await exigirUsuarioAutenticado(req.auth?.uid); return {contratos:await listarContratosAvaliaveis(admin.firestore(),p.uid,req.data)};
});

// Autorização específica em custom claim emitida por operador confiável, sem acesso por tipo A genérico.
export const moderarAvaliacaoVerificada = onCall({region:"southamerica-east1"},async req=>{
  const p = await exigirUsuarioAutenticado(req.auth?.uid);
  if (req.auth?.token.moderar_avaliacoes !== true) throw new HttpsError("permission-denied","Permissão específica de moderação necessária.");
  const d = req.data || {};
  if (Object.keys(d).some(k=>!["idFornecedor","idAvaliacao","ocultar","motivo"].includes(k)) || typeof d.ocultar !== "boolean" || typeof d.motivo !== "string" || d.motivo.trim().length < 10 || d.motivo.length > 500) throw new HttpsError("invalid-argument","Informe ação e motivo de 10 a 500 caracteres.");
  return admin.firestore().runTransaction(tx=>aplicarModeracaoAvaliacao(admin.firestore(),tx,p.uid,d));
});

/** Reutilizada pela fila: decisão, histórico e agregados compartilham o commit. */
export async function aplicarModeracaoAvaliacao(db: Firestore, tx: Transaction, autor: string, d: {
  idFornecedor: string; idAvaliacao: string; ocultar: boolean; motivo: string;
}, permitirLegado=false) {
    const fornecedor=id(d.idFornecedor), chave=id(d.idAvaliacao);
    if (autor === fornecedor) throw new HttpsError("permission-denied","Fornecedor não modera a própria reputação.");
    const ref=db.doc(`fornecedor/${fornecedor}/avaliacoes/${chave}`), snap=await tx.get(ref);
    if (!snap.exists || (!permitirLegado && snap.data()?.schema !== 2)) throw new HttpsError("failed-precondition","Avaliação não encontrada.");
    if (snap.data()?.id_cliente === autor) throw new HttpsError("permission-denied","Autor não modera a própria avaliação.");
    const docs=await tx.get(db.collection(`fornecedor/${fornecedor}/avaliacoes`));
    const estado=d.ocultar ? "oculta" : "publicada";
    if (snap.data()?.moderacao === estado) return {idempotente:true};
    const confiaveis=await registrosConfiaveis(tx,docs.docs);
    if (!permitirLegado && !confiaveis.some(x=>x.id===chave)) throw new HttpsError("failed-precondition","Registro sem comprovação de origem.");
    const todos=confiaveis.map(x=>x.id===chave ? {...x,moderacao:estado}:x);
    const resumo=resumoVerificado(todos);
    tx.create(ref.collection("historico").doc(),{acao:"moderar",autor_id:autor,motivo:d.motivo.trim(),anterior:snap.data(),moderacao:estado,data:FieldValue.serverTimestamp()});
    tx.update(ref,{moderacao:estado});
    tx.update(db.doc(`fornecedor/${fornecedor}`),{reputacao_verificada:resumo,mediaAvaliacoes:resumo.media,media_avaliacoes:resumo.media,totalAvaliacoes:resumo.quantidade,total_avaliacoes:resumo.quantidade});
    if (snap.data()?.id_servico && confiaveis.some(x=>x.id===chave)) tx.update(db.doc(`fornecedor_servico/${fornecedor}_${snap.data()!.id_servico}`),{reputacao_verificada:resumoVerificado(todos.filter(x=>x.id_servico===snap.data()!.id_servico),"servico")});
    return {idempotente:false};
}
