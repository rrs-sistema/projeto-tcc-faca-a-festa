import { createHash } from "crypto";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import { transacaoIdempotente } from "../../shared/transacaoIdempotente";
import { idJornada } from "../cotacao/jornadaAtendimentoService";
import { COL_CASOS } from "../financeiro/mediacaoPersistenciaService";
import { MEDIDAS_FORNECEDOR, restricaoVigente } from "./restricaoComercial";

type Dados = Record<string, any>;

function texto(valor: unknown, campo: string, maximo = 2000): string {
  const s = typeof valor === "string" ? valor.trim() : "";
  if (!s || s.length > maximo) throw new HttpsError("invalid-argument", `Preencha ${campo} (até ${maximo} caracteres).`);
  return s;
}

export async function registrarMedidaFornecedor(db: Firestore, autor: string, dados: Dados, agora = new Date()) {
  const idFornecedor = idJornada(dados.idFornecedor);
  const chave = idJornada(dados.chave);
  const acao = dados.acao;
  if (!["advertir", "restringir", "suspender", "descredenciar", "retirar", "manter_recurso"].includes(acao)) {
    throw new HttpsError("invalid-argument", "Medida inválida.");
  }
  const temporaria = acao === "restringir" || acao === "suspender";
  const bloqueio = temporaria || acao === "descredenciar";
  const analisaRecurso = acao === "manter_recurso";
  const justificativa = texto(dados.justificativa, "a justificativa interna");
  const comunicado = texto(dados.comunicado, "a mensagem ao fornecedor");
  const retorno = bloqueio || acao === "advertir" ? texto(dados.retorno, "a condição de regularização") : null;
  const idCaso = dados.idCaso ? idJornada(dados.idCaso) : null;
  const idServico = acao === "restringir" && dados.idServico ? idJornada(dados.idServico) : null;
  const fundamento = bloqueio ? dados.fundamento : null;
  const dias = dados.dias;
  if (bloqueio && (!idCaso || !["preventiva", "confirmada"].includes(fundamento) ||
      (temporaria && (!Number.isInteger(dias) || dias < 1 || dias > 90)) ||
      (acao !== "restringir" && fundamento !== "confirmada"))) {
    throw new HttpsError("invalid-argument", "Vincule um caso e indique o fundamento. Medidas temporárias exigem duração de 1 a 90 dias. Suspensão e descredenciamento exigem infração confirmada.");
  }
  const instante = agora.toISOString();
  const ate = temporaria ? new Date(agora.getTime() + dias * 86400000).toISOString() : null;
  const ref = db.collection(MEDIDAS_FORNECEDOR).doc(idFornecedor);
  const assinatura = createHash("sha256").update(JSON.stringify([
    acao, justificativa, comunicado, retorno, idCaso, idServico, fundamento, dias, dados.versao,
  ])).digest("hex");
  const id = createHash("sha256").update(JSON.stringify([autor, chave])).digest("hex");
  const registro = ref.collection("historico").doc(id);
  return transacaoIdempotente(db, async tx => {
    const [fornecedor, atual, anterior] = await tx.getAll(
      db.collection("fornecedor").doc(idFornecedor), ref, registro);
    if (anterior.exists) {
      if (anterior.data()?.assinatura !== assinatura) throw new HttpsError("already-exists", "Chave já utilizada em outra decisão.");
      return { id, idempotente: true };
    }
    if (!fornecedor.exists) throw new HttpsError("not-found", "Fornecedor não encontrado.");
    const anteriorDados = atual.data();
    const versao = anteriorDados?.versao ?? 0;
    if (dados.versao !== versao) throw new HttpsError("aborted", "A medida mudou. Atualize a ficha antes de decidir.");
    const caso = idCaso ? await tx.get(db.collection(COL_CASOS).doc(idCaso)) : null;
    if (idCaso && caso?.data()?.id_fornecedor !== idFornecedor) {
      throw new HttpsError("failed-precondition", "O caso deve pertencer a este fornecedor.");
    }
    if (bloqueio && (fundamento === "confirmada" ? caso?.data()?.estado !== "fechado" :
        ["fechado", "cancelado_caso"].includes(caso?.data()?.estado))) {
      throw new HttpsError("failed-precondition", "Medida preventiva exige caso em aberto. Infração confirmada exige caso encerrado após apuração.");
    }
    const vigente = restricaoVigente(anteriorDados, instante);
    const recursoPendente = anteriorDados?.recurso?.estado === "pendente";
    if (acao === "advertir" && (vigente || recursoPendente) ||
        acao === "retirar" && !vigente && !recursoPendente ||
        analisaRecurso && !recursoPendente ||
        bloqueio && recursoPendente) {
      throw new HttpsError("failed-precondition", "Revise a medida vigente e resolva eventual recurso pendente antes de substituí-la.");
    }
    let nomeServico = null;
    if (idServico) {
      const vinculo = await tx.get(db.collection("fornecedor_servico").where("id_fornecedor", "==", idFornecedor)
        .where("id_produto_servico", "==", idServico).limit(1));
      if (vinculo.empty) throw new HttpsError("failed-precondition", "O serviço deve estar vinculado a este fornecedor.");
      const servico = await tx.get(db.collection("servico_produto").doc(idServico));
      nomeServico = servico.data()?.nome || vinculo.docs[0].data().nome_produto_servico || "Serviço do fornecedor";
    }
    const recurso = recursoPendente ? { ...anteriorDados?.recurso, estado: "decidido", decisao: comunicado, decididoEm: instante } : null;
    const entrada = { id, acao, autor, justificativa, comunicado, retorno, fundamento, idServico,
      servico: nomeServico,
      idCaso: idCaso ?? (acao === "retirar" || analisaRecurso ? anteriorDados?.idCaso ?? null : null), ate, criadoEm: instante };
    const proxima = analisaRecurso
      ? { ...anteriorDados, recurso, versao: versao + 1 }
      : { ...entrada, ateTimestamp: ate ? Timestamp.fromDate(new Date(ate)) : null, recurso, versao: versao + 1 };
    tx.create(registro, { ...entrada, assinatura, medidaAnterior: anteriorDados?.id ?? null });
    tx.set(ref, proxima);
    return { id, idempotente: false };
  });
}

export async function registrarRecursoFornecedor(db: Firestore, uid: string, dados: Dados, agora = new Date()) {
  const idMedida = idJornada(dados.idMedida);
  const mensagem = texto(dados.mensagem, "o motivo do recurso");
  const ref = db.collection(MEDIDAS_FORNECEDOR).doc(uid);
  return transacaoIdempotente(db, async tx => {
    const snap = await tx.get(ref);
    const medida = snap.data();
    if (!medida || medida.id !== idMedida || !["advertir", "restringir", "suspender", "descredenciar"].includes(medida.acao)) {
      throw new HttpsError("failed-precondition", "A medida selecionada foi substituída. Atualize o comunicado.");
    }
    if (medida.recurso) {
      if (medida.recurso.mensagem === mensagem) return { ok: true };
      throw new HttpsError("already-exists", "Já existe recurso para esta medida.");
    }
    const recurso = { estado: "pendente", mensagem, criadoEm: agora.toISOString() };
    tx.create(ref.collection("historico").doc(`recurso_${idMedida}`), {
      acao: "recurso", autor: uid, comunicado: mensagem, criadoEm: recurso.criadoEm, medidaAnterior: idMedida,
    });
    tx.update(ref, { recurso, versao: medida.versao + 1 });
    return { ok: true };
  });
}

const regiao = { region: "southamerica-east1" };

export const registrarMedidaFornecedorFn = onCall(regiao, async req => {
  const perfil = await exigirUsuarioAutenticado(req.auth?.uid);
  exigirTipo(perfil, ["A"]);
  return registrarMedidaFornecedor(admin.firestore(), perfil.uid, req.data ?? {});
});

export const consultarComunicadoFornecedorFn = onCall(regiao, async req => {
  const perfil = await exigirUsuarioAutenticado(req.auth?.uid);
  exigirTipo(perfil, ["F"]);
  const medida = (await admin.firestore().collection(MEDIDAS_FORNECEDOR).doc(perfil.uid).get()).data();
  if (!medida) return { medida: null };
  const { id, acao, comunicado, retorno, ate, criadoEm, recurso, servico } = medida;
  return { medida: { id, acao, comunicado, retorno, ate, criadoEm, recurso, servico: servico ?? null,
    vigente: restricaoVigente(medida, new Date().toISOString()) } };
});

export const registrarRecursoFornecedorFn = onCall(regiao, async req => {
  const perfil = await exigirUsuarioAutenticado(req.auth?.uid);
  exigirTipo(perfil, ["F"]);
  return registrarRecursoFornecedor(admin.firestore(), perfil.uid, req.data ?? {});
});
