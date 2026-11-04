import { HttpsError,onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { exigirUsuarioAutenticado } from "../../shared/auth";
import { movimentarComercial,hashJornada,idJornada } from "../../services/cotacao/jornadaAtendimentoService";
export const cancelarCotacao=onCall({region:"southamerica-east1",timeoutSeconds:45,cors:true},async req=>{
 const p=await exigirUsuarioAutenticado(req.auth?.uid),d=req.data||{},cot=idJornada(d.idCotacao??d.id_cotacao),ref=admin.firestore().doc(`cotacao/${cot}`),c=await ref.get();
 if(!c.exists)throw new HttpsError("not-found","Cotação não encontrada.");
 let fornecedor=d.idFornecedor||p.uid;
 if(p.uid===c.data()?.id_usuario_solicitante&&!d.idFornecedor){const fs=await ref.collection("fornecedores").limit(1).get();fornecedor=fs.docs[0]?.id;}
 return movimentarComercial(admin.firestore(),p.uid,{idCotacao:cot,idFornecedor:fornecedor,acao:p.uid===c.data()?.id_usuario_solicitante?"cancelar":"recusar",motivo:d.motivo||"legado_nao_informado",descricao:d.descricao||"Cancelamento/recusa pelo fluxo legado",chave:d.chave||hashJornada([p.uid,cot,"cancelar"])});
});
