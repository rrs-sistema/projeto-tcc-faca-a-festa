import {createHash} from "crypto";
import {Firestore, Timestamp} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

type M = Record<string, any>;
export const VERSAO_COMPATIBILIDADE = 1;
// Ordenação estável inclusive para mapas e Timestamps. Nunca enviar o conteúdo ao log.
export function assinaturaCompatibilidade(v: any): string {
  const normalizar = (x: any): any => x instanceof Timestamp ? {segundos:x.seconds,nanos:x.nanoseconds} :
    Array.isArray(x) ? x.map(normalizar) : x && typeof x === "object" ?
      Object.fromEntries(Object.keys(x).sort().map(k => [k,normalizar(x[k])])) : x;
  return createHash("sha256").update(JSON.stringify(normalizar(v))).digest("hex");
}
export function inspecionarLegado(evento: M, operacao: M, menus: M[], historicos: M[]): M {
  const idade = ["total_adultos","total_criancas","total_bebes"];
  const total = evento.total_convidados ?? (idade.some(k => evento[k] != null) ? idade.reduce((s,k) => s + (evento[k] ?? 0),0) : null);
  const hipoteses: string[] = [];
  if (evento.data_fim == null) hipoteses.push("termino_nao_informado");
  if (total != null && !idade.some(k => evento[k] != null)) hipoteses.push("distribuicao_etaria_desconhecida");
  if (total == null) hipoteses.push("publico_nao_informado");
  if (operacao.versao != null && operacao.versao !== 1) throw new HttpsError("failed-precondition","Operação exige leitor mais recente.");
  const agenda = Array.isArray(operacao.agenda) ? operacao.agenda : [];
  const semOcorrencia = menus.filter(m => !agenda.some((a: M) => a.id_cardapio === m.id_cardapio)).length;
  if (semOcorrencia) hipoteses.push("cardapios_sem_ocorrencia");
  const regras = operacao.execucao?.regras ?? [];
  if (!Array.isArray(regras)) throw new HttpsError("failed-precondition","Regras incompatíveis; inspeção manual necessária.");
  if (regras.some((r: M) => !r.premissas?.fonte)) hipoteses.push("regras_sem_origem_declarada");
  if (historicos.some(h => (h.contexto_planejamento?.versao_motor ?? 0) < 6)) hipoteses.push("historico_motor_anterior_preservado");
  return {schema:VERSAO_COMPATIBILIDADE, motor_leitor:6, origem:"inspecao_sem_recalculo", hipoteses,
    total_informado:total, termino_confirmado:evento.data_fim != null, cardapios_sem_ocorrencia:semOcorrencia};
}

/** Migração aditiva: só publica a interpretação em um sidecar; fatos nunca são alvo de escrita. */
export async function migrarPlanejamento(db: Firestore, uid: string | undefined, input: M): Promise<M> {
  if (!uid) throw new HttpsError("unauthenticated","Entre na conta responsável.");
  const projeto = process.env.GCLOUD_PROJECT ?? "";
  if (!projeto.startsWith("demo-") || input?.projeto !== projeto ||
      !/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST ?? "")) {
    throw new HttpsError("failed-precondition","Ferramenta habilitada somente em projeto demo e emulador local.");
  }
  const {evento, acao = "inspecionar", assinatura} = input;
  if (typeof evento !== "string" || !/^[\w-]{1,120}$/.test(evento) || !["inspecionar","aplicar","reverter"].includes(acao)) {
    throw new HttpsError("invalid-argument","Selecione evento e ação explicitamente.");
  }
  return db.runTransaction(async tx => {
    const usuario = await tx.get(db.doc(`usuarios/${uid}`));
    if (usuario.data()?.ativo !== true || usuario.data()?.tipo !== "A" || usuario.data()?.migracao_planejamento !== true) {
      throw new HttpsError("permission-denied","Exige administrador ativo com autorização de migração.");
    }
    const ref = db.doc(`planejamento_compatibilidade/${evento}`), e = await tx.get(db.doc(`evento/${evento}`));
    if (!e.exists) throw new HttpsError("not-found","Evento não encontrado.");
    if (typeof e.data()?.id_usuario !== "string" || !e.data()!.id_usuario) throw new HttpsError("failed-precondition","Evento sem organizador identificado.");
    const atual = await tx.get(ref);
    if (atual.exists && atual.data()?.schema !== VERSAO_COMPATIBILIDADE) throw new HttpsError("failed-precondition","Projeção exige migrador mais recente.");
    // Desativar não depende de reinterpretar fontes que mudaram de motor.
    if (acao === "reverter") {
      if (!atual.exists || assinatura !== atual.data()?.assinatura) throw new HttpsError("aborted","Confira a assinatura da seleção que deseja desativar.");
      const resultado = {schema:1,assinatura,estado:"revertido",alterado:atual.data()!.selecao_ativa === true};
      if (!resultado.alterado) return resultado;
      const revisao = atual.data()!.revisao + 1;
      tx.update(ref,{selecao_ativa:false,revisao,responsavel:uid,atualizado_em:Timestamp.now()});
      tx.create(ref.collection("transicoes").doc(String(revisao)),{acao,assinatura,responsavel:uid,em:Timestamp.now()});
      return resultado;
    }
    const op = await tx.get(db.doc(`calculadora_operacao/${evento}`));
    const menus = await tx.get(db.collection("cardapios").where("id_evento","==",evento).limit(101));
    const historicos = await tx.get(db.collection("calculadora_festa").where("id_evento","==",evento).limit(101));
    if (menus.size > 100 || historicos.size > 100) throw new HttpsError("resource-exhausted","Inspeção excede lote suportado; revisão manual necessária.");
    if (op.exists && (op.data()?.id_usuario !== e.data()?.id_usuario || op.data()?.id_evento !== evento)) {
      throw new HttpsError("failed-precondition","Operação não corresponde ao organizador e evento.");
    }
    const fontes = {evento:e.data(),operacao:op.data() ?? null,
      cardapios:menus.docs.map(d => ({path:d.ref.path,dados:d.data()})).sort((a,b) => a.path.localeCompare(b.path)),
      historicos:historicos.docs.map(d => ({path:d.ref.path,dados:d.data()})).sort((a,b) => a.path.localeCompare(b.path))};
    const hash = assinaturaCompatibilidade(fontes);
    const leitura = inspecionarLegado(e.data()!,op.data() ?? {},menus.docs.map(d => ({...d.data(),id_cardapio:d.id})),historicos.docs.map(d => d.data()));
    const resultado = {schema:1,assinatura:hash,hipoteses:leitura.hipoteses,cardapios:menus.size,historicos:historicos.size};
    // Inspeção é estritamente read-only. A assinatura aprovada fixa o conjunto lido.
    if (acao === "inspecionar") return {...resultado,estado:"inspecionado",alterado:false};
    if (assinatura !== hash) throw new HttpsError("aborted","As fontes mudaram; repita a inspeção antes de confirmar.");
    const ativo = acao === "aplicar";
    if (atual.data()?.assinatura === hash && atual.data()?.selecao_ativa === ativo) return {...resultado,estado:ativo ? "ativo" : "revertido",alterado:false};
    if (!ativo && !atual.exists) throw new HttpsError("failed-precondition","Não existe seleção para reverter.");
    const copiaRef = ref.collection("inspecoes").doc(hash), copia = await tx.get(copiaRef);
    // Cópia privada completa no mesmo commit, anterior à ativação. Nunca no relatório/log.
    if (!copia.exists) tx.create(copiaRef,{schema:1,fontes,criado_em:Timestamp.now(),responsavel:uid});
    const revisao = (atual.data()?.revisao ?? 0) + 1;
    tx.set(ref,{schema:1,id_evento:evento,id_usuario:e.data()!.id_usuario,assinatura:hash,
      selecao_ativa:ativo,revisao,leitura,responsavel:uid,atualizado_em:Timestamp.now()});
    tx.create(ref.collection("transicoes").doc(String(revisao)),{acao,assinatura:hash,responsavel:uid,em:Timestamp.now()});
    return {...resultado,estado:ativo ? "ativo" : "revertido",alterado:true};
  });
}
