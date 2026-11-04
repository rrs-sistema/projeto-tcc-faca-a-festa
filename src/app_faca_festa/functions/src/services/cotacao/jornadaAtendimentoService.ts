import { prepararAgendaNaContratacao, validarJanelas } from "../agenda/agendaFornecedorService";
import { transacaoIdempotente } from "../../shared/transacaoIdempotente";
import { gravarMensagemSistemaNaTransacao } from "../../functions/cotacao/mensagensSistemaCotacao";
import { createHash } from "crypto";
import { FieldValue, Firestore, Timestamp, Transaction } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin } from "../../shared/firebaseAdmin";
import { atualizarExecucaoContrato } from "../financeiro/acompanhamentoPersistenciaService";
import { exigirUsuarioAutenticado } from "../../shared/auth";
export const hashJornada=(v:unknown)=>createHash("sha256").update(JSON.stringify(v)).digest("hex");
export function idJornada(v:unknown):string{if(typeof v!=="string"||!v.trim()||v.length>200||v.includes("/"))throw new HttpsError("invalid-argument","Identificador inválido.");return v.trim();}
const texto=(v:unknown,max=2000)=>{if(typeof v!=="string"||v.length>max)throw new HttpsError("invalid-argument","Texto inválido.");return v.trim();};
function inteiro(v:unknown,min=0){if(!Number.isSafeInteger(v)||Number(v)<min||Number(v)>900000000000)throw new HttpsError("invalid-argument","Valor/versão inválida.");return Number(v);}
function dataISO(v:unknown,obrigatoria=false){if(v==null||v===""){if(obrigatoria)throw new HttpsError("invalid-argument","Informe a validade.");return null;}if(typeof v!=="string"||!Number.isFinite(Date.parse(v)))throw new HttpsError("invalid-argument","Data inválida.");return new Date(v).toISOString();}
function instante(v:any):string|null{return v?.toDate?v.toDate().toISOString():null;}
export function comercialLegado(d:any):string{
 if(d.estado_comercial)return d.estado_comercial;
 const s=String(d.status||"").toLowerCase();
 return ["fechado","fechada","concluida","concluido"].includes(s)?"ganho":["respondido","respondida","parcial"].includes(s)?"proposta_enviada":s==="perdeucotacao"?"perdido":["recusado","recusada"].includes(s)?"recusado":["cancelado","cancelada"].includes(s)?"cancelado":"nova_solicitacao";
}
export function proximaAcaoJornada(comercial:string,execucao:string|null,responsavel?:string,prazo?:string|null){
 if(["perdido","recusado","cancelado"].includes(comercial))return {acao:"Encerramento comercial; não representa entrega",responsavel:null,prazo:null};
 if(comercial!=="ganho")return {acao:comercial==="nova_solicitacao"?"Revisar e enviar proposta":comercial==="negociacao"?"Responder à negociação":"Revisar proposta vigente",responsavel:responsavel||(comercial==="nova_solicitacao"?"fornecedor":"cliente"),prazo:prazo||null};
 const a:Record<string,[string,string|null]>={nao_iniciado:["Preparar e agendar compromisso","fornecedor"],agendado:["Iniciar execução","fornecedor"],em_execucao:["Informar entrega","fornecedor"],entrega_informada:["Aceitar ou contestar entrega","cliente"],aceito:["Entrega aceita; consultar pendências financeiras",null],contestado:["Acompanhar mediação existente","assistencia"],cancelado_execucao:["Consultar histórico e mediação",null]};
 const [acao,r]=a[execucao||""]||["Conferir vínculo do compromisso","participantes"];
 return {acao,responsavel:r,prazo:prazo||null};
}
async function contexto(db:Firestore,tx:Transaction,uid:string,idCotacao:string,idFornecedor:string){
 const cRef=db.doc(`cotacao/${idCotacao}`),fRef=cRef.collection("fornecedores").doc(idFornecedor),c=await tx.get(cRef),f=await tx.get(fRef);
 if(!c.exists||!f.exists)throw new HttpsError("not-found","Atendimento não encontrado.");
 if(uid!==c.data()?.id_usuario_solicitante&&uid!==idFornecedor)throw new HttpsError("permission-denied","Sem vínculo com a conversa.");
 return {cRef,fRef,c:c.data()!,f:f.data()!};
}
function audit(tx:Transaction,ref:FirebaseFirestore.DocumentReference,uid:string,chave:string,assinatura:string,detalhes:any,resultado:any){
 tx.create(ref.collection("historico_jornada").doc(hashJornada([uid,chave])),{...detalhes,autor_id:uid,chave,assinatura,resultado,criado_em:FieldValue.serverTimestamp()});
}
async function idem(tx:Transaction,ref:FirebaseFirestore.DocumentReference,uid:string,chave:string,assinatura:string){
 const s=await tx.get(ref.collection("historico_jornada").doc(hashJornada([uid,chave])));
 if(!s.exists)return null;if(s.data()?.assinatura!==assinatura)throw new HttpsError("already-exists","Chave com payload divergente.");return {...s.data()!.resultado,idempotente:true};
}
const sistema=gravarMensagemSistemaNaTransacao;

function aberto(c:any,f:any){if(["concluida","cancelada"].includes(c.status)||["ganho","perdido","recusado","cancelado"].includes(comercialLegado(f)))throw new HttpsError("failed-precondition","Negociação encerrada. Contratos aceitos exigem alteração explícita pela assistência.");}
function paiApos(docs:FirebaseFirestore.QueryDocumentSnapshot[],f:string,status:string){const ss=docs.map(d=>d.id===f?status:d.data().status);if(ss.every(s=>["recusado","cancelada","perdeuCotacao"].includes(s)))return "cancelada";return ss.every(s=>s!=="pendente")?"respondida":"parcial";}
export async function emitirProposta(db:Firestore,uid:string,d:any){
 const cot=idJornada(d.idCotacao??d.id_cotacao),forn=uid;
 if(d.idFornecedor&&d.idFornecedor!==uid)throw new HttpsError("permission-denied","Autoria da proposta vem da sessão.");
 const aceita=d.aceitou??d.aceitar;if(typeof aceita!=="boolean")throw new HttpsError("invalid-argument","Informe uma decisão explícita.");
 if(!aceita)return movimentarComercial(db,uid,{idCotacao:cot,idFornecedor:forn,acao:"recusar",motivo:d.motivo||"legado_nao_informado",descricao:d.observacaoFornecedor||"Recusa registrada",chave:d.chave||hashJornada([cot,uid,"recusar"])});
 const bruto=d.valorBrutoCentavos!=null?inteiro(d.valorBrutoCentavos,1):inteiro(Math.round(Number(d.valorProposto??d.valor_cotado)*100),1);
 const desconto=inteiro(d.descontoCentavos??0);if(desconto>=bruto)throw new HttpsError("invalid-argument","Desconto deve ser inferior ao valor bruto.");
 const validade=dataISO(d.validade,true)!,prazo=dataISO(d.prazoEntrega),escopo=texto(d.escopo??d.observacaoFornecedor??"",2000),condicoes=texto(d.condicaoPagamento??"",500);
 if(escopo.length<3||condicoes.length<3)throw new HttpsError("invalid-argument","Informe escopo e condições.");
 const esperada=inteiro(d.versaoEsperada??0),chave=idJornada(d.chave||hashJornada([cot,uid,bruto,desconto,validade,prazo,escopo,condicoes,esperada]));
 const agenda=d.agendaOperacional?validarJanelas(d.agendaOperacional):null;
 const assinatura=hashJornada(["proposta",bruto,desconto,validade,prazo,escopo,condicoes,esperada,...(agenda?[agenda]:[])]);
 return transacaoIdempotente(db,async tx=>{
 const x=await contexto(db,tx,uid,cot,forn);const anterior=await idem(tx,x.fRef,uid,chave,assinatura);if(anterior)return anterior;
 aberto(x.c,x.f);if((x.f.proposta_versao||0)!==esperada)throw new HttpsError("aborted","Proposta mudou. Recarregue antes de revisar.");
 if(Date.parse(validade)<=Date.now())throw new HttpsError("failed-precondition","Proposta expirada.");
 const itens=await tx.get(x.fRef.collection("servicos")),todos=await tx.get(x.cRef.collection("fornecedores"));
 if(itens.empty)throw new HttpsError("failed-precondition","Defina os serviços da solicitação antes da proposta.");
 for(const s of itens.docs){const i=s.data();idJornada(i.id_produto_servico||s.id);if(typeof i.quantidade!=="number"||!Number.isFinite(i.quantidade)||i.quantidade<=0||i.quantidade>1000000)throw new HttpsError("failed-precondition","Quantidade de serviço inválida.");}
 const versao=esperada+1,p={schema:1,agenda,versao,brutoCentavos:bruto,descontoCentavos:desconto,liquidoCentavos:bruto-desconto,validade,prazoEntrega:prazo,escopo,condicoes,
 itens:itens.docs.map(s=>({idServico:s.data().id_produto_servico||s.id,nome:String(s.data().nome_produto_servico||"Serviço"),quantidade:s.data().quantidade||1})),autor_id:uid};
 const assinaturaProposta=hashJornada(p),registro={...p,assinatura:assinaturaProposta,criado_em:FieldValue.serverTimestamp()};
 tx.create(x.fRef.collection("propostas").doc(String(versao)),registro);
 tx.update(x.fRef,{status:"respondido",estado_comercial:"proposta_enviada",proposta_versao:versao,proposta_atual:registro,valor_cotado:p.liquidoCentavos/100,observacao_fornecedor:escopo,condicao_pagamento:condicoes,prazo_entrega:prazo?Timestamp.fromDate(new Date(prazo)):null,respondido:true,data_resposta:FieldValue.serverTimestamp(),responsavel_retorno:"cliente",prazo_retorno:validade});
 const statusCotacao=paiApos(todos.docs,forn,"respondido");tx.update(x.cRef,{status:statusCotacao});
 const resultado={ok:true,versao,assinatura:assinaturaProposta,statusCotacao,valorCotado:p.liquidoCentavos/100,idempotente:false};
 audit(tx,x.fRef,uid,chave,assinatura,{acao:"emitir_proposta",versao,estado_anterior:comercialLegado(x.f),estado_novo:"proposta_enviada"},resultado);
 sistema(tx,x.fRef,hashJornada([uid,chave]),`Proposta versão ${versao} enviada para revisão humana. Validade: ${validade}.`);return resultado;
 });
}
export const MOTIVOS_JORNADA=["preco","prazo","indisponibilidade","escopo","cliente_desistiu","outro","legado_nao_informado"];
export async function movimentarComercial(db:Firestore,uid:string,d:any){
 const cot=idJornada(d.idCotacao),forn=idJornada(d.idFornecedor),chave=idJornada(d.chave),acao=d.acao;
 if(!["negociar","recusar","perder","cancelar"].includes(acao))throw new HttpsError("invalid-argument","Ação comercial inválida.");
 const descricao=texto(d.descricao||"",1000),prazo=dataISO(d.prazoRetorno);
 if(acao!=="negociar"&&!MOTIVOS_JORNADA.includes(d.motivo))throw new HttpsError("invalid-argument","Informe motivo estruturado.");
 if(acao==="negociar"&&(!prazo||Date.parse(prazo)<=Date.now()))throw new HttpsError("invalid-argument","Informe prazo de retorno futuro.");
 const assinatura=hashJornada([acao,d.motivo||null,descricao,prazo]);
 return transacaoIdempotente(db,async tx=>{
 const x=await contexto(db,tx,uid,cot,forn),prev=await idem(tx,x.fRef,uid,chave,assinatura);if(prev)return prev;aberto(x.c,x.f);
 if(acao==="recusar"&&uid!==forn)throw new HttpsError("permission-denied","Só o fornecedor registra recusa.");
 if(acao==="negociar"&&!(x.f.proposta_versao>0))throw new HttpsError("failed-precondition","A negociação exige proposta versionada.");
 const todos=await tx.get(x.cRef.collection("fornecedores"));
 const estado=acao==="negociar"?"negociacao":acao==="recusar"?"recusado":acao==="perder"?"perdido":"cancelado";
 const status=acao==="negociar"?"respondido":acao==="recusar"?"recusado":acao==="perder"?"perdeuCotacao":"cancelada";
 const alvoTodos=acao==="cancelar"&&uid===x.c.id_usuario_solicitante;
 const alvos=alvoTodos?todos.docs:[todos.docs.find(f=>f.id===forn)!];
 for(const f of alvos){tx.update(f.ref,{status,estado_comercial:estado,responsavel_retorno:acao==="negociar"?(uid===forn?"cliente":"fornecedor"):null,prazo_retorno:prazo,motivo_encerramento:acao==="negociar"?null:{codigo:d.motivo,descricao,autor_id:uid,data:FieldValue.serverTimestamp()}});if(f.id!==forn)tx.create(f.ref.collection("historico_jornada").doc(hashJornada([uid,chave])),{acao,autor_id:uid,estado_novo:estado,motivo:d.motivo,descricao,criado_em:FieldValue.serverTimestamp()});}
 const statusCotacao=alvoTodos?"cancelada":paiApos(todos.docs,forn,status);tx.update(x.cRef,{status:statusCotacao});
 const resultado={ok:true,estadoComercial:estado,statusCotacao,idempotente:false};audit(tx,x.fRef,uid,chave,assinatura,{acao,estado_anterior:comercialLegado(x.f),estado_novo:estado,motivo:d.motivo||null,descricao,prazo},resultado);
 for(const f of alvos)sistema(tx,f.ref,hashJornada([uid,chave]),acao==="negociar"?"Negociação aberta; aguarda retorno do participante responsável.":`Encerramento comercial: ${estado}. Motivo: ${d.motivo}. Isso não registra entrega.`);
 return resultado;
 });
}
export async function contratarProposta(db:Firestore,uid:string,d:any){
 const idCotacao=idJornada(d.idCotacao??d.id_cotacao),idFornecedor=idJornada(d.idFornecedor??d.id_fornecedor);
 const versao=inteiro(d.versaoProposta,1),assinaturaEsperada=texto(d.assinaturaProposta,128);
 return transacaoIdempotente(db,async tx=>{
 const x=await contexto(db,tx,uid,idCotacao,idFornecedor);
 if(uid!==x.c.id_usuario_solicitante||uid===idFornecedor)throw new HttpsError("permission-denied","Apenas o cliente solicitante aceita a proposta.");
 if(x.c.status==="concluida"){
 if(x.c.id_fornecedor_contratado!==idFornecedor||x.f.proposta_aceita?.versao!==versao||x.f.proposta_aceita?.assinatura!==assinaturaEsperada)throw new HttpsError("failed-precondition","Já houve outra contratação/versão aceita.");
 return {ok:true,idEvento:x.c.id_evento,idOrcamento:x.c.id_orcamento_contratado,valorContratado:x.f.proposta_aceita.liquidoCentavos/100,idempotente:true};
 }
 aberto(x.c,x.f);
 const p=x.f.proposta_atual;
 if(!p||p.versao!==versao||p.assinatura!==assinaturaEsperada)throw new HttpsError("aborted","Revise a versão vigente antes de aceitar.");
 if(Date.parse(p.validade)<=Date.now())throw new HttpsError("failed-precondition","Proposta expirada; solicite revisão ao fornecedor.");
 const idEvento=idJornada(x.c.id_evento),ev=await tx.get(db.doc(`evento/${idEvento}`)),perfilSnap=await tx.get(db.doc(`usuarios/${uid}`)),fornSnap=await tx.get(db.doc(`fornecedor/${idFornecedor}`));
 if(!ev.exists||["cancelado","cancelada"].includes(ev.data()?.status))throw new HttpsError("failed-precondition","Evento indisponível.");
 const fornecedoresSnap=await tx.get(x.cRef.collection("fornecedores"));
 const orcRef=db.collection("orcamento").doc(`cot_${hashJornada(idCotacao).slice(0,32)}`),orcSnap=await tx.get(orcRef);
 if(orcSnap.exists)throw new HttpsError("failed-precondition","Há vínculo existente a conferir; não será criada venda duplicada.");
 const categoriaNome=String(x.c.categoria_nome||"Serviço"),nomeSolicitante=String(perfilSnap.data()?.nome||"Cliente"),nomeFornecedorFinal=String(fornSnap.data()?.razao_social||x.f.nome_fornecedor||"Fornecedor");
 const valorCentavos=inteiro(p.liquidoCentavos,1),valorTotal=valorCentavos/100;
 const idServicoContratado=p.itens[0]?.idServico||null,nomeServicoContratado=p.itens[0]?.nome||categoriaNome;
 const perfil={uid};
 const reservarAgenda=await prepararAgendaNaContratacao(db,tx,idFornecedor,orcRef.id,orcRef.id,p.agenda);reservarAgenda();
 for(const f of fornecedoresSnap.docs){const ganhou=f.id===idFornecedor;tx.update(f.ref,{status:ganhou?"fechado":"perdeuCotacao",estado_comercial:ganhou?"ganho":"perdido",...(ganhou?{id_orcamento:orcRef.id,estado_execucao:"nao_iniciado",proposta_aceita:p}:{motivo_encerramento:{codigo:"outro_fornecedor_contratado",descricao:"Cliente escolheu outro fornecedor",autor_id:uid}})});sistema(tx,f.ref,hashJornada(["contratar",idCotacao]),ganhou?`Proposta ${versao} contratada. Compromisso operacional vinculado; entrega e repasse exigem ações próprias.`:"Negociação perdida. Nenhuma entrega foi registrada.");tx.create(f.ref.collection("historico_jornada").doc(`contratacao_${orcRef.id}`),{acao:ganhou?"contratar":"perder",autor_id:uid,estado_novo:ganhou?"ganho":"perdido",versao:ganhou?versao:null,id_orcamento:ganhou?orcRef.id:null,criado_em:FieldValue.serverTimestamp()});}
 tx.update(x.cRef,{status:"concluida",data_fechamento:FieldValue.serverTimestamp(),fechado_por:uid,id_orcamento_contratado:orcRef.id,id_fornecedor_contratado:idFornecedor});
 tx.create(orcRef, {
          ...(p.agenda?{agenda_operacional:p.agenda}:{}),
          proposta_aceita: {...p,aceito_por:uid,aceito_em:FieldValue.serverTimestamp()},
          escopo:p.escopo,
          condicao_pagamento:p.condicoes,
          id_servico: idServicoContratado,
          id_produto_servico: idServicoContratado,
          id_orcamento: orcRef.id,
          id_cotacao: idCotacao,
          id_necessidade: idCotacao,
          id_evento: idEvento,
          id_fornecedor: idFornecedor,
          nome_fornecedor: nomeFornecedorFinal,
          custo_estimado: valorTotal,
          valor_contratado: valorTotal,
          valor_contratado_centavos: valorCentavos,
          id_solicitante: perfil.uid,
          nome_solicitante: nomeSolicitante,
          anotacoes: `Orçamento gerado automaticamente após fechamento da cotação "${categoriaNome}".`,
          status: "fechado",
          orcamento_fechado: true,
          alternativa_ativa: true,
          contrato_financeiro: {
            schema: 1,
            id_contrato: orcRef.id,
            id_evento: idEvento,
            id_orcamento: orcRef.id,
            id_necessidade: idCotacao,
            valor: { centavos: valorCentavos, moeda: "BRL" },
            estado_comercial: "contratado",
            estado_execucao: "nao_iniciado",
            perspectiva: "evento_pagador",
            retencao: { centavos: 0, moeda: "BRL" },
            reembolso: { centavos: 0, moeda: "BRL" },
            historico: [],
            snapshot_identidade: {
              schema: 1,
              origem: "fechar_cotacao",
              capturado_em: new Date().toISOString(),
              id_evento: idEvento,
              nome_evento: null,
              id_organizador: null,
              nome_organizador: null,
              id_contratante: perfil.uid,
              nome_contratante: nomeSolicitante,
              id_pagador: perfil.uid,
              nome_pagador: nomeSolicitante,
              id_fornecedor: idFornecedor,
              nome_fornecedor: nomeFornecedorFinal,
              id_servico: idServicoContratado,
              nome_servico: nomeServicoContratado || categoriaNome || null,
              descricao_escopo:p.escopo,
              quantidade: null,
              unidade: null,
              valor_centavos: valorCentavos,
              id_operador_acompanhamento: null,
            },
            origem: "fechar_cotacao",
          },
          estado_execucao: "nao_iniciado",
          id_servico_fornecido: idServicoContratado || "",
          nome: nomeServicoContratado || categoriaNome || "",
          data_cadastro: FieldValue.serverTimestamp(),
        });
 tx.create(orcRef.collection("obrigacoes").doc("parcela-1"),{schema:1,id_obrigacao:"parcela-1",id_contrato:orcRef.id,id_orcamento:orcRef.id,id_evento:idEvento,valor:{centavos:valorCentavos,moeda:"BRL"},pago_liquido:{centavos:0,moeda:"BRL"},estado_liquidacao:"aberta",numero_parcela:1,origem:"fechar_cotacao"});
 tx.create(orcRef.collection("orcamento_gasto").doc("contratacao"),{id_gasto:"contratacao",id_orcamento:orcRef.id,nome:`Serviço contratado – ${categoriaNome}`,custo:valorTotal,pago:0,id_servico_contratado:idServicoContratado,nome_servico_contratado:nomeServicoContratado,data_cadastro:FieldValue.serverTimestamp()});
 return {ok:true,idEvento,idOrcamento:orcRef.id,valorContratado:valorTotal,idempotente:false};
 });
}
export async function consultarJornada(db:Firestore,uid:string,d:any){
 const cot=idJornada(d.idCotacao),forn=idJornada(d.idFornecedor);
 return db.runTransaction(async tx=>{
 const x=await contexto(db,tx,uid,cot,forn),p=x.f.proposta_atual||null;
 let idOrc=x.f.id_orcamento||(x.c.id_fornecedor_contratado===forn?x.c.id_orcamento_contratado:null),aviso:string|null=null;
 if(!idOrc&&comercialLegado(x.f)==="ganho"){
 const os=await tx.get(db.collection("orcamento").where("id_cotacao","==",cot));const candidatos=os.docs.filter(o=>o.data().id_fornecedor===forn),unicos=new Map<string,typeof candidatos[number]>();
 for(const o of candidatos){const id=String(o.data().contrato_financeiro?.id_contrato||o.id),anterior=unicos.get(id);if(anterior&&anterior.data().valor_contratado_centavos!==o.data().valor_contratado_centavos)throw new HttpsError("failed-precondition","Espelhos do contrato divergentes.");if(!anterior||o.id===id)unicos.set(id,o);}
 if(unicos.size===1)idOrc=[...unicos.values()][0].id;else aviso="Vínculo legado ausente ou ambíguo. Nenhum contrato será inventado.";
 }
 const orc=idOrc?await tx.get(db.doc(`orcamento/${idJornada(idOrc)}`)):null;
 if(orc?.exists&&(orc.data()?.id_fornecedor!==forn||orc.data()?.id_evento!==x.c.id_evento))throw new HttpsError("failed-precondition","Vínculo de contrato inconsistente.");
 const o=orc?.data(),exec=o?.contrato_financeiro?.estado_execucao||o?.estado_execucao||null;
 const ev=await tx.get(db.doc(`evento/${idJornada(x.c.id_evento)}`)),hist=await tx.get(x.fRef.collection("historico_jornada")),propostas=await tx.get(x.fRef.collection("propostas"));
 const he=orc?.exists?await tx.get(orc.ref.collection("execucao_historico")):null;
 const casos=orc?.exists?await tx.get(db.collection("plataforma_mediacao_casos").where("id_orcamento","==",orc.id)):null;
 const estado=comercialLegado(x.f),proxima=proximaAcaoJornada(estado,exec,x.f.responsavel_retorno,(estado==="ganho"?(["agendado","em_execucao"].includes(exec||"")?o?.agendamento_operacional:null):x.f.prazo_retorno||(estado==="nova_solicitacao"?instante(x.c.data_limite_resposta):null)));
 return {idCotacao:cot,idEvento:x.c.id_evento,idFornecedor:forn,papel:uid===forn?"fornecedor":"cliente",estadoComercial:estado,estadoExecucao:exec,execucaoRevisao:o?.execucao_revisao||0,idOrcamento:orc?.exists?orc.id:null,idContrato:o?.contrato_financeiro?.id_contrato||(orc?.exists?orc.id:null),
 cliente:{nome:String(x.c.nome_usuario_solicitante||"Cliente"),id:x.c.id_usuario_solicitante},evento:{data:instante(ev.data()?.data),local:String(ev.data()?.local_evento||ev.data()?.localEvento||"Local não informado")},
 proposta:p?{...p,criado_em:instante(p.criado_em)}:null,propostas:propostas.docs.map(p=>({...p.data(),criado_em:instante(p.data().criado_em)})).sort((a:any,b:any)=>a.versao-b.versao),
 condicoesAceitas:o?.proposta_aceita||x.f.proposta_aceita||null,escopo:o?.proposta_aceita?.escopo||p?.escopo||x.c.observacao||"Escopo não informado",aviso,motivo:x.f.motivo_encerramento?{codigo:x.f.motivo_encerramento.codigo,descricao:x.f.motivo_encerramento.descricao}:(["perdido","recusado","cancelado"].includes(estado)?{codigo:"legado_nao_informado",descricao:"Motivo não registrado no legado"}:null),
 proxima,chatAberto:x.c.status!=="cancelada"&&!["perdeuCotacao","recusado","cancelada"].includes(x.f.status),
 historico:[...hist.docs.map(h=>({acao:h.data().acao,autorId:h.data().autor_id,estado:h.data().estado_novo,versao:h.data().versao||null,motivo:h.data().motivo||null,data:instante(h.data().criado_em)})),...(he?.docs||[]).map(h=>({acao:h.data().acao,autorId:h.data().autor_id,estado:h.data().estado_novo,versao:null,motivo:h.data().motivo||null,data:instante(h.data().criado_em)}))].sort((a,b)=>String(a.data).localeCompare(String(b.data))),
 mediacoes:(casos?.docs||[]).map(c=>({id:c.id,estado:c.data().estado})),prazoAgendado:o?.agendamento_operacional||null};
 },{readOnly:true});
}
export const consultarJornadaAtendimentoFn=onCall({region:"southamerica-east1"},async req=>{const p=await exigirUsuarioAutenticado(req.auth?.uid);return consultarJornada(admin.firestore(),p.uid,req.data);});
export const movimentarComercialJornadaFn=onCall({region:"southamerica-east1"},async req=>{const p=await exigirUsuarioAutenticado(req.auth?.uid);return movimentarComercial(admin.firestore(),p.uid,req.data);});

export const executarJornadaAtendimentoFn=onCall({region:"southamerica-east1"},async req=>{
 const p=await exigirUsuarioAutenticado(req.auth?.uid),d=req.data||{};
 if(!["agendar","iniciar","informar_entrega","aceitar","contestar"].includes(d.acao))throw new HttpsError("invalid-argument","Ação inválida.");
 return atualizarExecucaoContrato(admin.firestore(),{idOrcamento:idJornada(d.idOrcamento),acao:d.acao,autorId:p.uid,papel:["aceitar","contestar"].includes(d.acao)?"cliente":"fornecedor",chaveIdempotencia:idJornada(d.chave),versaoEsperada:inteiro(d.versaoEsperada),motivo:typeof d.motivo==="string"?texto(d.motivo,1000):undefined,dataAgendada:d.dataAgendada?dataISO(d.dataAgendada)!:undefined});
});
