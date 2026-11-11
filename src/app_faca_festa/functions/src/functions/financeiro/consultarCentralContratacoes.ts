import { divisaoContrato, carregarContextoRepasse } from "../../services/financeiro/liberacaoRepasseService";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo } from "../../shared/auth";
import { carregarMapaDocs } from "../../shared/carregarMapaDocs";
import {
  resolverLinhaContratacao,
} from "../../services/financeiro/contratacaoIdentidadeService";
import { centavosDeOrcamento } from "../../services/financeiro/dashboardAdminService";
import {
  calcularDimensoesFinanceiras,
  montarLinhaCentral,
  capacidadesParaTipoUsuario,
} from "../../services/financeiro/mediacaoOperacionalService";
import {
  listarCasosPorContratos,
  carregarRegistrosCaso,
  casoDeDoc,
  COL_CASOS,
} from "../../services/financeiro/mediacaoPersistenciaService";
import {
  COL_ALOCACOES,
  COL_REPASSES,
} from "../../services/financeiro/intermediacaoPersistenciaService";

const REGION = "southamerica-east1";
const LIMITE = 200;

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

type ChavesContratacao = { id: string; idContrato: string };
type CasosPorContrato = Awaited<ReturnType<typeof listarCasosPorContratos>>;

function idsParaMediacao(itens: ChavesContratacao[]): string[] {
  return itens.flatMap(({ id, idContrato }) => [id, idContrato]);
}

async function carregarFinanceiroPagina(
  db: FirebaseFirestore.Firestore,
  pagina: ChavesContratacao[],
  casosFiltro: CasosPorContrato | null,
) {
  const idsOrc = pagina.map(({ id }) => id);
  const lotes: string[][] = [];
  for (let i = 0; i < idsOrc.length; i += 30) lotes.push(idsOrc.slice(i, i + 30));
  const [casosMap, comissoes, movimentos] = await Promise.all([
    casosFiltro ?? listarCasosPorContratos(db, idsParaMediacao(pagina)),
    carregarMapaDocs(db, "plataforma_comissao_obrigacoes",
      new Set(pagina.map(({ idContrato }) => `comissao-${idContrato}`))),
    Promise.all(lotes.map(fatia => Promise.all([
      db.collection(COL_ALOCACOES).where("id_orcamento", "in", fatia)
        .select("id_orcamento", "valor_centavos").get().catch(() => null),
      db.collection(COL_REPASSES).where("id_orcamento", "in", fatia)
        .select("id_orcamento", "valor_centavos", "estado").get().catch(() => null),
    ]))),
  ]);
  const alocadoPorOrc = new Map<string, number>();
  const repassadoPorOrc = new Map<string, number>();
  for (const [alocacoes, repasses] of movimentos) {
    for (const doc of alocacoes?.docs ?? []) {
      const { id_orcamento, valor_centavos } = doc.data();
      alocadoPorOrc.set(id_orcamento, (alocadoPorOrc.get(id_orcamento) ?? 0) + Number(valor_centavos ?? 0));
    }
    for (const doc of repasses?.docs ?? []) {
      const { id_orcamento, valor_centavos, estado } = doc.data();
      if (estado !== "confirmado") continue;
      repassadoPorOrc.set(id_orcamento, (repassadoPorOrc.get(id_orcamento) ?? 0) + Number(valor_centavos ?? 0));
    }
  }
  return { casosMap, comissoes, alocadoPorOrc, repassadoPorOrc };
}

/**
 * Central operacional: lista por contratação (não agrega fornecedores numa linha).
 * Completeness explícita; amostra ≠ inventário global.
 */
export const consultarCentralContratacoes = onCall(
  { region: REGION, timeoutSeconds: 120, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);
    const caps = capacidadesParaTipoUsuario(perfil.tipo);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const busca = texto(data.busca ?? data.q).toLowerCase();
    const estadoComercial = texto(data.estadoComercial ?? data.estado_comercial).toLowerCase();
    const estadoExecucao = texto(data.estadoExecucao ?? data.estado_execucao).toLowerCase();
    const casoAbertoFiltro = data.casoAberto ?? data.caso_aberto;
    const idResponsavel = texto(data.idResponsavel ?? data.id_responsavel);
    const eixo = texto(data.eixoTemporal ?? data.eixo_temporal) || "data_evento";
    const inicio = texto(data.periodoInicio ?? data.periodo_inicio);
    const fim = texto(data.periodoFim ?? data.periodo_fim);
    const agruparPorEvento = data.agruparPorEvento === true || data.agrupar_por_evento === true;
    const offset = Math.max(0, Number(data.offset ?? 0) || 0);
    const limite = Math.min(LIMITE, Math.max(1, Number(data.limite ?? 50) || 50));

    const db = admin.firestore();
    const [orcSnap, qtdCasosAbertos] = await Promise.all([
      db.collection("orcamento").limit(LIMITE).get(),
      db.collection(COL_CASOS)
        .where("estado", "in", ["aberto", "em_analise", "aguardando_partes", "em_decisao"])
        .limit(100).count().get().then(snap => snap.data().count).catch(() => null),
    ]);
    const truncado = orcSnap.size >= LIMITE;

    const itens: Array<{
      id: string;
      idContrato: string;
      data: Record<string, unknown>;
      contratado: boolean;
      vals: ReturnType<typeof centavosDeOrcamento>;
      dataEvento: string | null;
    }> = [];

    for (const doc of orcSnap.docs) {
      const d = doc.data() as Record<string, unknown>;
      const idEvento = texto(d.id_evento);
      if (!idEvento) continue;
      const status = texto(d.status).toLowerCase();
      const contratoMap =
        d.contrato_financeiro && typeof d.contrato_financeiro === "object"
          ? (d.contrato_financeiro as { id_contrato?: string; estado_comercial?: string; estado_execucao?: string })
          : null;
      const contratado =
        d.orcamento_fechado === true ||
        status === "fechado" ||
        status === "contratado" ||
        contratoMap?.estado_comercial === "contratado";

      if (estadoComercial === "contratado" && !contratado) continue;
      if (estadoComercial === "oportunidade" && contratado) continue;
      if (estadoExecucao) {
        const ex = texto(contratoMap?.estado_execucao || d.estado_execucao).toLowerCase();
        if (ex !== estadoExecucao) continue;
      }

      const dataEvento = parseData(d.data_evento) || parseData(d.data);
      const dataContrato = parseData(d.data_cadastro) || parseData(d.data_fechamento);
      if (inicio || fim) {
        const ref = eixo === "data_contratacao" ? dataContrato : dataEvento;
        if (ref) {
          if (inicio && ref < inicio) continue;
          if (fim && ref > fim) continue;
        }
      }

      itens.push({
        id: doc.id,
        idContrato: String(contratoMap?.id_contrato || doc.id),
        data: d,
        contratado,
        vals: centavosDeOrcamento(d),
        dataEvento,
      });
    }

    const filtrarPorCaso = typeof casoAbertoFiltro === "boolean" || !!idResponsavel;
    const casosFiltro = filtrarPorCaso ? await listarCasosPorContratos(db, idsParaMediacao(itens)) : null;
    const candidatos = casosFiltro ? itens.filter(it => {
      const caso = casosFiltro.get(it.idContrato) ?? casosFiltro.get(it.id);
      if (casoAbertoFiltro === true && !caso) return false;
      if (casoAbertoFiltro === false && caso) return false;
      return !idResponsavel || caso?.idResponsavel === idResponsavel;
    }) : itens;

    // Sem busca textual, a página é conhecida antes de ler nomes ou valores.
    const itensParaEnriquecer = busca ? candidatos : candidatos.slice(offset, offset + limite);
    const idsEvento = new Set<string>();
    const idsFornecedor = new Set<string>();
    const idsUsuario = new Set<string>();
    for (const it of itensParaEnriquecer) {
      const idEvento = texto(it.data.id_evento);
      if (idEvento) idsEvento.add(idEvento);
      const idForn = texto(it.data.id_fornecedor);
      if (idForn) idsFornecedor.add(idForn);
      const idSol = texto(it.data.id_solicitante);
      if (idSol) idsUsuario.add(idSol);
    }
    const [eventos, fornecedores, usuarios, financeiroDireto] = await Promise.all([
      carregarMapaDocs(db, "evento", idsEvento),
      carregarMapaDocs(db, "fornecedor", idsFornecedor),
      carregarMapaDocs(db, "usuarios", idsUsuario),
      busca ? null : carregarFinanceiroPagina(db, itensParaEnriquecer, casosFiltro),
    ]);
    const organizadoresRestantes = new Set<string>();
    for (const ev of eventos.values()) {
      const uid = texto(ev.id_usuario) || texto(ev.idUsuario);
      if (uid && !idsUsuario.has(uid)) organizadoresRestantes.add(uid);
    }
    for (const [uid, usuario] of await carregarMapaDocs(db, "usuarios", organizadoresRestantes)) {
      usuarios.set(uid, usuario);
    }

    const filtradas = [];
    for (const it of itensParaEnriquecer) {
      const d = it.data;
      const idEvento = texto(d.id_evento);
      const evento = eventos.get(idEvento);
      const idOrganizador = texto(evento?.id_usuario) || texto(evento?.idUsuario) || "";
      const idSolicitante = texto(d.id_solicitante);
      const idFornecedor = texto(d.id_fornecedor);
      const { idContrato } = it;

      const linhaId = resolverLinhaContratacao({
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
          linhaId.nome_evento,
          linhaId.nome_contratante,
          linhaId.nome_fornecedor,
          linhaId.nome_servico,
          linhaId.descricao_escopo,
          linhaId.id_evento,
          linhaId.id_orcamento,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        if (!hay.includes(busca)) continue;
      }

      filtradas.push({ it, idContrato, idEvento, evento, linhaId });
    }

    // Os totais de paginação dependem dos filtros, mas o financeiro só é
    // necessário para as linhas que serão devolvidas ao aplicativo.
    const totalFiltrado = busca ? filtradas.length : candidatos.length;
    const pagina = busca ? filtradas.slice(offset, offset + limite) : filtradas;
    const { casosMap, comissoes, alocadoPorOrc, repassadoPorOrc } =
      financeiroDireto ?? await carregarFinanceiroPagina(db, pagina.map(({ it }) => it), casosFiltro);

    const linhas = pagina.map(({ it, idContrato, idEvento, evento, linhaId }) => {
      const d = it.data;
      const caso = casosMap.get(idContrato) ?? casosMap.get(it.id) ?? null;
      const obrigacao = comissoes.get(`comissao-${idContrato}`);
      const divisao = divisaoContrato(d, obrigacao ? [obrigacao] : []);
      const fin = calcularDimensoesFinanceiras({
        valorContratadoCentavos: it.vals.contratado,
        recebidoAlocadoCentavos: alocadoPorOrc.get(it.id) ?? 0,
        repassadoConfirmadoCentavos: repassadoPorOrc.get(it.id) ?? 0,
      });

      fin.aReceberClienteCentavos = Math.max(0, (divisao?.precoClienteCentavos ?? it.vals.contratado) - fin.recebidoClienteAlocadoCentavos - (divisao?.comissaoExternaOrganizadorCentavos ?? 0));
      fin.remuneracaoAppPrevistaCentavos = divisao?.comissaoCentavos ?? 0;
      fin.pendenteRepasseCentavos = divisao ? Math.max(0, divisao.direitoFornecedorCentavos - fin.repassadoConfirmadoCentavos) : 0;
      const linha = montarLinhaCentral({
        idContrato,
        idOrcamento: it.id,
        idEvento,
        nomeEvento: linhaId.nome_evento,
        dataEvento: it.dataEvento,
        nomeContratante: linhaId.nome_contratante,
        nomeFornecedor: linhaId.nome_fornecedor,
        nomeServico: linhaId.nome_servico,
        escopoCurto: linhaId.descricao_escopo,
        estadoComercial: linhaId.estado_comercial,
        estadoExecucao: linhaId.estado_execucao,
        identidadeIncompleta: linhaId.identidade_incompleta,
        pendenciasIdentificacao: linhaId.pendencias_identificacao,
        financeiro: fin,
        casoAberto: caso,
      });
      return {
        ...linha,
        comissao_centavos: divisao?.comissaoCentavos ?? null,
        liquido_fornecedor_centavos: divisao?.direitoFornecedorCentavos ?? null,
        regra_repasse: !it.contratado ? "Aguardando contratação" :
          caso ? "Mediação em aberto: pagamento bloqueado" :
          evento?.status === "finalizado" ? "Evento finalizado: conferir saldo para repasse" :
          "Pagamento após o evento ou com autorização explícita do organizador",
        id_organizador: linhaId.id_organizador,
        nome_organizador: linhaId.nome_organizador,
        id_pagador: linhaId.id_pagador,
        nome_pagador: linhaId.nome_pagador,
        id_contratante: linhaId.id_contratante,
        id_fornecedor: linhaId.id_fornecedor,
        perfil_atual_separado: linhaId.perfil_atual_separado,
      };
    });

    let gruposEvento: Array<Record<string, unknown>> | null = null;
    if (agruparPorEvento) {
      const map = new Map<string, typeof linhas>();
      for (const l of linhas) {
        const k = l.idEvento;
        if (!map.has(k)) map.set(k, []);
        map.get(k)!.push(l);
      }
      gruposEvento = [...map.entries()].map(([idEvento, contratacoes]) => ({
        id_evento: idEvento,
        nome_evento: contratacoes[0]?.nomeEvento ?? null,
        qtd_contratacoes: contratacoes.length,
        contratacoes,
      }));
    }

    return {
      ok: true,
      capacidades: caps,
      linhas,
      grupos_evento: gruposEvento,
      filtros: {
        busca: busca || null,
        estado_comercial: estadoComercial || null,
        estado_execucao: estadoExecucao || null,
        caso_aberto: casoAbertoFiltro ?? null,
        id_responsavel: idResponsavel || null,
        eixo_temporal: eixo,
        periodo_inicio: inicio || null,
        periodo_fim: fim || null,
      },
      paginacao: {
        offset,
        limite,
        retornados: linhas.length,
        total_filtrado_amostra: totalFiltrado,
        truncado,
        aviso: truncado
          ? "Consulta limitada; contadores desta tela não são inventário global."
          : totalFiltrado > limite
            ? "Lista paginada da amostra filtrada; não trate como total completo do sistema."
            : null,
      },
      metricas_amostra: {
        qtd_linhas_filtradas: totalFiltrado,
        qtd_casos_abertos_amostra: qtdCasosAbertos,
        completo: !truncado,
      },
      gerado_em: new Date().toISOString(),
    };
  },
);

export const consultarDetalheContratacao = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    exigirTipo(perfil, ["A"]);

    const data = (request.data ?? {}) as Record<string, unknown>;
    const idOrcamento = texto(data.idOrcamento ?? data.id_orcamento);
    if (!idOrcamento) {
      throw new HttpsError("invalid-argument", "Informe idOrcamento.");
    }
    const db = admin.firestore();
    const [contexto, alocSnap, repSnap] = await Promise.all([
      db.runTransaction(tx => carregarContextoRepasse(db, tx, idOrcamento), { readOnly: true }),
      db.collection(COL_ALOCACOES).where("id_orcamento", "==", idOrcamento).get().catch(() => null),
      db.collection(COL_REPASSES).where("id_orcamento", "==", idOrcamento).get().catch(() => null),
    ]);
    const { orcamento: d, evento, idContrato } = contexto;
    const idEvento = texto(d.id_evento);
    const idOrg = texto(evento?.id_usuario) || texto(evento?.idUsuario);
    const idsU = new Set<string>();
    if (idOrg) idsU.add(idOrg);
    if (texto(d.id_solicitante)) idsU.add(texto(d.id_solicitante));

    const encerrados = contexto.casos.filter(c => (c as any).estado === "fechado")
      .sort((a, b) => String((b as any).fechado_em ?? "").localeCompare(String((a as any).fechado_em ?? "")));
    const [fornSnap, usuarios, mediacao] = await Promise.all([
      texto(d.id_fornecedor) ? db.collection("fornecedor").doc(texto(d.id_fornecedor)).get() : null,
      carregarMapaDocs(db, "usuarios", idsU),
      (async () => {
        const casos = await listarCasosPorContratos(db, [String(idContrato), idOrcamento]);
        const caso = casos.get(String(idContrato)) ?? casos.get(idOrcamento) ?? null;
        const encerrado = encerrados[0];
        const selecionado = caso ?? (encerrado ? casoDeDoc(encerrado.id, encerrado) : null);
        const registros = data.incluirRegistros === true && selecionado
          ? await carregarRegistrosCaso(db, {
            idCaso: selecionado.id,
            papel: "admin",
            caps: capacidadesParaTipoUsuario(perfil.tipo),
          }).catch(() => null)
          : null;
        return { caso, consultaCaso: registros !== null ? { caso: selecionado, registros } : null };
      })(),
    ]);

    const vals = centavosDeOrcamento(d);
    const contratado =
      d.orcamento_fechado === true ||
      texto(d.status).toLowerCase() === "fechado" ||
      texto(d.status).toLowerCase() === "contratado";

    const linha = resolverLinhaContratacao({
      idOrcamento,
      orcamento: d,
      evento,
      organizador: idOrg ? usuarios.get(idOrg) ?? null : null,
      contratante: texto(d.id_solicitante)
        ? usuarios.get(texto(d.id_solicitante)) ?? null
        : idOrg
          ? usuarios.get(idOrg) ?? null
          : null,
      pagador: texto(d.id_solicitante)
        ? usuarios.get(texto(d.id_solicitante)) ?? null
        : idOrg
          ? usuarios.get(idOrg) ?? null
          : null,
      fornecedor: fornSnap?.exists
        ? (fornSnap.data() as Record<string, unknown>)
        : null,
      valorContratadoCentavos: vals.contratado,
      pagoCentavos: vals.pago,
      contratado,
    });

    let alocado = 0;
    const alocacoes: Array<Record<string, unknown>> = [];
    if (alocSnap) {
      for (const doc of alocSnap.docs) {
        const x = doc.data();
        alocado += Number(x.valor_centavos ?? 0);
        alocacoes.push({ id: doc.id, ...x });
      }
    }
    let repassado = 0;
    const repasses: Array<Record<string, unknown>> = [];
    if (repSnap) {
      for (const doc of repSnap.docs) {
        const x = doc.data();
        if (String(x.estado ?? "") === "confirmado") {
          repassado += Number(x.valor_centavos ?? 0);
        }
        repasses.push({ id: doc.id, ...x });
      }
    }

    const fin = calcularDimensoesFinanceiras({
      valorContratadoCentavos: vals.contratado,
      recebidoAlocadoCentavos: alocado,
      repassadoConfirmadoCentavos: repassado,
    });

    const divisao = contexto.divisao;
    fin.aReceberClienteCentavos = Math.max(0, (divisao?.precoClienteCentavos ?? vals.contratado) - alocado - (divisao?.comissaoExternaOrganizadorCentavos ?? 0));
    fin.remuneracaoAppPrevistaCentavos = divisao?.comissaoCentavos ?? 0;
    fin.pendenteRepasseCentavos = divisao ? Math.max(0, divisao.direitoFornecedorCentavos - repassado) : 0;
    const { caso, consultaCaso } = mediacao;

    // Contatos autorizados (mínimo) — sem dados bancários.
    const contatoContratante = (() => {
      const u = texto(d.id_solicitante)
        ? usuarios.get(texto(d.id_solicitante))
        : idOrg
          ? usuarios.get(idOrg)
          : null;
      if (!u) return null;
      return {
        nome: linha.nome_contratante,
        email: texto(u.email) || null,
        telefone: texto(u.telefone) || texto(u.celular) || null,
      };
    })();
    const contatoFornecedor = (() => {
      if (!fornSnap?.exists) return null;
      const f = fornSnap.data() as Record<string, unknown>;
      return {
        nome: linha.nome_fornecedor,
        email: texto(f.email) || null,
        telefone: texto(f.telefone) || texto(f.whatsapp) || null,
      };
    })();

    return {
      ok: true,
      resumo: montarLinhaCentral({
        idContrato: String(idContrato),
        idOrcamento,
        idEvento,
        nomeEvento: linha.nome_evento,
        dataEvento: parseData(d.data_evento),
        nomeContratante: linha.nome_contratante,
        nomeFornecedor: linha.nome_fornecedor,
        nomeServico: linha.nome_servico,
        escopoCurto: linha.descricao_escopo,
        estadoComercial: linha.estado_comercial,
        estadoExecucao: linha.estado_execucao,
        identidadeIncompleta: linha.identidade_incompleta,
        pendenciasIdentificacao: linha.pendencias_identificacao,
        financeiro: fin,
        casoAberto: caso,
      }),
      partes: {
        organizador: {
          id: linha.id_organizador,
          nome: linha.nome_organizador,
        },
        contratante: {
          id: linha.id_contratante,
          nome: linha.nome_contratante,
          contato: contatoContratante,
        },
        pagador: {
          id: linha.id_pagador,
          nome: linha.nome_pagador,
        },
        fornecedor: {
          id: linha.id_fornecedor,
          nome: linha.nome_fornecedor,
          contato: contatoFornecedor,
        },
        perfil_atual_separado: linha.perfil_atual_separado,
        snapshot_aceite: linha.snapshot_aceite,
      },
      contratacao_servico: {
        id_orcamento: idOrcamento,
        id_contrato: idContrato,
        nome_servico: linha.nome_servico,
        escopo: linha.descricao_escopo,
        estado_comercial: linha.estado_comercial,
        estado_execucao: linha.estado_execucao,
        // Pagamento ≠ entrega prestada.
        aviso_execucao:
          "Contrato formalizado ou pagamento não comprovam serviço prestado.",
      },
      financeiro: {
        ...fin,
        legado_pago_centavos: vals.pago,
        comissao_centavos: divisao?.comissaoCentavos ?? null,
        direito_fornecedor_centavos: divisao?.direitoFornecedorCentavos ?? null,
        comissao_recebida_separadamente_centavos: divisao?.comissaoRecebidaSeparadamenteCentavos ?? 0,
        motivo_bloqueio: contexto.motivo,
        aviso:
          "pago legado ≠ recebido plataforma; dimensões não são somáveis entre si.",
        alocacoes,
        repasses,
      },
      historico_mediacao: {
        caso_aberto: caso,
        ultimo_caso_encerrado: encerrados[0] ?? null,
        ...(consultaCaso ? { consulta_caso: consultaCaso } : {}),
      },
      capacidades: capacidadesParaTipoUsuario(perfil.tipo),
    };
  },
);
