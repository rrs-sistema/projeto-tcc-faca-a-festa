// Valida o filtro de path usado na exclusão LGPD do vínculo fornecedor↔cotação.
const assert = require('node:assert/strict');
const { ehVinculoCotacaoFornecedor } = require(
  '../functions/lib/functions/lgpd/atenderSolicitacaoLgpd.js',
);

assert.equal(
  ehVinculoCotacaoFornecedor('cotacao/abc/fornecedores/uid-1'),
  true,
);
assert.equal(
  ehVinculoCotacaoFornecedor('cotacao/abc/fornecedores/uid-1/mensagens/m1'),
  false,
);
assert.equal(ehVinculoCotacaoFornecedor('outro/abc/fornecedores/uid-1'), false);
assert.equal(ehVinculoCotacaoFornecedor('cotacao/abc/itens/uid-1'), false);

console.log('test_lgpd_exclusao_paths: ok');
