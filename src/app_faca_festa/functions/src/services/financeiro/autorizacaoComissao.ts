import { HttpsError } from "firebase-functions/v2/https";
import { PerfilAuth, exigirTipo } from "../../shared/auth";

/** Configurar política: somente administrador da plataforma. */
export function exigirConfigurarPoliticaComissao(perfil: PerfilAuth): void {
  exigirTipo(perfil, ["A"]);
}

/**
 * Liquidar/estornar: administrador (papel distinto modelado;
 * hoje mesmo tipo A — claim futuro `comissao_liquidar` possível).
 */
export function exigirLiquidarComissao(perfil: PerfilAuth): void {
  exigirTipo(perfil, ["A"]);
}

/** Extrato admin: tipo A. Pagador: somente próprias obrigações. */
export function exigirLeituraExtratoComissao(
  perfil: PerfilAuth,
  idPagadorFiltro?: string | null,
): { modo: "admin" | "pagador"; idPagador?: string } {
  if (perfil.tipo === "A") {
    return { modo: "admin" };
  }
  if (idPagadorFiltro && idPagadorFiltro === perfil.uid) {
    return { modo: "pagador", idPagador: perfil.uid };
  }
  if (!idPagadorFiltro) {
    return { modo: "pagador", idPagador: perfil.uid };
  }
  throw new HttpsError(
    "permission-denied",
    "Sem acesso cruzado ao extrato de comissões de outro pagador.",
  );
}
