const assert=require('node:assert/strict');
const {planejar}=require('./planejarLegadoAvaliacoes');
const dados=[{path:'avaliacao_fornecedor/antiga',data:{nota:5,id_contrato:'aparente',comentario:'Original'}}];
const plano=planejar(dados);assert.equal(plano.modo,'dry-run');assert.equal(plano.promocoesAutomaticas,0);assert.equal(plano.operacoes[0].verificada,false);assert.deepEqual(plano.operacoes[0].dadosOriginais,dados[0].data);assert.throws(()=>planejar({}));
console.log('PASS dry-run offline: legado preservado sem promover verificação.');
