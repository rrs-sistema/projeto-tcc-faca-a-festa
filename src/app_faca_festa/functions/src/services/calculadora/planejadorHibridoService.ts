import { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { lerFontesEntrada, hashEntrada, mapa, normal, Dados } from "./entradaAssistenteService";
import { normalizarFonte } from "./executarPlanoService";
import { validarReferenciaContextual } from "./catalogoContextualService";
const fail = (s: string): never => { throw new HttpsError("failed-precondition", s); };
const id = (v: any) => typeof v === "string" && v.length > 0 && v.length <= 200 && !v.includes("/");
const numero = (n: any, positivo = false) => { if (typeof n !== "number" || !Number.isFinite(n) || n < (positivo ? Number.MIN_VALUE : 0) || n > 1000000)
    fail("Número inválido na proposta."); return n; };
export function validarContextoReferenciaPlanejador(r: Dados, c: Dados, infra: Dados): void {
    if (!r.servicos.includes(c.servico) || !r.formatos.includes(c.formato) || !r.obtencoes.includes(c.obtencao) ||
        !r.periodos.includes("qualquer") && !r.periodos.includes(c.periodo) ||
        r.hora_inicio != null && (typeof c.hora_local !== "string" || c.hora_local < r.hora_inicio || c.hora_local > r.hora_fim) ||
        r.duracao_minima != null && (!Number.isInteger(c.duracao_minutos) || c.duracao_minutos < r.duracao_minima) ||
        r.duracao_maxima != null && (!Number.isInteger(c.duracao_minutos) || c.duracao_minutos > r.duracao_maxima) ||
        (r.infraestrutura ?? []).some((k: string) => infra[k] !== true))
        fail("Referência fora dos limites de contexto ou infraestrutura.");
}
const semVinculo = (r: Dados): Dados => {
    const m = { ...mapa(r.premissas) };
    for (const k of ["id_evento", "id_cardapio", "id_item_cardapio", "origem", "fonte", "memoria_contexto", "proposta_respostas", "revisada_pelo_organizador"])
        delete m[k];
    return { ...r, id: null, nome: normal(r.nome), premissas: m };
};
/** Recalcula as medições privadas; IDs e uma mediana enviados pelo cliente não são prova. */
export function validarMedicoesPlanejador(regra: Dados, registros: Dados[], evento: string): void {
    const m = mapa(regra.premissas);
    let contexto: any;
    try {
        contexto = JSON.parse(m.contexto_consumo);
    }
    catch (_) {
        fail("Contexto observado inválido.");
    }
    if (!Array.isArray(contexto) || contexto[0] !== "contexto_v3" || contexto[7] !== normal(regra.nome) || contexto[8] !== regra.publico ||
        contexto[9] !== ({ quilo: "kg", litro: "L", unidade: "un" } as Dados)[regra.unidade] || contexto[10] !== m.estado || contexto[11] !== m.papel_na_refeicao ||
        contexto[12] !== m.numero_servicos || contexto[14] !== (m.fator_composicao ?? 1) || contexto[15] !== (m.peso_crianca ?? .6) || contexto[16] !== (m.peso_bebe ?? .2))
        fail("A base da medição não corresponde à regra oferecida.");
    const porEvento = new Map<string, Dados>();
    for (const r of registros) {
        if (r.id_evento === evento || r.contexto !== m.contexto_consumo)
            continue;
        if (!porEvento.has(r.id_evento) || Date.parse(r.data_registro) > Date.parse(porEvento.get(r.id_evento)!.data_registro))
            porEvento.set(r.id_evento, r);
    }
    const recentes = [...porEvento.values()].filter(r => Date.parse(r.data_consumo) >= Date.now() - 365 * 86400000 && Date.parse(r.data_consumo) <= Date.now() + 86400000);
    if (recentes.some(r => r.faltou !== false))
        fail("Há falta registrada no contexto observado.");
    const valores = recentes.map(r => {
        const base = mapa(r.regra), meta = mapa(base.premissas);
        if (base.unidade !== regra.unidade || base.publico !== regra.publico || normal(base.nome) !== normal(regra.nome) || meta.estado !== m.estado || !meta.receita)
            fail("Medição sem receita ou unidade compatível.");
        const a = numero(r.adultos), c = numero(r.criancas), b = numero(r.bebes), pc = numero(meta.peso_crianca ?? .6), pb = numero(meta.peso_bebe ?? .2);
        if (pc > 1 || pb > 1)
            fail("Pesos etários inválidos.");
        const denominador = base.publico === "adultos" ? a : base.publico === "criancas" ? c * pc : base.publico === "bebes" ? b * pb : a + c * pc + b * pb;
        if (normal(meta.receita) !== contexto[6] || meta.estado_compra !== m.estado_compra || (meta.rendimento ?? 1) !== (m.rendimento ?? 1) || hashEntrada(meta.ficha_tecnica ?? null) !== hashEntrada(m.ficha_tecnica ?? null))
            fail("Receita ou rendimento distintos da medição.");
        const preparo = meta.estado === "pronto" ? 1 : numero(r.peso_pronto_medido, true) / numero(r.peso_base_medido, true);
        const disp = numero(r.disponibilizado_pronto, true), sobra = numero(r.sobra_pronta), desperdicio = numero(r.desperdicio_pronto);
        if (sobra + desperdicio > disp + 1e-9 || denominador <= 0)
            fail("Medição inconsistente.");
        return (disp - sobra) / preparo / denominador / numero(meta.numero_servicos ?? 1, true) / numero(meta.fator_composicao ?? 1, true);
    }).filter(v => v > 0).sort((a, b) => a - b);
    const mediana = (v: number[]) => v.length % 2 ? v[Math.floor(v.length / 2)] : (v[v.length / 2 - 1] + v[v.length / 2]) / 2;
    if (valores.length < 3 || !Array.isArray(m.eventos_origem) || hashEntrada([...m.eventos_origem].sort()) !== hashEntrada(recentes.filter(r => !r.faltou && (r.disponibilizado_pronto - r.sobra_pronta) > 0).map(r => r.id_evento).sort()))
        fail("São necessárias três medições privadas verificáveis.");
    const centro = mediana(valores), mad = mediana(valores.map(v => Math.abs(v - centro)).sort((a, b) => a - b));
    if (valores.length >= 5 && valores.some(v => Math.abs(v - centro) > Math.max(3 * 1.4826 * mad, centro * .5) + 1e-9) || Math.abs(regra.consumo - centro) > 1e-9)
        fail("A mediana não corresponde às medições ou há valores atípicos.");
}
export function validarDecisaoPlanejador(d: Dados): void {
    if (!d || d.versao !== 1 || Object.keys(d).some(k => !["versao", "objetivo", "infraestrutura", "respostas", "assinatura_material"].includes(k)) || !["manter_receitas", "comparar_quantidades", "avaliar_custo"].includes(d.objetivo) || !/^[a-f0-9]{64}$/.test(d.assinatura_material))
        fail("Revise o objetivo e o contexto do serviço.");
    if (!d.respostas || typeof d.respostas !== "object" || Array.isArray(d.respostas) || Object.keys(d.respostas).length > 100 || Object.entries(d.respostas).some(([k, v]) => k.length > 250 || typeof v !== "string" || v.length > 1000))
        fail("Respostas do planejador inválidas.");
    if (!d.infraestrutura || typeof d.infraestrutura !== "object" || Array.isArray(d.infraestrutura) || Object.entries(d.infraestrutura).some(([k, v]) => !["cozinha", "refrigeracao", "aquecimento", "equipe_preparo"].includes(k) || v !== null && typeof v !== "boolean"))
        fail("Confira a infraestrutura declarada.");
}
export function validarCandidatosPlanejador(raw: Dados, candidatos: Dados[]): Dados[] {
    if (!raw || Object.keys(raw).some(k => !["candidatos", "perguntas"].includes(k)) || !Array.isArray(raw.candidatos) || raw.candidatos.length > 30)
        fail("Resposta de candidatos inválida.");
    if (raw.perguntas != null && (!Array.isArray(raw.perguntas) || raw.perguntas.length > 10 || raw.perguntas.some((s: any) => typeof s !== "string" || s.length > 300)))
        fail("Perguntas inválidas.");
    const vistos = new Set<string>();
    return raw.candidatos.map((c: any) => {
        if (!c || Object.keys(c).some(k => !["id_item", "referencia_id", "versao"].includes(k)))
            fail("A IA só pode sugerir IDs, sem quantidades ou fatos.");
        const match = candidatos.find(r => r.id_item === c.id_item && r.referencia_id === c.referencia_id && r.versao === c.versao);
        const k = `${c.id_item}/${c.referencia_id}/${c.versao}`;
        if (!match || vistos.has(k))
            fail("Candidato fora do contexto aprovado.");
        vistos.add(k);
        return { id_item: c.id_item, referencia_id: c.referencia_id, versao: c.versao };
    });
}
export async function sugerirCandidatosPlanejador(db: Firestore, uid: string | undefined, input: Dados, extrair?: (contexto: Dados) => Promise<Dados>): Promise<Dados> {
    if (!uid)
        throw new HttpsError("unauthenticated", "Entre na conta do organizador.");
    if (!id(input?.evento) || !id(input?.cardapio) || typeof input.texto !== "string" || !input.texto.trim() || input.texto.length > 6000)
        fail("Informe um briefing de até 6.000 caracteres.");
    const dados = await db.runTransaction(async (tx) => {
        const fontes = await lerFontesEntrada(db, tx, input.evento, uid);
        const menu = fontes[`cardapios/${input.cardapio}`];
        if (!menu || menu.ativo === false || menu.somente_modelo === true)
            fail("Selecione um serviço deste evento.");
        const op = mapa(fontes[`calculadora_operacao/${input.evento}`]), cfg = mapa(mapa(op.refeicoes)[input.cardapio]);
        const o = (op.agenda ?? []).find((a: Dados) => a.id_cardapio === input.cardapio) ?? {};
        const docs = await tx.get(db.collection("calculadora_itens_base").limit(501));
        if (docs.size > 500)
            fail("Catálogo excede a consulta suportada.");
        const itens = Object.entries(fontes).filter(([p]) => p.startsWith(`cardapios/${input.cardapio}/itens/`));
        const candidatos: Dados[] = [];
        for (const doc of docs.docs) {
            const r = doc.data().referencia_contextual;
            if (!r || doc.data().ativo === false || r.schema !== 1 || r.motor_minimo !== 1)
                continue;
            validarReferenciaContextual(r);
            if (r.tipo !== "porcao" || !r.aprovado_por || !r.aprovado_em)
                continue;
            for (const [path, item] of itens) {
                if (!r.aliases.some((a: string) => normal(a) === normal(item.nome)) || !r.publicos.includes(item.publico_alvo ?? "todos") || cfg.servico && !r.servicos.includes(cfg.servico) || o.formato && o.formato !== "nao_definido" && !r.formatos.includes(o.formato))
                    continue;
                candidatos.push({ id_item: path.split("/").pop(), nome: item.nome, referencia_id: r.id, versao: r.versao, contexto: r.contexto, servicos: r.servicos, formatos: r.formatos, unidade: r.unidade, publico: item.publico_alvo ?? "todos" });
            }
        }
        if (candidatos.length > 60)
            fail("Refine os itens antes de consultar candidatos.");
        return { evento: input.evento, cardapio: input.cardapio, servico: cfg.servico ?? null, formato: o.formato ?? null, candidatos };
    });
    try {
        if (!extrair)
            throw Error("modelo indisponível");
        const resposta = await extrair({ ...dados, texto: input.texto });
        return { origem: "ia_ids_validados", candidatos: validarCandidatosPlanejador(resposta, dados.candidatos), perguntas: resposta.perguntas ?? [], aviso: "Candidatos por ID para revisão. Nenhuma quantidade, presença ou compra foi inferida." };
    }
    catch (_) {
        const texto = `_${normal(input.texto)}_`;
        const locais = dados.candidatos.filter((c: Dados) => texto.includes(`_${normal(c.nome)}_`));
        return { origem: "parser_local_limitado", candidatos: validarCandidatosPlanejador({ candidatos: locais.map((c: Dados) => ({ id_item: c.id_item, referencia_id: c.referencia_id, versao: c.versao })) }, dados.candidatos), perguntas: [], aviso: "IA indisponível ou saída inválida. Leitura local limitada a nomes exatos já cadastrados; contexto e candidatos exigem confirmação. O cálculo determinístico permanece disponível." };
    }
}
export async function confirmarPlanejador(db: Firestore, uid: string | undefined, input: Dados): Promise<Dados> {
    if (!uid)
        throw new HttpsError("unauthenticated", "Entre na conta do organizador.");
    if (!id(input?.evento) || !id(input?.cardapio) || !id(input?.pedido) || !Number.isInteger(input?.revisao) || input.revisao < 0 || !Array.isArray(input.regras) || input.regras.length > 60 || Buffer.byteLength(JSON.stringify(input)) > 750000)
        fail("Revisão do planejador inválida.");
    validarDecisaoPlanejador(input.decisao);
    const assinatura = hashEntrada(input);
    return db.runTransaction(async (tx) => {
        const fontes = await lerFontesEntrada(db, tx, input.evento, uid, true);
        const ref = db.doc(`calculadora_operacao/${input.evento}`), op = mapa(fontes[ref.path]);
        const reciboRef = ref.collection("planejador_confirmacoes").doc(input.pedido), recibo = await tx.get(reciboRef);
        if (recibo.exists) {
            if (recibo.data()?.assinatura !== assinatura)
                fail("Este pedido já confirmou outros dados.");
            return op;
        }
        if ((op.revisao ?? 0) !== input.revisao || hashEntrada(normalizarFonte(fontes)) !== hashEntrada(input.fontes))
            fail("As fontes do evento mudaram. Reabra o planejador para revisar.");
        const menu = fontes[`cardapios/${input.cardapio}`];
        if (!menu || menu.id_evento !== input.evento || menu.ativo === false || menu.somente_modelo === true)
            fail("O serviço não está disponível.");
        const exec = mapa(op.execucao), regras: Dados[] = [...(exec.regras ?? [])], ids = new Set<string>();
        for (const regra of input.regras) {
            const m = mapa(regra.premissas), item = fontes[`cardapios/${input.cardapio}/itens/${m.id_item_cardapio}`];
            if (!item || regra.id !== `menu_${input.cardapio}_${m.id_item_cardapio}` || ids.has(regra.id) || m.id_evento !== input.evento || m.id_cardapio !== input.cardapio || normal(regra.nome) !== normal(item.nome) || regra.publico !== (item.publico_alvo ?? "todos"))
                fail("Regra fora do destino ou da unidade suportada.");
            ids.add(regra.id);
            numero(regra.consumo, true);
            numero(regra.preco ?? 0);
            numero(m.rendimento ?? 1, true);
            numero(m.numero_servicos ?? 1, true);
            const unidade = ({ quilo: "kg", litro: "L", unidade: "un" } as Dados)[regra.unidade];
            const indice = regras.findIndex(r => r.id === regra.id), anterior = indice < 0 ? null : regras[indice];
            if (anterior && (anterior.premissas?.revisada_pelo_organizador === true || anterior.premissas?.receita || anterior.premissas?.ficha_tecnica)) {
                if (hashEntrada(anterior) !== hashEntrada(regra))
                    fail("Uma receita confirmada não pode ser substituída pelo planejador.");
                continue;
            }
            if (!["quilo", "litro", "unidade"].includes(regra.unidade) || item.unidade !== unidade && !(item.unidade === "un" && !item.confirmado && !item.disponibilidade && !Number(item.quantidade_final ?? 0) && !Number(item.quantidade_sugerida ?? 0)))
                fail("A unidade do item mudou. Revise manualmente.");
            if (Object.keys(regra).some(k => !["id", "categoria", "nome", "tipo", "publico", "unidade", "consumo", "preco", "selecionado", "premissas"].includes(k)) || regra.selecionado !== true || regra.tipo !== item.tipo)
                fail("Estrutura da regra incompatível com o item.");
            if (m.origem === "preferencia_privada") {
                const memoria = await tx.get(db.doc(`calculadora_preferencias/${uid}`));
                const receita = (memoria.data()?.receitas ?? []).find((r: Dados) => r.contexto === m.memoria_contexto && normal(r.regra?.nome) === normal(regra.nome) && r.regra?.consumo === regra.consumo && r.regra?.unidade === regra.unidade && r.regra?.publico === regra.publico && r.regra?.premissas?.receita === m.receita);
                if (!receita || hashEntrada(semVinculo(receita.regra)) !== hashEntrada(semVinculo(regra)))
                    fail("A receita privada mudou. Revise a adoção.");
            }
            else if (m.origem === "consumo_observado") {
                // Adoção exige a evidência privada conferida; não aceitar preferência como medição.
                const eventos = m.eventos_origem;
                if (!Array.isArray(eventos) || new Set(eventos).size < 3 || !m.contexto_consumo)
                    fail("Consumo observado sem evidência compatível.");
                const historicos = await tx.get(db.collection("calculadora_festa").where("id_usuario", "==", uid).limit(101));
                if (historicos.size > 100)
                    fail("Refine os registros de consumo.");
                const disponiveis = historicos.docs.flatMap(d => Object.values(mapa(d.data().consumo_observado)) as Dados[]);
                const cfg = mapa(op.configuracao_planejamento), destino = mapa(mapa(op.refeicoes)[input.cardapio]), ev = fontes[`evento/${input.evento}`];
                let publico = mapa(destino.publico);
                if (!Object.keys(publico).length) {
                    if (cfg.base === "manual")
                        publico = mapa(cfg.publico);
                    else if (!cfg.base || cfg.base === "previstos")
                        publico = { adultos: ev.total_adultos, criancas: ev.total_criancas, bebes: ev.total_bebes };
                    else {
                        publico = { adultos: 0, criancas: 0, bebes: 0 };
                        for (const [p, g] of Object.entries(fontes))
                            if (p.startsWith("convidado/") && (cfg.base !== "confirmados" || g.status === "confirmado") && (cfg.base !== "nao_recusados" || g.status !== "recusado")) {
                                const tipo = g.tipo_convidado ?? (g.adulto === false ? "crianca" : "adulto");
                                publico[tipo === "adulto" ? "adultos" : tipo === "bebe" ? "bebes" : "criancas"]++;
                            }
                    }
                }
                const extra = mapa(destino.publico_extra);
                for (const k of ["adultos", "criancas", "bebes"])
                    publico[k] = numero(publico[k]) + numero(extra[k] ?? 0);
                const total = publico.adultos + publico.criancas + publico.bebes;
                const comparaveis = disponiveis.filter(r => { const n = r.adultos + r.criancas + r.bebes; return ["adultos", "criancas", "bebes"].every(k => r[k] * total === publico[k] * n); });
                validarMedicoesPlanejador(regra, comparaveis, input.evento);
                // Reutilização exige dimensões do serviço atual, nunca só um título parecido.
                let contexto: any;
                try {
                    contexto = JSON.parse(m.contexto_consumo);
                }
                catch (_) {
                    fail("Contexto inválido.");
                }
                const dimensoes = mapa(contexto?.[18]?.servico_planejador_v1), ocorrencia = (op.agenda ?? []).find((a: Dados) => a.id_cardapio === input.cardapio) ?? {};
                const grupos = (destino.grupos ?? []) as Dados[], d = mapa(mapa(destino.destinos_itens)[m.id_item_cardapio]), modo = d.modo ?? "todos";
                const dietas = [modo, ...grupos.filter(g => modo === "demais" || (d.grupos ?? []).includes(g.id)).map(g => [...(g.restricoes ?? [])].sort().join("+"))].sort();
                const gruposContexto = grupos.map(g => JSON.stringify([[...(g.restricoes ?? [])].sort(), g.adultos, g.criancas, g.bebes])).sort();
                if (hashEntrada(contexto[1]) !== hashEntrada(dietas) || hashEntrada(contexto[2]) !== hashEntrada(gruposContexto) || contexto[13] !== (cfg.duracao ?? 4))
                    fail("Grupos, destinos ou duração mudaram desde as medições.");
                if (regra.preco !== 0 || m.ajustar_por_duracao !== false || m.ajustar_por_perfil !== false || m.consumo_min != null || m.consumo_max != null)
                    fail("A medição não fornece preço nem novos fatores de ajuste.");
                const outras = regras.filter(r => r.selecionado !== false && r.premissas?.id_cardapio === input.cardapio && r.premissas?.id_item_cardapio !== m.id_item_cardapio);
                const assinaturas = (contexto[17] ?? []).map((s: string) => s.split("|"));
                if (assinaturas.length !== outras.length || outras.some(r => !assinaturas.some((a: any[]) => a[0] === normal(r.nome) && a[1] === r.publico && a[2] === r.premissas?.papel_na_refeicao && a[3] === r.premissas?.estado && a[4] === (r.premissas?.receita ?? "") && Number(a[5]) === r.consumo && Number(a[6]) === (r.premissas?.numero_servicos ?? 1) && Number(a[7]) === (r.premissas?.fator_composicao ?? 1) && Number(a[8]) === (r.premissas?.rendimento ?? 1) && a[9] === ({ quilo: "kg", litro: "L", unidade: "un" } as Dados)[r.unidade] && a[10] === (r.premissas?.estado_compra ?? ""))))
                    fail("A composição mudou desde as medições; confira manualmente.");
                const desconhecidos = Object.entries(fontes).filter(([p, i]) => p.startsWith(`cardapios/${input.cardapio}/itens/`) && p.split("/").pop() !== m.id_item_cardapio && !outras.some(r => r.premissas?.id_item_cardapio === p.split("/").pop())).map(([, i]) => `${normal(i.nome)}|${normal(i.unidade)}|${i.publico_alvo ?? "todos"}`).sort();
                if (hashEntrada(desconhecidos) !== hashEntrada(contexto[5]))
                    fail("Há itens sem receita diferentes do contexto medido.");
                const servicoAtual = mapa(mapa(op.refeicoes)[input.cardapio]).servico;
                if (!Object.keys(dimensoes).length || dimensoes.servico !== servicoAtual || dimensoes.formato !== ocorrencia.formato || dimensoes.duracao_minutos !== ocorrencia.duracao_minutos || dimensoes.hora_local !== ocorrencia.hora_local || hashEntrada(dimensoes.infraestrutura) !== hashEntrada(input.decisao.infraestrutura))
                    fail("As medições não têm dimensões compatíveis com este serviço; use a revisão manual.");
            }
            else {
                const r = m.referencia_snapshot;
                validarReferenciaContextual(r);
                const doc = await tx.get(db.doc(`calculadora_itens_base/${r.id}/versoes_contextuais/${r.versao}`));
                const c = mapa(m.contexto_referencia), infra = mapa(input.decisao.infraestrutura);
                if (!doc.exists || hashEntrada(doc.data()) !== hashEntrada(r) || !r.aprovado_por || !r.aliases.some((a: string) => normal(a) === normal(regra.nome)) || !r.servicos.includes(c.servico) || !r.formatos.includes(c.formato) || !r.publicos.includes(regra.publico) || !r.obtencoes.includes(c.obtencao) || regra.unidade !== r.unidade || regra.consumo !== r.padrao || regra.preco !== 0 || (r.infraestrutura ?? []).some((k: string) => infra[k] !== true))
                    fail("Referência não corresponde ao contexto aprovado.");
                validarContextoReferenciaPlanejador(r, c, infra);
                const respostas = mapa(input.decisao.respostas);
                for (const [campo, chave] of [["servico", "servico"], ["formato", "formato"], ["obtencao", `obtencao_${m.id_item_cardapio}`], ["periodo", "periodo"]]) {
                    if (respostas[chave] != null && respostas[chave] !== c[campo])
                        fail("A proposta diverge da escolha confirmada.");
                }
                if (r.tipo !== "porcao" || m.peso_crianca !== 1 || m.peso_bebe !== 1 || m.numero_servicos !== 1 || (m.fator_composicao ?? 1) !== 1 || m.ajustar_por_duracao !== false || m.ajustar_por_perfil !== false || m.consumo_min !== r.minimo || m.consumo_max !== r.maximo || m.papel_na_refeicao !== r.papel || m.publico_refeicao != null || m.destino_publico != null || m.ficha_tecnica != null || m.receita != null || m.dividir_grupo === true)
                    fail("A referência contém ajustes não confirmados.");
                const ocorrencia = (op.agenda ?? []).find((a: Dados) => a.id_cardapio === input.cardapio), servico = mapa(mapa(op.refeicoes)[input.cardapio]).servico;
                if (servico && servico !== c.servico || ocorrencia?.formato && ocorrencia.formato !== "nao_definido" && ocorrencia.formato !== c.formato)
                    fail("O contexto confirmado do serviço prevalece sobre o briefing.");
                if (ocorrencia?.hora_local != null && c.hora_local !== ocorrencia.hora_local || ocorrencia?.duracao_minutos != null && c.duracao_minutos !== ocorrencia.duracao_minutos)
                    fail("Horário ou duração divergem da agenda confirmada.");
                if (c.obtencao !== "preparar" && (m.rendimento ?? 1) !== 1 || c.obtencao === "pronto" && (r.estado_compra !== "pronto" || r.estado_consumo !== "pronto") || c.obtencao === "preparar" && r.estado_compra === "pronto")
                    fail("Obtenção ou rendimento incompatíveis.");
                if (m.estado !== r.estado_consumo || m.estado_compra !== (c.obtencao === "servir" ? r.estado_consumo : r.estado_compra))
                    fail("Estados de consumo e compra incompatíveis.");
                if (c.obtencao === "preparar" && r.estado_consumo !== r.estado_compra) {
                    const rend = m.rendimento_snapshot;
                    validarReferenciaContextual(rend);
                    const fonte = await tx.get(db.doc(`calculadora_itens_base/${rend.id}/versoes_contextuais/${rend.versao}`));
                    if (!fonte.exists || hashEntrada(fonte.data()) !== hashEntrada(rend) || m.rendimento !== rend.padrao || rend.tipo !== "rendimento" || !rend.aliases.some((a: string) => normal(a) === normal(regra.nome)))
                        fail("Rendimento não conferido.");
                    validarContextoReferenciaPlanejador(rend, c, infra);
                    if (rend.unidade !== r.unidade || rend.estado_consumo !== r.estado_consumo || rend.estado_compra !== r.estado_compra || !rend.publicos.includes(regra.publico))
                        fail("Rendimento incompatível com a referência.");
                }
            }
            if (indice < 0)
                regras.push(regra);
            else
                regras[indice] = regra;
        }
        if (regras.length > 60)
            fail("O evento excede 60 regras privadas.");
        const planejador = { ...mapa(op.planejador), [input.cardapio]: input.decisao };
        if (Object.keys(planejador).length > 20)
            fail("Limite de serviços excedido.");
        const novo = { ...op, id_evento: input.evento, id_usuario: uid, versao: 1, revisao: input.revisao + 1, planejador, execucao: { ...exec, regras, contexto_desatualizado: true } };
        tx.set(ref, novo);
        tx.create(reciboRef, { assinatura, id_usuario: uid });
        return novo;
    });
}
