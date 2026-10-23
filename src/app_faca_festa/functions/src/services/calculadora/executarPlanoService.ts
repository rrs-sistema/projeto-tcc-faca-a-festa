import { validarAgenda } from "./agendaServicoService";
import { validarReferenciaContextual } from "./catalogoContextualService";
import { validarPoliticaPublico } from "./publicoPlanejamentoService";
import { createHash } from "crypto";
import { Firestore, Timestamp, GeoPoint, DocumentReference, Query } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
type M = Record<string, any>;
const map = (v: unknown): M => v && typeof v === "object" && !Array.isArray(v) ? v as M : {};
const fail = (message: string): never => { throw new HttpsError("failed-precondition", message); };
const id = (v: unknown): v is string => typeof v === "string" && /^[^/]{1,200}$/.test(v);
function canonical(v: any): string {
    if (Array.isArray(v))
        return `[${v.map(canonical).join(",")}]`;
    if (v && typeof v === "object")
        return `{${Object.keys(v).sort().map(k => `${JSON.stringify(k)}:${canonical(v[k])}`).join(",")}}`;
    return JSON.stringify(v);
}
export function normalizarFonte(v: any): any {
    // Dart emits three fractional digits for millisecond timestamps, six otherwise.
    if (v instanceof Timestamp) {
        // Admin Timestamp.toDate() rounds milliseconds; Dart truncates to micros.
        // Build the millisecond portion without rounding before appending micros.
        const date = new Date(v.seconds * 1000 + Math.floor(v.nanoseconds / 1000000)).toISOString();
        const micro = Math.floor(v.nanoseconds / 1000) % 1000;
        return { __timestamp: micro ? date.replace("Z", `${String(micro).padStart(3, "0")}Z`) : date };
    }
    if (v instanceof GeoPoint)
        return { __geo: [v.latitude, v.longitude] };
    if (v instanceof DocumentReference)
        return { __ref: v.path };
    if (Array.isArray(v))
        return v.map(normalizarFonte);
    if (v && typeof v === "object")
        return Object.fromEntries(Object.entries(v).map(([k, a]) => [k, normalizarFonte(a)]));
    return v ?? null;
}
function numero(v: any): number {
    if (typeof v !== "number" || !Number.isFinite(v) || v < 0 || v > 1000000)
        fail("Quantidade inválida no plano.");
    return v;
}
function tarefaId(evento: string, chave: string): string {
    const hash = createHash("sha1").update(Buffer.from("6ba7b8119dad11d180b400c04fd430c8", "hex")).update(chave).digest();
    hash[6] = (hash[6] & 0x0f) | 0x50;
    hash[8] = (hash[8] & 0x3f) | 0x80;
    const h = hash.subarray(0, 16).toString("hex");
    return `calc_exec_${evento}_${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}
/** Owner-only command, bounded to a complete event snapshot. Queries participate
 * in the same transaction as the writes, including initially empty collections. */
export async function executarPlano(db: Firestore, uid: string | undefined, raw: unknown): Promise<boolean> {
    if (!uid)
        throw new HttpsError("unauthenticated", "Entre na conta do organizador.");
    const command = map(raw), evento = command.evento, pedido = command.pedido;
    if (!id(evento) || !id(pedido) || Buffer.byteLength(JSON.stringify(command), "utf8") > 750000) {
        throw new HttpsError("invalid-argument", "Plano inválido ou muito grande.");
    }
    const p = map(command.plano), fontes = map(p.fontes), patches = map(p.alteracoes), op = map(p.operacao);
    if (Object.keys(fontes).length > 240 || Object.keys(patches).length > 100 || !Array.isArray(p.regras) || p.regras.length > 60)
        fail("O plano excede o limite de uma revisão conjunta.");
    const assinatura = createHash("sha256").update(canonical(p)).digest("hex");
    const opRef = db.doc(`calculadora_operacao/${evento}`), receipt = opRef.collection("aplicacoes").doc(pedido);
    return db.runTransaction(async (tx) => {
        const ev = await tx.get(db.doc(`evento/${evento}`));
        if (ev.data()?.id_usuario !== uid)
            throw new HttpsError("permission-denied", "Somente o organizador pode aplicar o plano.");
        const oldReceipt = await tx.get(receipt);
        if (oldReceipt.exists) {
            if (oldReceipt.data()?.versao !== 2 || oldReceipt.data()?.assinatura !== assinatura || oldReceipt.data()?.id_usuario !== uid)
                fail("Pedido já utilizado para outra revisão.");
            return false;
        }
        const current = new Map<string, M | null>([[ev.ref.path, ev.data() ?? null]]);
        const operation = await tx.get(opRef);
        if (operation.data()?.versao != null && operation.data()?.versao !== 1) throw new HttpsError("failed-precondition", "Atualize o leitor antes de alterar esta operação.");
        current.set(opRef.path, operation.data() ?? null);
        const referencias = new Map<string, M>();
        for (const regra of p.regras)
            for (const campo of ["referencia_snapshot", "modelo_snapshot", "rendimento_snapshot"]) {
                const snapshot = regra?.premissas?.[campo];
                if (snapshot == null)
                    continue;
                validarReferenciaContextual(snapshot);
                const chave = `${snapshot.id}/${snapshot.versao}`;
                if (!referencias.has(chave)) {
                    const versao = await tx.get(db.doc(`calculadora_itens_base/${snapshot.id}/versoes_contextuais/${snapshot.versao}`));
                    if (!versao.exists)
                        fail("A versão editorial da proposta não está disponível. Revise a referência.");
                    referencias.set(chave, versao.data()!);
                }
                if (canonical(referencias.get(chave)) !== canonical(snapshot))
                    fail("A referência editorial foi alterada. Revise a proposta.");
            }
        async function query(q: Query, max: number) {
            const snapshot = await tx.get(q.limit(max + 1));
            if (snapshot.size > max)
                fail("A consulta excedeu o limite. Atualize a revisão.");
            for (const doc of snapshot.docs)
                current.set(doc.ref.path, doc.data());
            if (current.size > 240)
                fail("Há muitos registros para esta revisão conjunta.");
            return snapshot.docs;
        }
        const menus = await query(db.collection("cardapios").where("id_evento", "==", evento), 20);
        for (const menu of menus)
            if (menu.data().ativo !== false)
                await query(menu.ref.collection("itens"), 60);
        await query(db.collection("convidado").where("id_evento", "==", evento), 120);
        const budgets = await query(db.collection("orcamento").where("id_evento", "==", evento), 40);
        for (const budget of budgets)
            await query(budget.ref.collection("orcamento_gasto"), 40);
        await query(db.collection("tarefa").where("id_evento", "==", evento), 100);
        if (current.size !== Object.keys(fontes).length || [...current].some(([path, value]) => !Object.hasOwnProperty.call(fontes, path) || canonical(normalizarFonte(value)) !== canonical(fontes[path]))) {
            const diferentes = [...new Set([...current.keys(), ...Object.keys(fontes)])]
                .filter(path => !current.has(path) || !Object.hasOwnProperty.call(fontes, path) || canonical(normalizarFonte(current.get(path))) !== canonical(fontes[path]));
            throw new HttpsError("failed-precondition", "Público, cardápio, estoque, despesas ou tarefas mudaram. Atualize a proposta antes de aplicar.", { fontes: diferentes.slice(0, 30) });
        }
        if (op.versao !== 1 || op.revisao !== (operation.data()?.revisao ?? 0) + 1)
            fail("Revisão operacional incompatível.");
        validarPoliticaPublico(op.configuracao_planejamento ?? {});
        validarAgenda(op.agenda, evento);
        const roots = ["id_evento", "id_usuario", "versao", "revisao", "refeicoes", "lotes", "execucao", "revisao_pos_evento", "configuracao_planejamento", "agenda", "planejador"];
        if (Object.keys(op).some(k => !roots.includes(k)))
            fail("Operação desconhecida.");
        // The grouped executor may only change stock and its execution report.
        for (const key of ["refeicoes", "revisao_pos_evento", "configuracao_planejamento", "agenda", "planejador"]) {
            if (canonical(op[key] ?? null) !== canonical(operation.data()?.[key] ?? null))
                fail("A configuração da refeição mudou.");
        }
        const lots = map(op.lotes);
        if (Object.keys(lots).length > 100)
            fail("Limite de estoque excedido.");
        for (const [key, rawLot] of Object.entries(lots)) {
            const lot = map(rawLot), prior = map(map(operation.data()?.lotes)[key]);
            if (!Object.keys(prior).length || ["nome", "total", "unidade", "estado"].some(k => canonical(lot[k] ?? null) !== canonical(prior[k] ?? null)))
                fail("O executor não pode criar ou alterar lotes.");
            const used = Object.values(map(lot.reservas)).reduce<number>((sum, r) => sum + numero(map(r).quantidade), 0);
            if (used > numero(lot.total) + 1e-9)
                fail("Saldo insuficiente no estoque.");
            const anteriores = map(prior.reservas), novas = map(lot.reservas);
            for (const [destino, reserva] of Object.entries(anteriores)) {
                if (map(reserva).origem !== "execucao_v1" && canonical(novas[destino] ?? null) !== canonical(reserva))
                    fail("Reservas manuais devem ser preservadas.");
                if (canonical(novas[destino] ?? null) !== canonical(reserva)) {
                    const r = map(reserva), chave = canonical(["preparo", r.refeicao, r.item]);
                    const iniciada = [...current].some(([path, t]) => path.startsWith("tarefa/") && t?.calculadora_origem === "execucao_v1" && t?.calculadora_chave === chave && (t.status !== "a_fazer" || t.calculadora_assinatura !== canonical({ titulo: t.titulo, descricao: t.descricao })));
                    if (iniciada)
                        fail("Reservas de preparo iniciado ou editado devem ser preservadas.");
                }
            }
            for (const [destino, rawReserva] of Object.entries(novas)) {
                if (canonical(anteriores[destino] ?? null) === canonical(rawReserva))
                    continue;
                const r = map(rawReserva), path = `cardapios/${r.refeicao}/itens/${r.item}`, item = current.get(path);
                if (!id(r.refeicao) || !id(r.item) || !item || current.get(`cardapios/${r.refeicao}`)?.id_evento !== evento || current.get(`cardapios/${r.refeicao}`)?.somente_modelo === true || r.origem !== "execucao_v1" || r.publico !== (item.publico_alvo ?? "todos"))
                    fail("Destino da reserva incompatível.");
                const chave = r.ingrediente == null ? [r.refeicao, r.item] : [r.refeicao, r.item, r.ingrediente];
                if (destino !== JSON.stringify(chave))
                    fail("Uma reserva deve usar a chave única do destino.");
                const regra = p.regras.find((v: M) => v.premissas?.id_cardapio === r.refeicao && v.premissas?.id_item_cardapio === r.item);
                if (!regra)
                    fail("Reserva sem regra revisada.");
                const ingrediente = r.ingrediente == null ? null : map(regra.premissas?.ficha_tecnica).ingredientes?.find((i: M) => i.id === r.ingrediente);
                if (r.ingrediente != null && !ingrediente)
                    fail("Ingrediente sem ficha técnica conhecida.");
                const produto = ingrediente ?? { nome: item!.nome, unidade: item!.unidade, estado: regra.premissas?.estado_compra ?? regra.premissas?.estado };
                const normal = (s: any) => String(s ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").trim().toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
                if (normal(lot.nome) !== normal(produto.nome) || r.nome !== produto.nome || lot.unidade !== produto.unidade || lot.estado !== produto.estado)
                    fail("Identidade, unidade ou estado incompatível no lote.");
            }
        }
        if (Object.keys(lots).length !== Object.keys(map(operation.data()?.lotes)).length)
            fail("O executor não pode excluir lotes.");
        const destinations = new Map<string, boolean>();
        for (const [path, rawPatch] of Object.entries(patches)) {
            const patch = map(rawPatch), parts = path.split("/");
            const task = parts.length === 2 && parts[0] === "tarefa" && parts[1].startsWith(`calc_exec_${evento}_`);
            const item = parts.length === 4 && parts[0] === "cardapios" && parts[2] === "itens" && current.has(path) && current.get(`cardapios/${parts[1]}`)?.id_evento === evento && current.get(`cardapios/${parts[1]}`)?.somente_modelo !== true;
            const allowed = task ? ["id_tarefa", "id_evento", "titulo", "descricao", "status", "id_responsavel", "data_prevista", "calculadora_origem", "calculadora_chave", "calculadora_assinatura", "calculadora_sem_demanda"] : ["quantidade_sugerida", "disponibilidade"];
            if ((!task && !item) || Object.keys(patch).some(k => !allowed.includes(k)))
                fail("Destino ou campos incompatíveis.");
            const previous = current.get(path);
            if (task) {
                const target = await tx.get(db.doc(path));
                if (target.exists && !current.has(path))
                    fail("Uma tarefa foi criada durante a revisão.");
                if ((previous?.id_evento ?? patch.id_evento) !== evento || (patch.calculadora_origem ?? previous?.calculadora_origem) !== "execucao_v1")
                    fail("Tarefa incompatível.");
                const chave = patch.calculadora_chave ?? previous?.calculadora_chave;
                if (typeof chave !== "string" || tarefaId(evento, chave) !== parts[1] || (previous && previous.calculadora_chave !== chave))
                    fail("Identidade estável da tarefa incompatível.");
                if (previous && (previous.status !== "a_fazer" || previous.calculadora_origem !== "execucao_v1" || canonical({ titulo: previous.titulo, descricao: previous.descricao }) !== previous.calculadora_assinatura)) {
                    fail("Uma tarefa já iniciada ou editada deve ser preservada.");
                }
                if (!previous && (patch.status !== "a_fazer" || (patch.id_responsavel != null && patch.id_responsavel !== uid)))
                    fail("Responsável ou status inválido.");
                if (previous && ["status", "id_responsavel", "data_prevista"].some(k => Object.hasOwnProperty.call(patch, k) && canonical(patch[k]) !== canonical(previous[k] ?? null)))
                    fail("A execução não altera responsabilidade, prazo ou conclusão.");
                if ((patch.id_tarefa != null && patch.id_tarefa !== parts[1]) || (patch.id_evento != null && patch.id_evento !== evento) || typeof patch.titulo !== "string" || typeof patch.descricao !== "string" || patch.titulo.length > 300 || patch.descricao.length > 12000 || patch.calculadora_assinatura !== canonical({ titulo: patch.titulo, descricao: patch.descricao }))
                    fail("Conteúdo da tarefa incompatível.");
            }
            else {
                if (patch.quantidade_sugerida != null)
                    numero(patch.quantidade_sugerida);
                if (patch.disponibilidade != null) {
                    const availability = map(patch.disponibilidade);
                    if (Object.keys(availability).some(k => !["comprado", "estoque", "estado", "nome", "unidade", "publico"].includes(k)))
                        fail("Disponibilidade inválida.");
                    if (previous?.disponibilidade != null || availability.comprado !== 0 || availability.estoque !== 0)
                        fail("Compras existentes devem ser preservadas.");
                    if (availability.nome !== previous?.nome || availability.unidade !== previous?.unidade || availability.publico !== (previous?.publico_alvo ?? "todos") || !["cru", "seco", "pronto", "não se aplica"].includes(availability.estado))
                        fail("Identidade da disponibilidade incompatível.");
                }
            }
            destinations.set(path, previous != null);
        }
        // Applying one plan must not erase saved edits for items omitted from it.
        const salvas = map(operation.data()?.execucao).regras;
        const regras = new Map<string, M>();
        for (const raw of [...(Array.isArray(salvas) ? salvas : []), ...p.regras]) {
            const regra = map(raw);
            if (!id(regra.id))
                fail("Regra de consumo sem identificação válida.");
            if (p.regras.includes(raw)) {
                const meta = map(regra.premissas);
                if (meta.id_evento !== evento || !current.has(`cardapios/${meta.id_cardapio}/itens/${meta.id_item_cardapio}`))
                    fail("Regra fora do destino revisado.");
                const anterior = regras.get(regra.id);
                if (anterior && ["id_evento", "id_cardapio", "id_item_cardapio"].some(k => anterior.premissas?.[k] !== meta[k]))
                    fail("A identificação da regra já pertence a outro destino.");
            }
            regras.set(regra.id, regra);
        }
        if (regras.size > 60)
            fail("O evento excede 60 regras de consumo salvas.");
        tx.set(opRef, { ...op, id_evento: evento, id_usuario: uid, execucao: {
                versao: 2, pedido, publico: p.publico, compras: p.compras,
                regras: [...regras.values()], pendencias: command.pendencias ?? [], aplicado_em: new Date().toISOString(),
            } });
        for (const [path, rawPatch] of Object.entries(patches)) {
            const ref = db.doc(path), patch = map(rawPatch);
            if (destinations.get(path))
                tx.update(ref, patch);
            else
                tx.create(ref, { ...patch, id_responsavel: patch.id_responsavel ?? uid, data_cadastro: Timestamp.now() });
        }
        tx.create(receipt, { versao: 2, pedido, id_evento: evento, id_usuario: uid, assinatura, revisao: op.revisao, aplicado_em: Timestamp.now(), acoes: Object.keys(patches).length });
        return true;
    });
}
