import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo } from "../../shared/auth";
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

async function carregarMapaDocs(
  db: FirebaseFirestore.Firestore,
  colecao: string,
  ids: Set<string>,
): Promise<Map<string, Record<string, unknown>>> {
  const mapa = new Map<string, Record<string, unknown>>();
  const lista = [...ids].filter(Boolean);
  for (let i = 0; i < lista.length; i += 100) {
    const fatia = lista.slice(i, i + 100);
    await Promise.all(
      fatia.map(async (id) => {
        const snap = await db.collection(colecao).doc(id).get();
        if (snap.exists) mapa.set(id, (snap.data() ?? {}) as Record<string, unknown>);
      }),
    );
  }
  return mapa;
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
    const orcSnap = await db.collection("orcamento").limit(LIMITE).get();
    const truncado = orcSnap.size >= LIMITE;

    const itens: Array<{
      id: string;
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
          ? (d.contrato_financeiro as { estado_comercial?: string; estado_execucao?: string })
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
        data: d,
        contratado,
        vals: centavosDeOrcamento(d),
        dataEvento,
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

    const idsContrato = itens.map((it) => {
      const cf = it.data.contrato_financeiro;
      if (cf && typeof cf === "object" && (cf as { id?: string }).id) {
        return String((cf as { id: string }).id);
      }
      return it.id;
    });
    const casosMap = await listarCasosPorContratos(db, idsContrato);

    // Agregados de intermediação por orçamento (amostra).
    const alocadoPorOrc = new Map<string, number>();
    const repassadoPorOrc = new Map<string, number>();
    const idsOrc = itens.map((i) => i.id);
    for (let i = 0; i < idsOrc.length; i += 10) {
      const fatia = idsOrc.slice(i, i + 10);
      const [alocSnap, repSnap] = await Promise.all([
        db.collection(COL_ALOCACOES).where("id_orcamento", "in", fatia).limit(100).get().catch(() => null),
        db.collection(COL_REPASSES).where("id_orcamento", "in", fatia).limit(100).get().catch(() => null),
      ]);
      if (alocSnap) {
        for (const d of alocSnap.docs) {
          const x = d.data();
          const id = String(x.id_orcamento ?? "");
          alocadoPorOrc.set(id, (alocadoPorOrc.get(id) ?? 0) + Number(x.valor_centavos ?? 0));
        }
      }
      if (repSnap) {
        for (const d of repSnap.docs) {
          const x = d.data();
          if (String(x.estado ?? "") !== "confirmado") continue;
          const id = String(x.id_orcamento ?? "");
          repassadoPorOrc.set(id, (repassadoPorOrc.get(id) ?? 0) + Number(x.valor_centavos ?? 0));
        }
      }
    }

    let linhas = [];
    for (const it of itens) {
      const d = it.data;
      const idEvento = texto(d.id_evento);
      const evento = eventos.get(idEvento);
      const idOrganizador = texto(evento?.id_usuario) || texto(evento?.idUsuario) || "";
      const idSolicitante = texto(d.id_solicitante);
      const idFornecedor = texto(d.id_fornecedor);
      const idContrato =
        (d.contrato_financeiro &&
          typeof d.contrato_financeiro === "object" &&
          (d.contrato_financeiro as { id?: string }).id) ||
        it.id;

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

      const caso = casosMap.get(String(idContrato)) ?? casosMap.get(it.id) ?? null;
      if (casoAbertoFiltro === true && !caso) continue;
      if (casoAbertoFiltro === false && caso) continue;
      if (idResponsavel && (!caso || caso.idResponsavel !== idResponsavel)) continue;

      const fin = calcularDimensoesFinanceiras({
        valorContratadoCentavos: it.vals.contratado,
        recebidoAlocadoCentavos: alocadoPorOrc.get(it.id) ?? 0,
        repassadoConfirmadoCentavos: repassadoPorOrc.get(it.id) ?? 0,
      });

      const linha = montarLinhaCentral({
        idContrato: String(idContrato),
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
      linhas.push({
        ...linha,
        id_organizador: linhaId.id_organizador,
        nome_organizador: linhaId.nome_organizador,
        id_pagador: linhaId.id_pagador,
        nome_pagador: linhaId.nome_pagador,
        id_contratante: linhaId.id_contratante,
        id_fornecedor: linhaId.id_fornecedor,
        perfil_atual_separado: linhaId.perfil_atual_separado,
      });
    }

    const totalFiltrado = linhas.length;
    linhas = linhas.slice(offset, offset + limite);

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

    const qtdCasosAbertosSnap = await db
      .collection(COL_CASOS)
      .where("estado", "in", ["aberto", "em_analise", "aguardando_partes", "em_decisao"])
      .limit(100)
      .get()
      .catch(() => null);

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
        qtd_casos_abertos_amostra: qtdCasosAbertosSnap?.size ?? null,
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
    const orcSnap = await db.collection("orcamento").doc(idOrcamento).get();
    if (!orcSnap.exists) {
      throw new HttpsError("not-found", "Contratação não encontrada.");
    }
    const d = orcSnap.data() as Record<string, unknown>;
    const idEvento = texto(d.id_evento);
    const [eventoSnap, fornSnap] = await Promise.all([
      idEvento ? db.collection("evento").doc(idEvento).get() : null,
      texto(d.id_fornecedor)
        ? db.collection("fornecedor").doc(texto(d.id_fornecedor)).get()
        : null,
    ]);
    const evento = eventoSnap?.exists ? (eventoSnap.data() as Record<string, unknown>) : null;
    const idOrg = texto(evento?.id_usuario) || texto(evento?.idUsuario);
    const idsU = new Set<string>();
    if (idOrg) idsU.add(idOrg);
    if (texto(d.id_solicitante)) idsU.add(texto(d.id_solicitante));
    const usuarios = await carregarMapaDocs(db, "usuarios", idsU);

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

    const idContrato =
      (d.contrato_financeiro &&
        typeof d.contrato_financeiro === "object" &&
        (d.contrato_financeiro as { id?: string }).id) ||
      idOrcamento;

    const [alocSnap, repSnap, casosMap] = await Promise.all([
      db.collection(COL_ALOCACOES).where("id_orcamento", "==", idOrcamento).limit(50).get().catch(() => null),
      db.collection(COL_REPASSES).where("id_orcamento", "==", idOrcamento).limit(50).get().catch(() => null),
      listarCasosPorContratos(db, [String(idContrato), idOrcamento]),
    ]);

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

    const caso =
      casosMap.get(String(idContrato)) ?? casosMap.get(idOrcamento) ?? null;

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
        aviso:
          "pago legado ≠ recebido plataforma; dimensões não são somáveis entre si.",
        alocacoes,
        repasses,
      },
      historico_mediacao: {
        caso_aberto: caso,
      },
      capacidades: capacidadesParaTipoUsuario(perfil.tipo),
    };
  },
);
