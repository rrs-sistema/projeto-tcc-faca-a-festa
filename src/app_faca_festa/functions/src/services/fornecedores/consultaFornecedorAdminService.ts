import { DocumentSnapshot, Firestore, QueryDocumentSnapshot } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { exigirTipo, exigirUsuarioAutenticado } from "../../shared/auth";
import { admin } from "../../shared/firebaseAdmin";
import { registrosConfiaveis } from "../avaliacoes/avaliacaoVerificadaService";
import { comercialLegado, idJornada } from "../cotacao/jornadaAtendimentoService";
import { nomeUsuarioDeDoc } from "../financeiro/contratacaoIdentidadeService";
import { contratado } from "../financeiro/liberacaoRepasseService";
import { COL_CASOS } from "../financeiro/mediacaoPersistenciaService";
import { lerAtendimentosFornecedor, metricasAtendimentos, primeiraRespostaHoras } from "./painelOperacionalService";
import { MEDIDAS_FORNECEDOR, restricaoVigente } from "./restricaoComercial";

const DIA = 86400000;
const CASOS_ABERTOS = ["aberto", "em_analise", "aguardando_partes", "em_decisao"];
const PRIORIDADES = ["critica", "alta", "normal", "baixa"];

function iso(valor: any): string | null {
  const data = valor?.toDate?.() ?? (typeof valor === "string" ? new Date(valor) : null);
  return data && Number.isFinite(data.getTime()) ? data.toISOString() : null;
}

async function carregarEventos(db: Firestore, ids: unknown[]) {
  const unicos = [...new Set(ids.filter((id): id is string => typeof id === "string" && !!id && !id.includes("/")))];
  const lotes: string[][] = [];
  for (let i = 0; i < unicos.length; i += 100) lotes.push(unicos.slice(i, i + 100));
  const eventos = (await Promise.all(lotes.map(lote =>
    db.getAll(...lote.map(id => db.collection("evento").doc(id)),
      { fieldMask: ["data", "nome", "nome_evento", "status"] })))).flat();
  return new Map(eventos.map(ev => [ev.id, ev.data()]));
}

function dadosEvento(evento: FirebaseFirestore.DocumentData | undefined) {
  return { dataEvento: iso(evento?.data), evento: evento?.nome_evento || evento?.nome || "Evento", eventoCancelado:
    ["cancelado", "cancelada"].includes(evento?.status) };
}

function resumirCaso(doc: QueryDocumentSnapshot, eventos: Awaited<ReturnType<typeof carregarEventos>>, agora: Date) {
  const caso = doc.data();
  const evento = dadosEvento(eventos.get(caso.id_evento));
  const aberto = CASOS_ABERTOS.includes(caso.estado);
  const horas = evento.dataEvento ? (Date.parse(evento.dataEvento) - agora.getTime()) / 3600000 : null;
  const eventoProximo = aberto && !evento.eventoCancelado && horas !== null && horas >= -24 && horas <= 72;
  return { id: doc.id, idFornecedor: caso.id_fornecedor ?? null, idOrcamento: caso.id_orcamento,
    categoria: caso.categoria, motivo: caso.motivo, estado: caso.estado, prioridade: caso.prioridade ?? "normal",
    abertoEm: caso.aberto_em, responsavel: caso.id_responsavel ?? null, conclusao: caso.conclusao ?? null,
    eventoProximo, ...evento };
}

function ordenarCasos<T extends ReturnType<typeof resumirCaso>>(casos: T[]) {
  return casos.sort((a, b) => Number(b.prioridade === "critica") - Number(a.prioridade === "critica") ||
    Number(b.eventoProximo) - Number(a.eventoProximo) ||
    PRIORIDADES.indexOf(a.prioridade) - PRIORIDADES.indexOf(b.prioridade) ||
    String(a.abertoEm ?? "").localeCompare(String(b.abertoEm ?? "")));
}

function aguardaFornecedor(comercial: string, responsavel: unknown) {
  return !["ganho", "perdido", "recusado", "cancelado"].includes(comercial) &&
    (responsavel === "fornecedor" || (!responsavel && comercial === "nova_solicitacao"));
}

export async function consultarTriagemFornecedoresAdmin(
  db: Firestore, ids: string[], agora = new Date(),
) {
  if (!ids.length) return { fornecedores: [] };
  const instante = agora.toISOString();
  const lotes: string[][] = [];
  for (let i = 0; i < ids.length; i += 30) lotes.push(ids.slice(i, i + 30));
  const fornecedores = await Promise.all(lotes.map(async lote => {
    const limite = 1200;
    const [casos, participacoes, medidas] = await Promise.all([
      db.collection(COL_CASOS).where("id_fornecedor", "in", lote)
        .select("estado", "id_fornecedor", "id_evento", "prioridade", "id_responsavel", "aberto_em")
        .limit(limite + 1).get(),
      db.collectionGroup("fornecedores").where("id_fornecedor", "in", lote)
        .select("id_fornecedor", "estado_comercial", "status", "respondido", "prazo_retorno", "responsavel_retorno")
        .limit(limite + 1).get(),
      db.getAll(...lote.map(id => db.collection(MEDIDAS_FORNECEDOR).doc(id)),
        { fieldMask: ["acao", "ate", "servico"] }),
    ]);
    const casosAbertos = casos.docs.slice(0, limite).filter(doc => CASOS_ABERTOS.includes(doc.get("estado")));
    const aguardando = participacoes.docs.slice(0, limite).filter(doc =>
      /^cotacao\/[^/]+\/fornecedores\/[^/]+$/.test(doc.ref.path) &&
      doc.id === doc.get("id_fornecedor") &&
      aguardaFornecedor(comercialLegado(doc.data()), doc.get("responsavel_retorno")) &&
      (iso(doc.get("prazo_retorno")) ?? "") < instante);
    const pais = [...new Set(aguardando.map(doc => doc.ref.parent.parent!.id))];
    const lotesPais: string[][] = [];
    for (let i = 0; i < pais.length; i += 100) lotesPais.push(pais.slice(i, i + 100));
    const [eventos, cotacoes] = await Promise.all([
      carregarEventos(db, casosAbertos.map(doc => doc.get("id_evento"))),
      Promise.all(lotesPais.map(idsPai => db.getAll(...idsPai.map(id => db.collection("cotacao").doc(id)),
        { fieldMask: ["status", "data_limite_resposta"] }))),
    ]);
    const cotacoesPorId = new Map(cotacoes.flat().map(doc => [doc.id, doc.data()]));
    const vencidas = new Map<string, number>();
    for (const doc of aguardando) {
      const pai = cotacoesPorId.get(doc.ref.parent.parent!.id);
      const prazo = iso(doc.get("prazo_retorno")) ?? iso(pai?.data_limite_resposta);
      if (!pai || pai.status === "cancelada" || prazo === null || prazo >= instante) continue;
      vencidas.set(doc.id, (vencidas.get(doc.id) ?? 0) + 1);
    }
    const casosPorFornecedor = new Map<string, ReturnType<typeof resumirCaso>[]>();
    for (const doc of casosAbertos) {
      const id = doc.get("id_fornecedor") as string;
      const grupo = casosPorFornecedor.get(id) ?? [];
      grupo.push(resumirCaso(doc, eventos, agora));
      casosPorFornecedor.set(id, grupo);
    }
    const responsaveis = [...new Set([...casosPorFornecedor.values()].map(grupo =>
      ordenarCasos(grupo)[0].responsavel).filter((id): id is string =>
      typeof id === "string" && !!id && !id.includes("/")))];
    const usuarios = responsaveis.length
      ? await db.getAll(...responsaveis.map(id => db.collection("usuarios").doc(id)),
        { fieldMask: ["nome", "nome_completo", "nomeCompleto", "display_name"] })
      : [];
    const nomes = new Map(usuarios.map(doc => [doc.id, nomeUsuarioDeDoc(doc.data())]));
    return medidas.map(doc => {
      const grupo = casosPorFornecedor.get(doc.id) ?? [];
      const primeiro = grupo[0];
      const medida = doc.data();
      return {
        idFornecedor: doc.id,
        casosAbertos: grupo.length,
        casosCriticos: grupo.filter(caso => caso.prioridade === "critica").length,
        semResponsavel: grupo.filter(caso => !caso.responsavel).length,
        eventoProximoEm: grupo.filter(caso => caso.eventoProximo)
          .map(caso => caso.dataEvento!).sort()[0] ?? null,
        responsavel: primeiro?.responsavel ? nomes.get(primeiro.responsavel) ?? null : null,
        casoPrioritarioAtribuido: !!primeiro?.responsavel,
        cotacoesVencidas: vencidas.get(doc.id) ?? 0,
        casosParciais: casos.size > limite,
        cotacoesParciais: participacoes.size > limite,
        restricao: medida && restricaoVigente(medida, instante)
          ? { acao: medida.acao, ate: medida.ate ?? null, servico: medida.servico ?? null } : null,
      };
    });
  }));
  return { fornecedores: fornecedores.flat() };
}

function resumoMedida(doc: DocumentSnapshot, agora: string) {
  const medida = doc.data();
  if (!medida) return null;
  const { ateTimestamp, ...dados } = medida;
  return { ...dados, vigente: restricaoVigente(medida, agora) };
}

export async function consultarFilaFornecedorAdmin(db: Firestore, agora = new Date()) {
  const [casos, recursos, medidas, descredenciados] = await Promise.all([
    db.collection(COL_CASOS).where("estado", "in", CASOS_ABERTOS).limit(151).get(),
    db.collection(MEDIDAS_FORNECEDOR).where("recurso.estado", "==", "pendente").limit(51).get(),
    db.collection(MEDIDAS_FORNECEDOR).where("ate", ">", agora.toISOString()).limit(51).get(),
    db.collection(MEDIDAS_FORNECEDOR).where("acao", "==", "descredenciar").limit(51).get(),
  ]);
  const casosAmostra = casos.docs.slice(0, 150);
  const recursosAmostra = recursos.docs.slice(0, 50);
  const medidasAmostra = [...medidas.docs.slice(0, 50), ...descredenciados.docs.slice(0, 50)];
  const ids = [...new Set([...casosAmostra.map(c => c.data().id_fornecedor), ...recursosAmostra.map(d => d.id),
    ...medidasAmostra.map(d => d.id)].filter((id): id is string => typeof id === "string" && !!id && !id.includes("/")))];
  const [eventos, fornecedores] = await Promise.all([
    carregarEventos(db, casosAmostra.map(c => c.data().id_evento)),
    ids.length ? db.getAll(...ids.map(id => db.collection("fornecedor").doc(id)), { fieldMask: ["razao_social"] }) : [],
  ]);
  const nomes = new Map(fornecedores.map(doc => [doc.id, doc.data()?.razao_social || "Fornecedor"]));
  return {
    casos: ordenarCasos(casosAmostra.map(c => ({ ...resumirCaso(c, eventos, agora),
      fornecedor: nomes.get(c.data().id_fornecedor) ?? "Fornecedor" }))),
    recursos: recursosAmostra.map(doc => ({ idFornecedor: doc.id, fornecedor: nomes.get(doc.id),
      acao: doc.data().acao, criadoEm: doc.data().recurso.criadoEm })),
    restricoes: medidasAmostra.map(doc => ({ idFornecedor: doc.id, fornecedor: nomes.get(doc.id),
      acao: doc.data().acao, ate: doc.data().ate, servico: doc.data().servico ?? null })),
    parcial: casos.size > 150 || recursos.size > 50 || medidas.size > 50 || descredenciados.size > 50,
  };
}

async function lerReputacao(db: Firestore, fornecedor: FirebaseFirestore.DocumentReference, de: string, ate: string) {
  return db.runTransaction(async tx => {
    const todos = await tx.get(fornecedor.collection("avaliacoes").limit(301));
    const amostra = todos.docs.slice(0, 300);
    const confiaveis = new Map((await registrosConfiaveis(tx, amostra)).map(a => [a.id, a]));
    const porData = amostra.map(doc => ({ doc, dados: doc.data() })).sort((a, b) =>
      (iso(b.dados.data) ?? "").localeCompare(iso(a.dados.data) ?? ""));
    const noPeriodo = (dados: FirebaseFirestore.DocumentData) => {
      const data = iso(dados.data);
      return data !== null && data >= de && data < ate;
    };
    const verificadas = porData.filter(({ doc, dados }) =>
      confiaveis.has(doc.id) && dados.moderacao !== "oculta" && noPeriodo(dados));
    const notas = verificadas.filter(({ dados }) => dados.tipo === "fornecedor").map(({ dados }) => Number(dados.nota));
    const meses = new Map<string, number[]>();
    for (const { dados } of verificadas.filter(a => a.dados.tipo === "fornecedor")) {
      const mes = iso(dados.data)!.slice(0, 7);
      const amostra = meses.get(mes) ?? [];
      amostra.push(Number(dados.nota));
      meses.set(mes, amostra);
    }
    const recentes = porData.filter(({ dados }) => dados.moderacao !== "oculta" &&
      (noPeriodo(dados) || !iso(dados.data))).slice(0, 30);
    const itens = await Promise.all(recentes.map(async ({ doc, dados }) => {
      const verificada = confiaveis.has(doc.id);
      const resposta = await tx.get(doc.ref.collection("respostas_publicas").doc("atual"));
      return { id: doc.id, nota: dados.nota ?? null, comentario: dados.comentario ?? "", data: iso(dados.data),
        tipo: dados.tipo ?? "legado", servico: verificada ? dados.nome_servico ?? dados.id_servico ?? null : null,
        verificada, resposta: resposta.data()?.texto ?? null };
    }));
    return { media: notas.length ? notas.reduce((a, b) => a + b, 0) / notas.length : null, quantidade: notas.length,
      distribuicao: [1, 2, 3, 4, 5].map(n => notas.filter(nota => nota === n).length),
      evolucao: [...meses.entries()].reverse().map(([mes, amostra]) =>
        ({ mes, quantidade: amostra.length, media: amostra.reduce((a, b) => a + b, 0) / amostra.length })),
      legadas: amostra.length - confiaveis.size, parcial: todos.size > 300, itens };
  }, { readOnly: true });
}

export async function consultarFornecedorAdmin(db: Firestore, idFornecedor: string, dias: number, agora = new Date()) {
  if (![30, 90, 365].includes(dias)) throw new HttpsError("invalid-argument", "Selecione 30, 90 ou 365 dias.");
  const fornecedor = db.collection("fornecedor").doc(idFornecedor);
  const medidaRef = db.collection(MEDIDAS_FORNECEDOR).doc(idFornecedor);
  const ate = agora.toISOString(), de = new Date(agora.getTime() - dias * DIA).toISOString();
  const cadastro = await fornecedor.get();
  if (!cadastro.exists) throw new HttpsError("not-found", "Fornecedor não encontrado.");
  const [atendimentos, orcamentos, reputacao, casos, medida, historico, vinculos] = await Promise.all([
    lerAtendimentosFornecedor(db, idFornecedor, 250).catch(() => null),
    db.collection("orcamento").where("id_fornecedor", "==", idFornecedor).limit(251).get(),
    lerReputacao(db, fornecedor, de, ate).catch(() => null),
    db.collection(COL_CASOS).where("id_fornecedor", "==", idFornecedor).limit(151).get(),
    medidaRef.get(), medidaRef.collection("historico").orderBy("criadoEm", "desc").limit(30).get(),
    db.collection("fornecedor_servico").where("id_fornecedor", "==", idFornecedor).limit(101).get(),
  ]);
  const servicos = new Map<string, string>();
  for (const doc of vinculos.docs.slice(0, 100)) {
    const vinculo = doc.data();
    const id = vinculo.id_produto_servico;
    if (typeof id === "string" && id && !id.includes("/")) servicos.set(id, vinculo.nome_produto_servico || id);
  }
  const orcamentosAmostra = orcamentos.docs.slice(0, 250);
  const casosAmostra = casos.docs.slice(0, 150);
  const [catalogo, eventos] = await Promise.all([
    servicos.size ? db.getAll(...[...servicos.keys()].map(id => db.collection("servico_produto").doc(id)), { fieldMask: ["nome"] }) : [],
    carregarEventos(db, [...orcamentosAmostra, ...casosAmostra].map(d => d.data().id_evento)),
  ]);
  for (const doc of catalogo) {
    const nome = doc.data()?.nome;
    if (typeof nome === "string" && nome.trim()) servicos.set(doc.id, nome);
  }
  const porIdentidade = new Map<string, QueryDocumentSnapshot>();
  for (const doc of orcamentosAmostra) {
    const x = doc.data();
    const id = x.contrato_financeiro?.id_contrato || (x.id_cotacao ? `legado-cotacao:${x.id_cotacao}` : doc.id);
    if (!contratado(x) && !(x.contrato_financeiro?.id_contrato &&
        [x.status, x.contrato_financeiro?.estado_comercial].some(v => ["cancelado", "cancelada", "estornado"].includes(v)))) continue;
    if (!porIdentidade.has(id) || doc.id === id) porIdentidade.set(id, doc);
  }
  const contratos = [...porIdentidade.entries()].map(([identidade, doc]) => {
    const x = doc.data();
    const execucao = x.contrato_financeiro?.estado_execucao || x.estado_execucao || null;
    const evento = dadosEvento(eventos.get(x.id_evento));
    const cancelado = !contratado(x) || execucao === "cancelado_execucao";
    const horas = evento.dataEvento ? (Date.parse(evento.dataEvento) - agora.getTime()) / 3600000 : null;
    const proximo = !cancelado && execucao !== "aceito" && !evento.eventoCancelado &&
      horas !== null && horas >= -24 && horas <= 168;
    return { identidade, idOrcamento: doc.id, idCotacao: x.id_cotacao ?? null, execucao, cancelado, proximo,
      aceite: iso(x.proposta_aceita?.aceito_em) || iso(x.data_fechamento) || iso(x.contrato_financeiro?.snapshot_identidade?.capturado_em),
      servico: x.nome_servico_contratado || x.nome || "Serviço contratado", ...evento };
  });
  const metricas = atendimentos ? metricasAtendimentos(atendimentos.itens, contratos, idFornecedor, de, ate, ate) : null;
  const execucao = metricasAtendimentos([], contratos, idFornecedor, de, ate, ate);
  const coorte = atendimentos?.itens.filter(a => a.envio && a.envio >= de && a.envio < ate) ?? [];
  const comparaveis = coorte.flatMap(a => {
    const horas = primeiraRespostaHoras(a, idFornecedor, ate);
    return horas === null || !a.prazoInicial ? [] : [{ horas, prazo: (Date.parse(a.prazoInicial) - Date.parse(a.envio)) / 3600000 }];
  });
  const vencidas = atendimentos?.itens.filter(a => !a.parentCancelada &&
    aguardaFornecedor(a.comercial, a.responsavel) && a.prazo && a.prazo < ate);
  const contratosExibidos = contratos.filter(c => c.proximo || (c.aceite ?? "") >= de).sort((a, b) =>
    Number(b.proximo) - Number(a.proximo) || (a.proximo ? (a.dataEvento ?? "").localeCompare(b.dataEvento ?? "") :
      (b.aceite ?? "").localeCompare(a.aceite ?? "")));
  const detalhesContratos = await Promise.all(contratosExibidos.slice(0, 40).map(async contrato => {
    if (!contrato.cancelado) return contrato;
    const doc = porIdentidade.get(contrato.identidade)!;
    const historicoFinanceiro = doc.data().contrato_financeiro?.historico;
    const comercial = Array.isArray(historicoFinanceiro)
      ? [...historicoFinanceiro].reverse().find(r => r?.tipo === "cancelamento") : null;
    if (comercial) return { ...contrato, cancelamento: { motivo: comercial.motivo ?? null, data: iso(comercial.em) } };
    const execucao = await doc.ref.collection("execucao_historico").where("estado_novo", "==", "cancelado_execucao").limit(2).get();
    const registro = execucao.size === 1 ? execucao.docs[0].data() : null;
    return { ...contrato, cancelamento: registro ? { motivo: registro.motivo ?? null, data: iso(registro.criado_em),
      registradoPor: registro.papel ?? null } : null };
  }));
  return { idFornecedor, nome: cadastro.data()?.razao_social || "Fornecedor", de, ate, reputacao,
    atendimento: metricas && { ...metricas, noPrazo: comparaveis.filter(r => r.horas <= r.prazo).length,
      amostraPrazo: comparaveis.length, vencidas: vencidas?.length ?? 0,
      parcial: atendimentos?.parcial || orcamentos.size > 250 },
    execucao: { contratacoes: execucao.contratacoes, cancelados: execucao.contratosCancelados, aceitos: execucao.concluidas,
      semDataAceite: execucao.contratosSemDataAceite, parcial: orcamentos.size > 250 },
    contratos: detalhesContratos, contratosExibidosParciais: contratosExibidos.length > 40,
    casos: ordenarCasos(casosAmostra.map(doc => resumirCaso(doc, eventos, agora))),
    casosParciais: casos.size > 150, medida: resumoMedida(medida, ate),
    servicos: [...servicos.entries()].map(([id, nome]) => ({ id, nome })).sort((a, b) => a.nome.localeCompare(b.nome)),
    servicosParciais: vinculos.size > 100,
    historico: historico.docs.map(doc => { const { assinatura, ...dados } = doc.data(); return dados; }),
  };
}

const config = { region: "southamerica-east1", timeoutSeconds: 120 };
export const consultarFilaFornecedorAdminFn = onCall(config, async req => {
  exigirTipo(await exigirUsuarioAutenticado(req.auth?.uid), ["A"]);
  return consultarFilaFornecedorAdmin(admin.firestore());
});
export const consultarFornecedorAdminFn = onCall(config, async req => {
  exigirTipo(await exigirUsuarioAutenticado(req.auth?.uid), ["A"]);
  return consultarFornecedorAdmin(admin.firestore(), idJornada(req.data?.idFornecedor), req.data?.dias ?? 90);
});
export const consultarTriagemFornecedoresAdminFn = onCall(config, async req => {
  exigirTipo(await exigirUsuarioAutenticado(req.auth?.uid), ["A"]);
  const ids = req.data?.ids;
  if (!Array.isArray(ids) || ids.length > 120) {
    throw new HttpsError("invalid-argument", "Informe até 120 fornecedores por consulta.");
  }
  return consultarTriagemFornecedoresAdmin(admin.firestore(), [...new Set<string>(ids.map(idJornada))]);
});
