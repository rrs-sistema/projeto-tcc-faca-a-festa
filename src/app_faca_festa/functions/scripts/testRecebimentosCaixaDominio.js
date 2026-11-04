const assert=require('node:assert/strict');
const {projetarCaixaRecebimentos,calcularResumoFornecedor}=require('../lib/services/financeiro/resumoFornecedorService');
const {normalizarRecebimento,assinaturaRecebimento}=require('../lib/services/financeiro/recebimentoFornecedorService');
const fato={id:'r',data:{id_evento:'e',valor:{centavos:50000},alocacoes:[{id_contrato:'c1',centavos:50000}],tipo:'adiantamento'}};
const mirror={id:'r',data:{id_evento:'e',valor:{centavos:50000},entrada:true,id_recebimento_origem:'r'}};
for(const espelhos of [[],[mirror],[mirror]]){
 const r=projetarCaixaRecebimentos([fato],espelhos);
 assert.equal(r.entradasCentavos,50000);assert.equal(r.porContrato.get('c1'),50000);assert.equal(r.porContrato.get('c2')||0,0);
}
assert.throws(()=>projetarCaixaRecebimentos([],[mirror]));
const saldo=calcularResumoFornecedor({vendas:[{id:'c1',id_evento:'e',valor_contratado:2000,recebido_confirmado:2500},{id:'c2',id_evento:'e',valor_contratado:3000}],custos:[]});
assert.equal(saldo.aReceber,3000);assert.equal(saldo.creditoExcedente,500);assert.equal(saldo.saldoContrato,2500);
const p={idFornecedor:'f',idEvento:'e',chaveIdempotencia:'op',valorCentavos:50000,alocacoes:[{idContrato:'c1',valorCentavos:20000},{idContrato:'c2',valorCentavos:30000}]};
assert.equal(assinaturaRecebimento(normalizarRecebimento(p)),assinaturaRecebimento(normalizarRecebimento({...p,alocacoes:[...p.alocacoes].reverse()})));
assert.notEqual(assinaturaRecebimento(normalizarRecebimento(p)),assinaturaRecebimento(normalizarRecebimento({...p,tipo:'adiantamento'})));
const legadoRep={id:'rep',data:{tipo:'repasse',id_evento:'e',valor:{centavos:10000}}};
const legado=projetarCaixaRecebimentos([legadoRep],[]);assert.equal(legado.entradasCentavos,0);assert.equal(legado.repasseLegadoNaoConciliadoCentavos,10000);
const orfao=projetarCaixaRecebimentos([fato],[{id:'outra-chave',data:{id_evento:'e',valor:{centavos:50000},entrada:true,origem:'recebimento'}}]);assert.equal(orfao.entradasCentavos,50000);assert.equal(orfao.movimentoLegadoNaoConciliadoCentavos,50000);
console.log('PASS domínio caixa TS: identidade, espelho, alocação, crédito, assinatura canônica e repasse legado.');
