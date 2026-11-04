import { onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado, exigirTipo } from "../../shared/auth";
import { emitirProposta } from "../../services/cotacao/jornadaAtendimentoService";
export const responderCotacao=onCall({region:"southamerica-east1",timeoutSeconds:45,cors:true},async req=>{
 const p=await exigirUsuarioAutenticado(req.auth?.uid);exigirTipo(p,["F"]);return emitirProposta(admin.firestore(),p.uid,req.data);
});
