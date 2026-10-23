import { onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo } from "../../shared/auth";
import {
  agregarDashboardAdmin,
  centavosDeOrcamento,
  FatoComercial,
  FatoComissao,
} from "../../services/financeiro/dashboardAdminService";
import {
  LinhaContratacaoAdmin,
  resolverLinhaContratacao,
  rotuloEstadoExecucao,
} from "../../services/financeiro/contratacaoIdentidadeService";

const REGION = "southamerica-east1";
const LIMITE_ORCAMENTOS = 500;

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

function parseData(v: unknown): string | null {
  if (!v) return null;
  if (typeof v === "string") return v;
  if (typeof v === "object" && v !== null && "toDate" in v) {
    try {
      return (v as { toDate: () => Date }).toDate().toISOString();
    } catch {
      return null;
    }
  }
  return null;
}

async function carregarMapaDocs(
  db: FirebaseFirestore.Firestore,
  colecao: string,
  ids: Set<string>,
): Promise<Map<string, Record<string, unknown>>> {
  const mapa = new Map<string, Record<string, unknown>>();
  const lista = [...ids].filter(Boolean);
  const chunk = 100;
  for (let i = 0; i < lista.length; i += chunk) {
    const fatia = lista.slice(i, i + chunk);
    await Promise.all(
      fatia.map(async (id) => {
        const snap = await db.collection(colecao).doc(id).get();
        if (snap.exists) {
          mapa.set(id, (snap.data() ?? {}) as Record<string, unknown>);
        }
      }),
    );
  }
  return mapa;
}

/**
 * Agregado seguro para admin. Não lê custos_internos / margens de fornecedor.
 * Prompt 01: enriquece identidades em lote e lista contratações por fornecedor.
 */
export const consultarDashboardFinanceiroAdmin = onCall(
  { region: REGION, timeoutSeconds: 120, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const eixo = texto(data.eixoTemporal ?? data.eixo_temporal) || "data_evento";
    const idFornecedorFiltro = texto(data.idFornecedor ?? data.id_fornecedor);
    const estadoFiltro = texto(data.estado ?? data.status).toLowerCase();
    const inicio = texto(data.periodoInicio ?? data.periodo_inicio);
    const fim = texto(data.periodoFim ?? data.periodo_fim);
    const busca = texto(data.busca ?? data.q).toLowerCase();

    const db = admin.firestore();

    const orcSnap = await db.collection("orcamento").limit(LIMITE_ORCAMENTOS).get();
    const truncado = orcSnap.size >= LIMITE_ORCAMENTOS;

    type OrcItem = {
      id: string;
      data: Record<string, unknown>;
      contratado: boolean;
      vals: ReturnType<typeof centavosDeOrcamento>;
      dataEvento: string | null;
      dataContrato: string | null;
    };

    const itens: OrcItem[] = [];
    for (const doc of orcSnap.docs) {
      const d = doc.data() as Record<string, unknown>;
      const idEvento = texto(d.id_evento);
      if (!idEvento) continue;
      if (idFornecedorFiltro && texto(d.id_fornecedor) !== idFornecedorFiltro) {
        continue;
      }

      const status = texto(d.status).toLowerCase();
      const contratoMap =
        d.contrato_financeiro && typeof d.contrato_financeiro === "object"
          ? (d.contrato_financeiro as { estado_comercial?: string })
          : null;
      const contratado: boolean =
        d.orcamento_fechado === true ||
        status === "fechado" ||
        status === "contratado" ||
        contratoMap?.estado_comercial === "contratado";

      const vals = centavosDeOrcamento(d);
      const dataEvento = parseData(d.data_evento) || parseData(d.data);
      const dataContrato =
        parseData(d.data_cadastro) || parseData(d.data_fechamento);

      if (inicio || fim) {
        const ref = eixo === "data_contratacao" ? dataContrato : dataEvento;
        if (ref) {
          if (inicio && ref < inicio) continue;
          if (fim && ref > fim) continue;
        }
      }
      if (estadoFiltro) {
        if (estadoFiltro === "contratado" && !contratado) continue;
        if (estadoFiltro === "oportunidade" && contratado) continue;
      }

      itens.push({
        id: doc.id,
        data: d,
        contratado,
        vals,
        dataEvento,
        dataContrato,
      });
    }

    const idsEvento = new Set<string>();
    const idsFornecedor = new Set<string>();
    const idsUsuario = new Set<string>();
    for (const it of itens) {
      const idEvento = texto(it.data.id_evento);
      if (idEvento) idsEvento.add(idEvento);
      const idForn = texto(it.data.id_fornecedor);
      if (idForn) idsFornecedor.add(idForn);
      const idSol = texto(it.data.id_solicitante);
      if (idSol) idsUsuario.add(idSol);
    }

    const eventos = await carregarMapaDocs(db, "evento", idsEvento);
    for (const ev of eventos.values()) {
      const uid = texto(ev.id_usuario) || texto(ev.idUsuario);
      if (uid) idsUsuario.add(uid);
    }

    const [fornecedores, usuarios] = await Promise.all([
      carregarMapaDocs(db, "fornecedor", idsFornecedor),
      carregarMapaDocs(db, "usuarios", idsUsuario),
    ]);

    const fatos: FatoComercial[] = [];
    const linhasContratacao: LinhaContratacaoAdmin[] = [];

    for (const it of itens) {
      const d = it.data;
      const idEvento = texto(d.id_evento);
      const evento = eventos.get(idEvento);
      const idOrganizador =
        texto(evento?.id_usuario) || texto(evento?.idUsuario) || "";
      const idSolicitante = texto(d.id_solicitante);
      const idFornecedor = texto(d.id_fornecedor);

      const linha = resolverLinhaContratacao({
        idOrcamento: it.id,
        orcamento: d,
        evento: evento ?? null,
        organizador: idOrganizador ? usuarios.get(idOrganizador) ?? null : null,
        contratante: idSolicitante
          ? usuarios.get(idSolicitante) ?? null
          : idOrganizador
            ? usuarios.get(idOrganizador) ?? null
            : null,
        pagador: idSolicitante
          ? usuarios.get(idSolicitante) ?? null
          : idOrganizador
            ? usuarios.get(idOrganizador) ?? null
            : null,
        fornecedor: idFornecedor ? fornecedores.get(idFornecedor) ?? null : null,
        valorContratadoCentavos: it.vals.contratado,
        pagoCentavos: it.vals.pago,
        contratado: it.contratado,
      });

      if (busca) {
        const hay = [
          linha.nome_evento,
          linha.nome_contratante,
          linha.nome_organizador,
          linha.nome_fornecedor,
          linha.nome_servico,
          linha.id_evento,
          linha.id_orcamento,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        if (!hay.includes(busca)) continue;
      }

      linhasContratacao.push(linha);

      fatos.push({
        idEvento,
        idOrcamento: it.id,
        idNecessidade: texto(d.id_necessidade) || texto(d.id_cotacao) || null,
        idFornecedor: idFornecedor || null,
        idServico:
          texto(d.id_servico_fornecido) || texto(d.id_servico) || null,
        contratado: it.contratado,
        valorOportunidadeCentavos: it.vals.oportunidade,
        valorContratadoCentavos: it.vals.contratado,
        pagoCentavos: it.vals.pago,
        alternativaAtiva: d.alternativa_ativa !== false ? true : false,
        dataEvento: it.dataEvento,
        dataContratacao: it.dataContrato,
        statusEvento: texto(d.status_evento) || texto(d.status) || null,
        consultaPagamentoCompleta: it.vals.pagoCompleto || !it.contratado,
      });
    }

    // Concilia pagamentos parciais (amostra limitada).
    const incompletos = fatos.filter(
      (f) => f.contratado && f.consultaPagamentoCompleta === false,
    );
    const amostra = incompletos.slice(0, 40);
    await Promise.all(
      amostra.map(async (f) => {
        const [liq, gastos] = await Promise.all([
          db
            .collection("orcamento")
            .doc(f.idOrcamento)
            .collection("liquidacoes")
            .limit(50)
            .get()
            .catch(() => null),
          db
            .collection("orcamento")
            .doc(f.idOrcamento)
            .collection("orcamento_gasto")
            .limit(50)
            .get()
            .catch(() => null),
        ]);
        let pago = 0;
        if (liq && !liq.empty) {
          for (const l of liq.docs) {
            const ld = l.data();
            const c = ld.valor?.centavos ?? ld.valor_centavos;
            if (typeof c === "number") pago += c;
            else if (typeof ld.valor === "number") {
              pago += Math.round(ld.valor * 100);
            }
          }
          f.pagoCentavos = pago;
          f.consultaPagamentoCompleta = true;
          const linha = linhasContratacao.find(
            (x) => x.id_orcamento === f.idOrcamento,
          );
          if (linha) linha.pago_centavos = pago;
        } else if (gastos && !gastos.empty) {
          for (const gdoc of gastos.docs) {
            const g = gdoc.data();
            if (typeof g.pago === "number") pago += Math.round(g.pago * 100);
          }
          f.pagoCentavos = pago;
          f.consultaPagamentoCompleta = true;
          const linha = linhasContratacao.find(
            (x) => x.id_orcamento === f.idOrcamento,
          );
          if (linha) linha.pago_centavos = pago;
        }
      }),
    );

    const [polSnap, comSnap] = await Promise.all([
      db
        .collection("plataforma_comissao_politicas")
        .where("ativa", "==", true)
        .limit(1)
        .get(),
      db.collection("plataforma_comissao_obrigacoes").limit(500).get(),
    ]);

    const comissoes: FatoComissao[] = comSnap.docs.map((d) => {
      const x = d.data();
      return {
        id: d.id,
        status: String(x.status ?? "gerada"),
        valorOriginalCentavos: Number(x.valor_original?.centavos ?? 0),
        valorAjustesCentavos: Number(x.valor_ajustes_centavos ?? 0),
        valorLiquidadoCentavos: Number(x.valor_liquidado?.centavos ?? 0),
        vencimento: x.vencimento_em ? String(x.vencimento_em) : null,
        idEvento: x.id_evento ? String(x.id_evento) : null,
      };
    });

    const despesasRaw =
      data.despesasPlataformaCentavos ?? data.despesas_plataforma_centavos;
    const despesas =
      typeof despesasRaw === "number" && Number.isInteger(despesasRaw)
        ? despesasRaw
        : null;

    const dash = agregarDashboardAdmin({
      fatos,
      comissoes,
      politicaComissaoAtiva: !polSnap.empty,
      despesasPlataformaCentavos: despesas,
      eixoTemporal: eixo,
    });

    // Enriquece linhas de evento com nomes (mesmo organizador; contratos listados).
    const linhasEventoEnriquecidas = (dash.linhasEvento as Array<Record<string, unknown>>).map(
      (linha) => {
        const idEvento = String(linha.id_evento ?? "");
        const contratosDoEvento = linhasContratacao.filter(
          (c) => c.id_evento === idEvento,
        );
        const primeiro = contratosDoEvento[0];
        return {
          ...linha,
          nome_evento: primeiro?.nome_evento ?? null,
          nome_organizador: primeiro?.nome_organizador ?? null,
          id_organizador: primeiro?.id_organizador ?? null,
          qtd_identidade_incompleta: contratosDoEvento.filter(
            (c) => c.identidade_incompleta,
          ).length,
          contratacoes: contratosDoEvento.map((c) => ({
            id_contrato: c.id_contrato,
            id_orcamento: c.id_orcamento,
            nome_fornecedor: c.nome_fornecedor,
            nome_servico: c.nome_servico,
            nome_contratante: c.nome_contratante,
            estado_comercial: c.estado_comercial,
            estado_execucao: c.estado_execucao,
            estado_execucao_rotulo: rotuloEstadoExecucao(c.estado_execucao),
            contratado: c.contratado,
            valor_contratado_centavos: c.valor_contratado_centavos,
            pago_centavos: c.pago_centavos,
            identidade_incompleta: c.identidade_incompleta,
            pendencias_identificacao: c.pendencias_identificacao,
            perfil_atual_separado: c.perfil_atual_separado,
            nome_fornecedor_atual: c.nome_fornecedor_atual,
          })),
        };
      },
    );

    const qtdIdentidadeIncompleta = linhasContratacao.filter(
      (c) => c.identidade_incompleta,
    ).length;

    return {
      ok: true,
      ...dash,
      linhasEvento: linhasEventoEnriquecidas,
      linhas_evento: linhasEventoEnriquecidas,
      linhasContratacao,
      linhas_contratacao: linhasContratacao,
      qtdIdentidadeIncompleta,
      qtd_identidade_incompleta: qtdIdentidadeIncompleta,
      origem_consulta: "consultarDashboardFinanceiroAdmin",
      consistencia: {
        idempotente: true,
        fonte_orcamentos: "orcamento + lote evento/fornecedor/usuarios",
        fonte_comissao: "plataforma_comissao_obrigacoes",
        exclui: ["custos_internos", "margens_fornecedor", "estoque_privado", "dados_bancarios"],
        limite_orcamentos: LIMITE_ORCAMENTOS,
        truncado,
        completo: dash.completo && !truncado,
        reprocessamento: "reexecutar callable; sem backfill de produção",
        identidade:
          "snapshot_aceite preferido; perfil atual separado; pendência sem inventar nome",
      },
      paginacao: {
        limite: LIMITE_ORCAMENTOS,
        retornados: orcSnap.size,
        truncado,
        aviso: truncado
          ? "Consulta limitada aos primeiros 500 orçamentos; não é inventário total."
          : null,
      },
      gerado_em: new Date().toISOString(),
    };
  },
);
