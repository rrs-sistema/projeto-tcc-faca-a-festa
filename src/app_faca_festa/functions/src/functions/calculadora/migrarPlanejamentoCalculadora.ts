import { onCall } from "../../shared/callableComMfa";
import {admin} from "../../shared/firebaseAdmin";
import {migrarPlanejamento} from "../../services/calculadora/migracaoPlanejamentoService";
export const migrarPlanejamentoCalculadora = onCall({region:"southamerica-east1",timeoutSeconds:120,cors:true},
  req => migrarPlanejamento(admin.firestore(),req.auth?.uid,req.data));
