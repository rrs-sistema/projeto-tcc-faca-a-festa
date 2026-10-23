import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo, PerfilAuth } from "../../shared/auth";
import {
  capacidadesParaTipoUsuario,
  casoPertenceAoVinculo,
  CategoriaCaso,
  PrioridadeCaso,
  TipoDecisaoMediacao,
  TipoRegistroMediacao,
  VisibilidadeRegistro,
  temCapacidade,
  registrosParaExportacao,
} from "../../services/financeiro/mediacaoOperacionalService";
import {
  abrirCasoMediacao,
  adicionarRegistro,
  atribuirResponsavel,
  carregarCasoComRegistros,
  fecharCaso,
  recomendarBloqueio,
  registrarDecisao,
} from "../../services/financeiro/mediacaoPersistenciaService";

const REGION = "southamerica-east1";

function texto(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

async function exigirAdmin(uid: string | undefined): Promise<PerfilAuth> {
  const perfil = await exigirUsuarioAutenticado(uid);
  exigirTipo(perfil, ["A"]);
  return perfil;
}

export const abrirCasoMediacaoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    if (!temCapacidade(capacidadesParaTipoUsuario(perfil.tipo), "decisao_mediacao")) {
      throw new HttpsError("permission-denied", "Sem capacidade de mediação.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    return abrirCasoMediacao(admin.firestore(), {
      idEvento: texto(data.idEvento ?? data.id_evento),
      idContrato: texto(data.idContrato ?? data.id_contrato),
      idOrcamento: texto(data.idOrcamento ?? data.id_orcamento),
      idFornecedor: texto(data.idFornecedor ?? data.id_fornecedor) || null,
      idContratante: texto(data.idContratante ?? data.id_contratante) || null,
      categoria: (texto(data.categoria) || "outro") as CategoriaCaso,
      motivo: texto(data.motivo),
      descricao: texto(data.descricao),
      prioridade: (texto(data.prioridade) || "normal") as PrioridadeCaso,
      chaveIdempotencia: texto(data.chaveIdempotencia ?? data.chave_idempotencia),
      autorId: perfil.uid,
    });
  },
);

export const atribuirResponsavelCasoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const caso = await atribuirResponsavel(admin.firestore(), {
      idCaso: texto(data.idCaso ?? data.id_caso),
      idResponsavel: texto(data.idResponsavel ?? data.id_responsavel),
      autorId: perfil.uid,
    });
    return { ok: true, caso };
  },
);

export const registrarRegistroMediacaoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const tipo = (texto(data.tipo) || "analise") as TipoRegistroMediacao;
    const visRaw = texto(data.visibilidade);
    let visibilidade: VisibilidadeRegistro | undefined;
    if (visRaw === "interna" || visRaw === "compartilhavel") {
      visibilidade = visRaw;
    }
    if (tipo === "nota_interna") {
      if (!temCapacidade(capacidadesParaTipoUsuario(perfil.tipo), "notas_internas")) {
        throw new HttpsError("permission-denied", "Sem capacidade de notas internas.");
      }
      visibilidade = "interna";
    }
    const r = await adicionarRegistro(admin.firestore(), {
      idCaso: texto(data.idCaso ?? data.id_caso),
      tipo,
      texto: texto(data.texto),
      visibilidade,
      autorId: perfil.uid,
      novoEstado: texto(data.novoEstado ?? data.novo_estado) as
        | "em_analise"
        | "aguardando_partes"
        | undefined,
    });
    return { ok: true, ...r };
  },
);

export const solicitarInformacaoCasoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    // Sem disparo externo — só registro no fluxo.
    const r = await adicionarRegistro(admin.firestore(), {
      idCaso: texto(data.idCaso ?? data.id_caso),
      tipo: "solicitacao_info",
      texto: texto(data.texto),
      visibilidade: "compartilhavel",
      autorId: perfil.uid,
      novoEstado: "aguardando_partes",
    });
    return {
      ok: true,
      ...r,
      aviso:
        "Solicitação registrada no caso. Nenhum e-mail/WhatsApp foi enviado automaticamente.",
    };
  },
);

export const registrarDecisaoCasoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    if (!temCapacidade(capacidadesParaTipoUsuario(perfil.tipo), "decisao_mediacao")) {
      throw new HttpsError("permission-denied", "Sem capacidade de decisão.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    const refs = Array.isArray(data.referenciasComandos ?? data.referencias_comandos)
      ? ((data.referenciasComandos ?? data.referencias_comandos) as unknown[]).map(String)
      : [];
    const r = await registrarDecisao(admin.firestore(), {
      idCaso: texto(data.idCaso ?? data.id_caso),
      tipoDecisao: (texto(data.tipoDecisao ?? data.tipo_decisao) ||
        "manter") as TipoDecisaoMediacao,
      texto: texto(data.texto),
      autorId: perfil.uid,
      referenciasComandos: refs,
      compartilharComPartes:
        data.compartilharComPartes === true || data.compartilhar_com_partes === true,
    });
    return {
      ok: true,
      ...r,
      aviso:
        "Decisão registrada. Nenhum reembolso/repasse foi executado automaticamente.",
    };
  },
);

export const fecharCasoMediacaoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const r = await fecharCaso(admin.firestore(), {
      idCaso: texto(data.idCaso ?? data.id_caso),
      conclusao: texto(data.conclusao),
      autorId: perfil.uid,
    });
    return {
      ok: true,
      ...r,
      aviso: "Caso fechado sem movimento financeiro silencioso.",
    };
  },
);

export const recomendarBloqueioRevisaoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirAdmin(request.auth?.uid);
    if (
      !temCapacidade(
        capacidadesParaTipoUsuario(perfil.tipo),
        "autorizacao_financeira",
      )
    ) {
      throw new HttpsError("permission-denied", "Sem autorização financeira.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    const r = await recomendarBloqueio(admin.firestore(), {
      idCaso: texto(data.idCaso ?? data.id_caso),
      motivo: texto(data.motivo),
      autorId: perfil.uid,
      // Política de retenção ainda não definida.
      politicaRetencaoAtiva: false,
    });
    return {
      ok: true,
      ...r,
      aviso:
        "Recomendação de revisão no contrato afetado. Sem retenção automática (política não definida).",
    };
  },
);

/**
 * Consulta de caso com filtro de visibilidade.
 * Admin: tudo (com notas internas). Cliente/fornecedor: só compartilhável do próprio vínculo.
 */
export const consultarCasoMediacaoFn = onCall(
  { region: REGION, timeoutSeconds: 60, cors: true },
  async (request) => {
    const perfil = await exigirUsuarioAutenticado(request.auth?.uid);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const idCaso = texto(data.idCaso ?? data.id_caso);
    if (!idCaso) {
      throw new HttpsError("invalid-argument", "Informe idCaso.");
    }

    const caps = capacidadesParaTipoUsuario(perfil.tipo);
    const papel =
      perfil.tipo === "A"
        ? "admin"
        : texto(data.papelConsulta ?? data.papel_consulta) === "fornecedor"
          ? "fornecedor"
          : "cliente";

    const db = admin.firestore();
    // Carrega bruto para checar vínculo antes de filtrar.
    const { caso } = await carregarCasoComRegistros(db, {
      idCaso,
      papel: "admin",
      caps: capacidadesParaTipoUsuario("A"),
    });

    if (papel !== "admin") {
      let idFornecedorOperador: string | null = null;
      if (papel === "fornecedor") {
        idFornecedorOperador =
          texto(data.idFornecedorOperador ?? data.id_fornecedor_operador) || null;
      }
      if (
        !casoPertenceAoVinculo({
          caso,
          papel,
          uid: perfil.uid,
          idFornecedorOperador,
        })
      ) {
        throw new HttpsError("permission-denied", "Caso fora do seu vínculo.");
      }
    }

    const filtrados = await carregarCasoComRegistros(db, {
      idCaso,
      papel,
      caps,
    });

    const exportaveis = registrosParaExportacao(filtrados.registros);

    return {
      ok: true,
      caso: filtrados.caso,
      registros: filtrados.registros,
      exportacao_compartilhavel: exportaveis,
      capacidades: caps,
      papel_consulta: papel,
    };
  },
);
