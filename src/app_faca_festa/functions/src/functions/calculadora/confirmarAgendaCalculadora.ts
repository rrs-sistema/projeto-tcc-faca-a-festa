import {onCall,HttpsError} from "firebase-functions/v2/https";
import {admin} from "../../shared/firebaseAdmin";
import {confirmarAgendaServico} from "../../services/calculadora/agendaServicoService";
export const confirmarAgendaCalculadora=onCall({region:"southamerica-east1",timeoutSeconds:120,memory:"512MiB",cors:true},req=>{
 if(process.env.FUNCTIONS_EMULATOR==="true"&&(!String(process.env.GCLOUD_PROJECT??"").startsWith("demo-")||!/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST??""))) throw new HttpsError("failed-precondition","Testes de agenda exigem projeto demo e Firestore local.");
 return confirmarAgendaServico(admin.firestore(),req.auth?.uid,req.data);
});
