import { HttpsError } from "firebase-functions/v2/https";
export function validarPoliticaPublico(cfg: Record<string, any>): void {
  const falha = () => { throw new HttpsError("failed-precondition", "Confira a configuração privada de público."); };
  if (!cfg || typeof cfg !== "object" || Array.isArray(cfg)) falha();
  const v=cfg.verba_confirmacao;
  if(v!=null&&(v.versao!==1||v.fonte!=="organizador"||typeof v.confirmado_por!=="string"||!Number.isFinite(Date.parse(v.confirmado_em))))falha();
  if (Object.prototype.hasOwnProperty.call(cfg, "duracao") && (!Number.isInteger(cfg.duracao) || cfg.duracao < 1 || cfg.duracao > 24)) falha();
  if (Object.prototype.hasOwnProperty.call(cfg, "perfil") && !["economico","padrao","premium"].includes(cfg.perfil)) falha();
  for (const k of ["margem","verba_alimentacao"]) {
    const v = cfg[k];
    if (v != null && (typeof v !== "number" || !Number.isFinite(v) || v < 0 || v > (k === "margem" ? .3 : 1000000))) falha();
  }
  if (cfg.confirmacoes !== undefined && (!cfg.confirmacoes || typeof cfg.confirmacoes !== "object" || Array.isArray(cfg.confirmacoes) || Object.keys(cfg.confirmacoes).length > 20 || Object.values(cfg.confirmacoes).some(v => typeof v !== "string" || v.length > 5000))) falha();
  if (Object.prototype.hasOwnProperty.call(cfg, "lista_completude") && !["desconhecida", "em_preenchimento", "concluida"].includes(cfg.lista_completude)) falha();
  if (Object.prototype.hasOwnProperty.call(cfg, "base_confirmada") && typeof cfg.base_confirmada !== "boolean") falha();
  if (Object.prototype.hasOwnProperty.call(cfg, "base") && !["manual", "previstos", "todos", "nao_recusados", "confirmados"].includes(cfg.base)) falha();
  if (cfg.base_confirmada === true && !cfg.base) falha();
  if (cfg.publico !== undefined) {
    const p = cfg.publico;
    if (!p || typeof p !== "object" || Array.isArray(p) || Object.keys(p).some(k => !["adultos", "criancas", "bebes"].includes(k))) falha();
    for (const k of ["adultos", "criancas", "bebes"]) if (!Number.isInteger(p[k]) || p[k] < 0 || p[k] > 1000000) falha();
  }
  if (cfg.base_confirmada === true && cfg.base === "manual" && cfg.publico === undefined) falha();
}
