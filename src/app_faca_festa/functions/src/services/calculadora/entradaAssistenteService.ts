import { validarPoliticaPublico } from "./publicoPlanejamentoService";
import { createHash, randomUUID } from "crypto";
import { Firestore, Transaction, Query, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { normalizarFonte } from "./executarPlanoService";

export type Dados = Record<string, any>;
export const mapa = (v: any): Dados => v && typeof v === "object" && !Array.isArray(v) ? v : {};
export const normal = (s: any): string => String(s ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");
function canon(v: any): string {
  if (Array.isArray(v)) return `[${v.map(canon).join(",")}]`;
  if (v && typeof v === "object") return `{${Object.keys(v).sort().map(k => `${JSON.stringify(k)}:${canon(v[k])}`).join(",")}}`;
  return JSON.stringify(v ?? null);
}
export const hashEntrada = (v: any): string => createHash("sha256").update(canon(v)).digest("hex");
const erro = (s: string): never => { throw new HttpsError("failed-precondition", s); };
const id = (s: any): s is string => typeof s === "string" && /^[^/]{1,200}$/.test(s);
function numero(n: any, positivo = false): number {
  if (typeof n !== "number" || !Number.isFinite(n) || n < (positivo ? Number.MIN_VALUE : 0) || n > 1000000) erro("Quantidade ou valor inválido.");
  return n;
}
const unidades = ["kg", "L", "un", "cento", "garrafa", "pacote"];
const estados = ["cru", "seco", "pronto", "não se aplica"];
const rotulos: Dados = { publico: "Público", base: "Fonte do público", duracao: "Duração", perfil: "Perfil", limite: "Limite da festa", margem: "Margem extra", verba: "Verba alimentar", quantidade: "Quantidade final planejada", preco: "Preço por unidade", compra_adicionar: "Adicionar compra já realizada", compra_total: "Total já comprado", estoque: "Cadastrar lote disponível", cotacao: "Registrar cotação", despesa: "Registrar despesa", pagamento: "Registrar pagamento já realizado", receita: "Ingredientes da receita" };

export async function lerFontesEntrada(db: Firestore, tx: Transaction, evento: string, uid: string, incluirTarefas=false): Promise<Dados> {
  const ev = await tx.get(db.doc(`evento/${evento}`));
  if (ev.data()?.id_usuario !== uid) throw new HttpsError("permission-denied", "Somente o organizador pode revisar esta entrada.");
  const fontes: Dados = { [ev.ref.path]: ev.data() };
  const op = await tx.get(db.doc(`calculadora_operacao/${evento}`));
  if (op.data()?.versao != null && op.data()?.versao !== 1) erro("Atualize o leitor antes de alterar esta operação.");
  fontes[op.ref.path] = op.data() ?? null;
  async function consulta(q: Query, max: number) {
    const result = await tx.get(q.limit(max + 1));
    if (result.size > max) erro("Há muitos registros para uma revisão conjunta.");
    for (const d of result.docs) fontes[d.ref.path] = d.data();
    if (Object.keys(fontes).length > 240) erro("Há muitos registros para uma revisão conjunta.");
    return result.docs;
  }
  const menus = await consulta(db.collection("cardapios").where("id_evento", "==", evento), 20);
  for (const m of menus) if (m.data().ativo !== false) await consulta(m.ref.collection("itens"), 60);
  const budgets = await consulta(db.collection("orcamento").where("id_evento", "==", evento), 40);
  for (const b of budgets) await consulta(b.ref.collection("orcamento_gasto"), 40);
  await consulta(db.collection("convidado").where("id_evento", "==", evento), 120);
  if(incluirTarefas) await consulta(db.collection("tarefa").where("id_evento","==",evento),100);
  return fontes;
}

export function validarAcoesEntrada(raw: Dados, fontes: Dados, regras: Dados[], evento: string): Dados {
  if (!Array.isArray(raw.acoes) || raw.acoes.length > 30) erro("A resposta excede o limite de ações.");
  const perguntas: string[] = Array.isArray(raw.perguntas) ? raw.perguntas.filter((p: any) => typeof p === "string").map((p: string) => p.slice(0, 350)).filter((p: string) => {
    // New quotes have no optional budget-link/status decision in this operation.
    const q = normal(p);
    return !(q.includes("cotacao") && /associ|vincul|rascunho|ativa/.test(q)) &&
      !(/registrar_o_fornecedor|registrar_fornecedor/.test(q) && q.includes("exatamente"));
  }).slice(0, 20) : [];
  const validas: Dados[] = [], ids = new Set<string>(), destinos = new Set<string>();
  const op = mapa(fontes[`calculadora_operacao/${evento}`]);
  for (const entrada of raw.acoes) {
    const a = { ...mapa(entrada) };
    try {
      if (!/^[a-zA-Z0-9_-]{1,40}$/.test(a.id) || ids.has(a.id) || !rotulos[a.tipo] || typeof a.evidencia !== "string" || !a.evidencia.trim()) erro("Ação sem identificação ou evidência.");
      if (mapa(raw.documento).tipo === "cotacao" && !["cotacao", "preco"].includes(a.tipo)) erro("Cotação não comprova compra, despesa ou pagamento. Confirme esses fatos separadamente.");
      ids.add(a.id);
      const path = `cardapios/${a.id_cardapio}/itens/${a.id_item}`, item = fontes[path];
      const usaItem = ["quantidade", "preco", "compra_adicionar", "compra_total", "estoque", "receita"].includes(a.tipo);
      if (usaItem && (!item || fontes[`cardapios/${a.id_cardapio}`]?.id_evento !== evento)) erro("Selecione o item e a refeição correspondentes.");
      if (usaItem) {
        if (!unidades.includes(a.unidade) || !estados.includes(a.estado)) erro("Confirme unidade e estado (cru, seco ou pronto).");
        const adotar = item.unidade === "un" && Number(item.quantidade_final ?? 0) === 0 && Number(item.quantidade_sugerida ?? 0) === 0 && !item.confirmado && !item.disponibilidade;
        if (item.unidade !== a.unidade && !adotar) erro("A unidade não corresponde ao item. Não há conversão automática de medida.");
        a.nome = item.nome; a.path = path; a.adotar_unidade = item.unidade !== a.unidade;
      }
      if (["quantidade", "compra_adicionar", "compra_total", "estoque"].includes(a.tipo)) numero(a.quantidade, a.tipo === "compra_adicionar" || a.tipo === "estoque");
      if (["preco", "cotacao", "despesa", "pagamento", "limite"].includes(a.tipo)) numero(a.valor, true);
      if (a.tipo === "publico") {
        for (const k of ["adultos", "criancas", "bebes"]) if (!Number.isInteger(a[k]) || numero(a[k]) > 1000000) erro("Informe pessoas inteiras por faixa etária.");
      }
      if (a.tipo === "base" && !["confirmados", "nao_recusados", "previstos", "todos"].includes(a.nome)) erro("Escolha uma fonte de convidados.");
      if (a.tipo === "perfil" && !["economico", "padrao", "premium"].includes(a.nome)) erro("Escolha o perfil da festa.");
      if (a.tipo === "margem" && (typeof a.valor !== "number" || !Number.isFinite(a.valor) || a.valor < 0 || a.valor > .3)) erro("Informe margem entre 0 e 30% como fração.");
      if (a.tipo === "verba") numero(a.valor);
      if (a.tipo === "duracao" && (!Number.isInteger(a.quantidade) || a.quantidade < 1 || a.quantidade > 24)) erro("Informe de 1 a 24 horas.");
      if (["compra_adicionar", "compra_total"].includes(a.tipo) && item.disponibilidade) {
        const d = item.disponibilidade;
        if (d.estado !== a.estado || d.unidade !== a.unidade || d.nome !== item.nome || d.publico !== (item.publico_alvo ?? "todos")) erro("Confira a disponibilidade anterior; medida, nome ou público mudaram.");
        numero(d.comprado); numero(d.estoque);
        a.anterior = d.comprado;
      }
      if (a.tipo === "preco" || a.tipo === "receita") {
        const r = regras.find(r => r.premissas?.id_cardapio === a.id_cardapio && r.premissas?.id_item_cardapio === a.id_item);
        if (!r) throw new HttpsError("failed-precondition", "Defina uma porção antes de associar preço ou receita.");
        const unit: Dados = { quilo: "kg", litro: "L", unidade: "un", cento: "cento", garrafa: "garrafa", pacote: "pacote" };
        if (!r || normal(r.nome) !== normal(item.nome) || unit[r.unidade] !== a.unidade ||
            (r.premissas.estado_compra ?? r.premissas.estado) !== a.estado || numero(r.consumo, true) <= 0) erro("Defina uma porção com a mesma medida antes de associar preço ou receita.");
        if (r.id !== `menu_${a.id_cardapio}_${a.id_item}` || !["comida", "bebida", "bolo", "sobremesa", "descartavel", "outro"].includes(r.categoria) ||
            typeof r.tipo !== "string" || !["todos", "adultos", "criancas", "bebes"].includes(r.publico) || r.publico !== (item.publico_alvo ?? "todos") ||
            (r.premissas.id_evento && r.premissas.id_evento !== evento)) erro("A regra não pertence a este contexto de planejamento.");
        numero(r.preco ?? 0);
        a.regra = r;
        if (a.tipo === "receita") {
          const f = mapa(a.receita);
          numero(f.rendimento, true);
          if (f.unidade !== a.unidade || f.estado !== a.estado || !Array.isArray(f.ingredientes) || f.ingredientes.length < 1 || f.ingredientes.length > 20) erro("Informe rendimento e ingredientes na medida da receita.");
          f.ingredientes.forEach((i: Dados) => {
            numero(i.quantidade, true);
            if (!String(i.nome ?? "").trim() || !unidades.includes(i.unidade) || !estados.includes(i.estado)) erro("Confira nome, quantidade, unidade e estado dos ingredientes.");
          });
        }
      }
      if (["cotacao", "despesa"].includes(a.tipo) && (typeof a.nome !== "string" || !a.nome.trim())) erro("Identifique a despesa ou cotação.");
      if (a.tipo === "pagamento" && !String(a.id_orcamento ?? "").startsWith("nova:")) {
        const b = fontes[`orcamento/${a.id_orcamento}`];
        if (!b || b.id_evento !== evento || b.ativo === false || b.deletado === true || ["cancelado", "cancelada"].includes(b.status)) erro("Selecione um orçamento ativo para vincular o pagamento.");
      }
      const destino = [a.tipo === "base" ? "publico" : a.tipo.startsWith("compra_") ? "compra" : a.tipo, usaItem ? path : a.tipo === "pagamento" ? a.id_orcamento : ["despesa", "cotacao"].includes(a.tipo) ? normal(a.nome) : ""].join("|");
      if (destinos.has(destino)) erro("Há mais de uma definição para o mesmo destino. Consolide as linhas antes de aplicar.");
      destinos.add(destino);
      const valor = a.tipo === "publico" ? `${a.adultos} adultos, ${a.criancas} crianças, ${a.bebes} bebês` :
        a.tipo === "margem" ? `${(a.valor * 100).toFixed(1)}%` : a.valor != null ? `R$ ${a.valor.toFixed(2).replace(".", ",")}${a.tipo === "preco" ? `/${a.unidade}` : ""}` :
          a.quantidade != null ? `${a.quantidade} ${a.unidade ?? "h"}` : a.nome ?? "";
      a.descricao = `${rotulos[a.tipo]}${usaItem ? ` · ${fontes[`cardapios/${a.id_cardapio}`]?.titulo} · ${item.nome}` : ""}: ${valor}${usaItem ? ` (${a.estado})` : ""}`;
      if (a.tipo === "compra_adicionar") a.descricao += `; total comprado: ${Number(a.anterior ?? 0) + a.quantidade} ${a.unidade}. Não registra pagamento.`;
      if (a.tipo === "compra_total") a.descricao += "; substitui apenas a quantidade já comprada registrada, sem pagamento.";
      if (a.tipo === "estoque") a.descricao += "; novo lote central, ainda sem reserva.";
      if (a.tipo === "cotacao") a.descricao += "; em negociação, sem contratação ou pagamento.";
      if (a.tipo === "despesa") a.descricao += "; custo realizado, pagamento separado.";
      if (a.tipo === "pagamento" && fontes[`orcamento/${a.id_orcamento}`]) a.descricao += `; orçamento: ${fontes[`orcamento/${a.id_orcamento}`].nome ?? fontes[`orcamento/${a.id_orcamento}`].anotacoes ?? a.id_orcamento}.`;
      if (a.adotar_unidade) a.descricao += `; unidade inicial ${item.unidade} → ${a.unidade}.`;
      validas.push(a);
    } catch (e) { perguntas.push(`${a.nome ?? a.tipo ?? "Entrada"}: ${e instanceof Error ? e.message : "confira os dados"}`); }
  }
  return { resumo: String(raw.resumo ?? "Confira as propostas extraídas.").slice(0, 500), acoes: validas, perguntas,
    documento: mapa(raw.documento), revisao: op.revisao ?? 0 };
}

export async function prepararEntradaAssistente(db: Firestore, uid: string | undefined, dados: Dados,
    extrair: (contexto: Dados) => Promise<Dados>): Promise<Dados> {
  if (!uid) throw new HttpsError("unauthenticated", "Entre na sua conta.");
  const evento = dados.evento;
  if (!id(evento) || typeof dados.texto !== "string" || dados.texto.length > 16000 || !Array.isArray(dados.regras) || dados.regras.length > 60) throw new HttpsError("invalid-argument", "Entrada inválida.");
  const anexo = mapa(dados.anexo);
  if (Object.keys(anexo).length && (!/^(application\/pdf|image\/png|image\/jpeg|image\/webp)$/.test(anexo.mime) || typeof anexo.base64 !== "string" || anexo.base64.length > 5600000)) erro("Use PDF, PNG, JPEG ou WebP de até 4 MB.");
  if (!dados.texto.trim() && !anexo.base64) erro("Descreva seu pedido ou selecione um documento.");
  const fontes = await db.runTransaction(tx => lerFontesEntrada(db, tx, evento, uid));
  const documentoEntrada = !!anexo.base64 || dados.documento === true;
  if (anexo.base64) {
    if (!/^[A-Za-z0-9+/]+={0,2}$/.test(anexo.base64)) erro("Arquivo inválido.");
    const bytes = Buffer.from(anexo.base64, "base64");
    const ok = anexo.mime === "application/pdf" ? bytes.subarray(0, 5).toString() === "%PDF-" :
      anexo.mime === "image/png" ? bytes.subarray(0, 4).equals(Buffer.from([137, 80, 78, 71])) :
        anexo.mime === "image/jpeg" ? bytes[0] === 255 && bytes[1] === 216 : bytes.subarray(0, 4).toString() === "RIFF" && bytes.subarray(8, 12).toString() === "WEBP";
    if (!ok || bytes.length > 4194304) erro("O conteúdo não corresponde ao tipo ou limite do arquivo.");
  }
  const original = hashEntrada(anexo.base64 ? { anexo: anexo.base64 } : { texto: dados.texto.trim(), contexto: documentoEntrada ? null : hashEntrada(normalizarFonte(fontes)) });
  const root = db.doc(`calculadora_operacao/${evento}`);

  const contexto = { itens: Object.entries(fontes).filter(([p]) => p.startsWith("cardapios/")).map(([path, value]) => ({ path, id_cardapio: path.split('/')[1], ...(path.split('/').length === 4 ? { id_item: path.split('/')[3] } : {}),
      nome: value.nome ?? value.titulo ?? "", unidade: value.unidade ?? null, publico: value.publico_alvo ?? null })),
    orcamentos: Object.entries(fontes).filter(([p]) => /^orcamento\/[^/]+$/.test(p)).map(([path, value]) => ({ path, id_orcamento: path.split('/')[1], nome: value.nome, custo_estimado: value.custo_estimado ?? 0, status: value.status ?? null })),
    regras: dados.regras, texto: dados.texto, texto_documental: dados.documento === true, anexo };
  const extraido = await extrair(contexto);
  const proposta = validarAcoesEntrada(extraido, fontes, dados.regras, evento);
  const doc = proposta.documento;
  const identidade = doc.numero && doc.emissor ? hashEntrada({ tipo: doc.tipo, numero: normal(doc.numero), emissor: normal(doc.emissor) }) : null;
  const anteriores: Dados = {};
  const previstas = new Set<string>();
  for (const h of [...new Set([original, identidade].filter(Boolean))] as string[]) {
    const registro = (await root.collection("documentos").doc(h).get()).data();
    Object.assign(anteriores, mapa(registro?.acoes));
    for (const fp of registro?.previstas ?? []) previstas.add(fp);
  }
  const acoesOriginais = [...proposta.acoes] as Dados[];
  for (const a of acoesOriginais) {
    const refNova = a.tipo === "pagamento" && String(a.id_orcamento).startsWith("nova:") ?
      acoesOriginais.find(x => x.id === a.id_orcamento.slice(5) && x.tipo === "despesa") : null;
    const budgetNome = refNova?.nome ?? fontes[`orcamento/${a.id_orcamento}`]?.nome ?? a.id_orcamento;
    const item = ["quantidade", "preco", "compra_adicionar", "compra_total", "estoque", "receita"].includes(a.tipo);
    a.fingerprint = hashEntrada({ tipo: a.tipo, cardapio: item ? a.id_cardapio : null, item: item ? a.id_item : null,
      destino: a.tipo === "pagamento" ? normal(budgetNome) : normal(a.nome),
      unidade: item ? a.unidade : null, estado: item ? a.estado : null, quantidade: item || a.tipo === "duracao" ? a.quantidade : null, valor: a.valor,
      adultos: a.tipo === "publico" ? a.adultos : null, criancas: a.tipo === "publico" ? a.criancas : null, bebes: a.tipo === "publico" ? a.bebes : null, receita: a.tipo === "receita" ? a.receita : null });
  }
  for (const a of acoesOriginais) {
    if (a.tipo === "pagamento" && String(a.id_orcamento).startsWith("nova:")) {
      const dep = acoesOriginais.find(x => x.id === a.id_orcamento.slice(5) && x.tipo === "despesa");
      if (dep && anteriores[dep.fingerprint]?.orcamento) a.id_orcamento = anteriores[dep.fingerprint].orcamento;
    }
  }
  proposta.acoes = acoesOriginais.filter(a => !anteriores[a.fingerprint]);
  proposta.ja_registradas = acoesOriginais.length - proposta.acoes.length;
  proposta.acoes = proposta.acoes.filter((a: Dados) => {
    if (documentoEntrada && Object.keys(anteriores).length && ["cotacao", "despesa", "pagamento"].includes(a.tipo) && !previstas.has(a.fingerprint)) {
      proposta.perguntas.push(`${a.nome ?? "Documento"}: a extração financeira mudou em um documento já lançado. Confira o registro existente antes de acrescentar outro valor.`);
      return false;
    }
    const duplicada = ["cotacao", "despesa"].includes(a.tipo) && Object.entries(fontes).some(([path, b]) =>
      /^orcamento\/[^/]+$/.test(path) && b.ativo !== false && b.deletado !== true && normal(b.nome) === normal(a.nome) &&
      Number(b.custo_real ?? b.custo_estimado ?? 0) === a.valor);
    if (duplicada) proposta.perguntas.push(`${a.nome}: já há um orçamento com esse nome e valor. Confira o registro existente antes de criar outro.`);
    return !duplicada;
  });
  const pedido = randomUUID(), assinatura = hashEntrada({ proposta, original, fontes: normalizarFonte(fontes) });
  const persistido = { ...proposta, documento_entrada: documentoEntrada, id: pedido, assinatura, original, identidade,
    fontes_hash: hashEntrada(normalizarFonte(fontes)), criado_em: Timestamp.now(), id_usuario: uid,
    expira_em: Date.now() + 30 * 60 * 1000 };
  if (Buffer.byteLength(JSON.stringify(persistido), "utf8") > 650000) erro("A revisão ficou muito grande. Separe o documento.");
  await root.collection("entradas").doc(pedido).create(persistido);
  return { id: pedido, assinatura, resumo: proposta.resumo,
    acoes: proposta.acoes.map((a: Dados) => ({ id: a.id, tipo: a.tipo, descricao: a.descricao, evidencia: a.evidencia.slice(0, 500), receita: a.tipo === "receita" ? a.receita : null })),
    perguntas: proposta.perguntas, documento: proposta.documento, ja_registradas: proposta.ja_registradas,
    aviso_duplicidade: documentoEntrada && !identidade ? "Documento sem identificação única. Confira se já foi registrado por outro arquivo ou manualmente." : null };
}

export async function aplicarEntradaAssistente(db: Firestore, uid: string | undefined, dados: Dados): Promise<Dados> {
  if (!uid) throw new HttpsError("unauthenticated", "Entre na sua conta.");
  if (!id(dados.evento) || !id(dados.id) || !Array.isArray(dados.selecionadas) || dados.selecionadas.length < 1 || dados.selecionadas.length > 30 || new Set(dados.selecionadas).size !== dados.selecionadas.length) throw new HttpsError("invalid-argument", "Selecione as ações revisadas.");
  const root = db.doc(`calculadora_operacao/${dados.evento}`), ref = root.collection("entradas").doc(dados.id);
  return db.runTransaction(async tx => {
    const evento = await tx.get(db.doc(`evento/${dados.evento}`));
    if (evento.data()?.id_usuario !== uid) throw new HttpsError("permission-denied", "Somente o organizador pode revisar esta entrada.");
    const salvo = mapa((await tx.get(ref)).data());
    if (!salvo || salvo.id_usuario !== uid || salvo.assinatura !== dados.assinatura) erro("Revisão não encontrada ou incompatível.");
    if (salvo.aplicado_em) {
      if (hashEntrada(salvo.selecionadas) !== hashEntrada(dados.selecionadas)) erro("O pedido já foi aplicado com outra seleção.");
      return { aplicado: false, operacao: mapa((await tx.get(root)).data()), limite_atual: (salvo.acoes as Dados[]).some(a => dados.selecionadas.includes(a.id) && a.tipo === "limite") ? evento.data()?.custo_estimado : null, regras_alteradas: (salvo.acoes as Dados[]).filter(a => dados.selecionadas.includes(a.id) && a.regra).map(a => a.regra.id) };
    }
    const fontes = await lerFontesEntrada(db, tx, dados.evento, uid);
    if (salvo.expira_em < Date.now()) erro("A revisão expirou. Leia a entrada novamente.");
    if (hashEntrada(normalizarFonte(fontes)) !== salvo.fontes_hash) erro("Os dados mudaram. Leia a entrada novamente antes de aplicar.");
    const hashes = [...new Set([salvo.original, salvo.identidade].filter(Boolean))] as string[];
    const registros: Dados = {};
    const acoesAnteriores: Dados = {};
    for (const h of hashes) {
      registros[h] = mapa((await tx.get(root.collection("documentos").doc(h))).data());
      Object.assign(acoesAnteriores, mapa(registros[h].acoes));
    }
    const acoes = (salvo.acoes as Dados[]).filter(a => dados.selecionadas.includes(a.id));
    if (acoes.length !== dados.selecionadas.length) erro("A seleção contém ação desconhecida.");
    if (acoes.some(a => acoesAnteriores[a.fingerprint])) erro("Uma ação deste documento já foi registrada. Leia novamente para obter somente as restantes.");
    if (salvo.documento_entrada && !salvo.identidade && dados.conferiu_duplicidade !== true) erro("Confira se o documento sem identificação já foi lançado antes de aplicar.");
    const op = { ...mapa(fontes[root.path]) }, config = { ...mapa(op.configuracao_planejamento) };
    const rules: Dados[] = [...(mapa(op.execucao).regras ?? [])].map(r => ({ ...r, premissas: { ...r.premissas } }));
    const patches: Dados = {}, novos: Dados = {}, lotes = { ...mapa(op.lotes) };
    const despesaId = (action: string) => `entrada_${dados.id}_${action}`;
    const tocar = (path: string, patch: Dados) => patches[path] = { ...mapa(patches[path]), ...patch };
    for (const a of acoes) {
      const item = fontes[a.path];
      if (a.adotar_unidade) tocar(a.path, { unidade: a.unidade });
      switch (a.tipo) {
        case "publico": config.publico = { adultos: a.adultos, criancas: a.criancas, bebes: a.bebes }; config.base = "manual"; config.base_confirmada = true; break;
        case "base": config.base = a.nome; config.base_confirmada = true; break;
        case "margem": config.margem = a.valor; break;
        case "verba": config.verba_alimentacao = a.valor; config.verba_confirmacao={versao:1,valor:a.valor,fonte:"organizador",confirmado_por:uid,confirmado_em:new Date().toISOString()}; break;
        case "duracao": config.duracao = a.quantidade; break;
        case "perfil": config.perfil = a.nome; break;
        case "limite": tocar(`evento/${dados.evento}`, { custo_estimado: a.valor }); break;
        case "quantidade": tocar(a.path, { quantidade_final: a.quantidade }); break;
        case "compra_adicionar": case "compra_total": {
          const d = mapa(item.disponibilidade);
          const comprado = a.tipo === "compra_total" ? a.quantidade : Number(d.comprado ?? 0) + a.quantidade;
          numero(comprado);
          tocar(a.path, { disponibilidade: { nome: item.nome, unidade: a.unidade, estado: a.estado,
            publico: item.publico_alvo ?? "todos", comprado, estoque: Number(d.estoque ?? 0) } }); break;
        }
        case "estoque": lotes[despesaId(a.id)] = { nome: item.nome, total: a.quantidade, unidade: a.unidade, estado: a.estado, reservas: {} }; break;
        case "preco": case "receita": {
          const base = { ...a.regra, premissas: { ...a.regra.premissas, id_evento: dados.evento } };
          if (a.tipo === "preco") {base.preco = a.valor;Object.assign(base.premissas,{preco_unidade:a.unidade,preco_estado:a.estado,preco_fonte:"organizador",preco_confirmado_em:new Date().toISOString()});}
          else base.premissas.ficha_tecnica = { versao: 1, prato: item.nome, ...a.receita,
            ingredientes: a.receita.ingredientes.map((i: Dados, n: number) => ({ ...i, id: `entrada_${n}` })) };
          const index = rules.findIndex(r => r.id === base.id);
          if (index >= 0) rules[index] = { ...rules[index], ...(a.tipo === "preco" ? { preco: a.valor, premissas:base.premissas } : { premissas: { ...rules[index].premissas, ficha_tecnica: base.premissas.ficha_tecnica } }) };
          else rules.push(base);
          break;
        }
        case "cotacao": case "despesa": {
          const budget = despesaId(a.id), atual = a.tipo === "despesa";
          novos[`orcamento/${budget}`] = { id_orcamento: budget, id_evento: dados.evento,
            id_solicitante: uid, id_servico_fornecido: "", nome: a.nome, custo_estimado: a.valor,
            ...(atual ? { custo_real: a.valor } : {}), status: atual ? "fechado" : "em_negociacao",
            orcamento_fechado: atual, data_cadastro: Timestamp.now(), anotacoes: a.nome, calculadora_entrada: dados.id };
          novos[`orcamento/${budget}/orcamento_gasto/entrada`] = { id_gasto: "entrada", id_orcamento: budget, id_evento: dados.evento,
            nome: a.nome, descricao: a.nome, custo: a.valor, pago: 0, data_cadastro: Timestamp.now() }; break;
        }
      }
    }
    validarPoliticaPublico(config);
    const limiteConfiguracao = patches[`evento/${dados.evento}`]?.custo_estimado ?? fontes[`evento/${dados.evento}`]?.custo_estimado;
    if (config.verba_alimentacao != null && limiteConfiguracao != null && config.verba_alimentacao > limiteConfiguracao) erro("A verba deve caber no limite total do evento.");
    for (const a of acoes.filter(a => a.tipo === "pagamento")) {
      const nova = String(a.id_orcamento).startsWith("nova:");
      const budget = nova ? despesaId(a.id_orcamento.slice(5)) : a.id_orcamento;
      const path = `orcamento/${budget}`, b = novos[path] ?? fontes[path];
      if (!b || (nova && !acoes.some(x => x.id === a.id_orcamento.slice(5) && x.tipo === "despesa"))) erro("Selecione também a despesa correspondente ao pagamento.");
      const filhos = { ...fontes, ...novos };
      const linhas = Object.entries(filhos).filter(([p]) => p.startsWith(`${path}/orcamento_gasto/`)).sort(([a], [b]) => a.localeCompare(b));
      const gastos = linhas.map(([, g]) => g);
      numero(b.custo_real ?? 0); numero(b.custo_estimado ?? 0);
      for (const g of gastos) {
        numero(g.custo ?? 0); numero(g.pago ?? 0);
        if (Number(g.pago ?? 0) > Number(g.custo ?? 0) + 1e-6) erro("Há uma despesa com pagamento superior ao custo. Confira o financeiro antes de registrar outro pagamento.");
      }
      const custo = Math.max(b.custo_real ?? 0, b.custo_estimado ?? 0, gastos.reduce((s, g) => s + Number(g.custo ?? 0), 0));
      const pago = b.pago === true ? custo : gastos.reduce((s, g) => s + Number(g.pago ?? 0), 0);
      if (!Number.isFinite(custo) || !Number.isFinite(pago) || pago + a.valor > custo + 1e-6) erro("O pagamento excede o custo ainda não pago. Confira o orçamento e pagamentos anteriores.");
      // A payment belongs to an expense; a zero-cost paid row is incompatible
      // with the finance editor, whose invariant is 0 <= paid <= cost.
      let restante = a.valor;
      for (const [linha, gasto] of linhas) {
        const parte = Math.min(restante, Math.max(0, Number(gasto.custo ?? 0) - Number(gasto.pago ?? 0)));
        if (parte <= 0) continue;
        const patch = { pago: Number(gasto.pago ?? 0) + parte, calculadora_entrada: dados.id };
        if (novos[linha]) novos[linha] = { ...novos[linha], ...patch };
        else tocar(linha, patch);
        restante -= parte;
      }
      if (restante > 1e-6) {
        const semDetalhe = custo - gastos.reduce((s, g) => s + Number(g.custo ?? 0), 0);
        if (semDetalhe + 1e-6 < restante) erro("Confira a distribuição dos pagamentos nas despesas existentes.");
        const gastoId = despesaId(a.id), nome = b.nome ?? b.anotacoes ?? "Despesa do orçamento";
        novos[`${path}/orcamento_gasto/${gastoId}`] = { id_gasto: gastoId, id_orcamento: budget, id_evento: dados.evento,
          nome, descricao: nome, custo: semDetalhe, pago: restante, calculadora_entrada: dados.id, data_cadastro: Timestamp.now() };
      }
    }
    if (Object.keys(lotes).length > 100 || rules.length > 60) erro("O conjunto excede o limite de lotes ou regras.");
    if (Object.keys(patches).length + Object.keys(novos).length + hashes.length + 2 > 450) erro("Há muitas despesas para atualizar juntas. Divida os pagamentos em entradas menores.");
    const resultado = { ...op, versao: 1, revisao: Number(op.revisao ?? 0) + 1,
      id_evento: dados.evento, id_usuario: uid, lotes,
      ...(acoes.some(a => ["publico", "base", "duracao", "perfil", "margem", "verba"].includes(a.tipo)) ? {
        configuracao_planejamento: { ...config, revisao: Number(op.revisao ?? 0) + 1,
          campos_alterados: [...new Set(acoes.filter(a => ["publico", "base", "duracao", "perfil", "margem", "verba"].includes(a.tipo)).flatMap(a => a.tipo === "publico" ? ["publico", "base", "base_confirmada"] : a.tipo === "verba" ? ["verba_alimentacao"] : [a.tipo]))] },
      } : {}),
      execucao: { ...mapa(op.execucao), regras: rules, contexto_desatualizado: true } };
    tx.set(root, resultado);
    for (const [p, patch] of Object.entries(patches)) tx.update(db.doc(p), patch);
    for (const [p, doc] of Object.entries(novos)) tx.create(db.doc(p), doc);
    tx.update(ref, { aplicado_em: Timestamp.now(), selecionadas: dados.selecionadas });
    const aplicadas = Object.fromEntries(acoes.map(a => [a.fingerprint, {
      entrada: dados.id, tipo: a.tipo,
      ...(["despesa", "cotacao"].includes(a.tipo) ? { orcamento: despesaId(a.id) } : {}),
    }]));
    for (const h of hashes) tx.set(root.collection("documentos").doc(h), {
      acoes: { ...mapa(registros[h].acoes), ...aplicadas }, entrada: dados.id, aplicado_em: Timestamp.now(),
      previstas: [...new Set([...(registros[h].previstas ?? []), ...(salvo.acoes as Dados[]).map(a => a.fingerprint)])],
    });
    return { aplicado: true, operacao: resultado, limite_atual: patches[`evento/${dados.evento}`]?.custo_estimado ?? null, regras_alteradas: acoes.filter(a => a.regra).map(a => a.regra.id) };
  });
}
