const assert=require('node:assert/strict');
const {transacaoIdempotente}=require('../lib/shared/transacaoIdempotente');
(async()=>{
 let tentativas=0;const db={runTransaction:async fn=>{if(++tentativas===1)throw {code:3,details:'Transaction is invalid or closed.'};return fn({});}};
 assert.equal(await transacaoIdempotente(db,async()=>42),42);assert.equal(tentativas,2);
 for(const erro of [{code:'permission-denied'},{code:'aborted'},{code:3,details:'Invalid document fields'}]){let n=0;await assert.rejects(()=>transacaoIdempotente({runTransaction:async()=>{n++;throw erro;}},async()=>0));assert.equal(n,1);}
 let n=0;await assert.rejects(()=>transacaoIdempotente({runTransaction:async()=>{n++;throw {code:3,details:'Transaction is invalid or closed.'};}},async()=>0));assert.equal(n,3);
 console.log('PASS reinício limitado de transação invalidada; autorização/validação não são repetidas.');
})().catch(e=>{console.error(e);process.exitCode=1;});
