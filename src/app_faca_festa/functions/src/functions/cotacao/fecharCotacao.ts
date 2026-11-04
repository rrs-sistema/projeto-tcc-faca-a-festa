import { onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { contratarProposta } from "../../services/cotacao/jornadaAtendimentoService";
import { tentarGerarComissaoAposContratacao } from "../financeiro/comandosComissaoPlataforma";
export const fecharCotacao=onCall({region:"southamerica-east1",timeoutSeconds:60,cors:true},async req=>{
 const p=await exigirUsuarioAutenticado(req.auth?.uid),r=await contratarProposta(admin.firestore(),p.uid,req.data);
 await tentarGerarComissaoAposContratacao({idEvento:r.idEvento,idContrato:r.idOrcamento,baseBrutaCentavos:Math.round(r.valorContratado*100),idFornecedor:req.data.idFornecedor??req.data.id_fornecedor,idPagador:req.data.idFornecedor??req.data.id_fornecedor,autorId:p.uid});return r;
});
