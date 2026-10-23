// Ferramenta deliberadamente restrita a demo. Nenhuma credencial é impressa.
const fs = require('node:fs');
function argumentos(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i += 2) {
    if (!/^--[a-z-]+$/.test(argv[i]) || !argv[i + 1]) throw Error('Use opções explícitas --nome valor.');
    out[argv[i].slice(2)] = argv[i + 1];
  }
  for (const k of Object.keys(out)) if (!['projeto','eventos','acao','inspecao','relatorio'].includes(k)) throw Error('Opção desconhecida.');
  return out;
}
async function executar(args, token, host) {
  if (!/^demo-[a-z0-9-]+$/.test(args.projeto || '') ||
      !/^(127\.0\.0\.1|localhost|\[::1\]):\d+$/.test(host || '')) throw Error('Selecione projeto demo e FUNCTIONS_EMULATOR_HOST local.');
  const eventos = (args.eventos || '').split(',');
  if (!eventos.length || eventos.length > 20 || new Set(eventos).size !== eventos.length || eventos.some(e => !/^[\w-]{1,120}$/.test(e))) throw Error('Selecione até 20 eventos distintos.');
  const acao = args.acao || 'inspecionar';
  if (!['inspecionar','aplicar','reverter'].includes(acao) || !token) throw Error('Ação ou autenticação ausente.');
  const anterior = args.inspecao ? JSON.parse(fs.readFileSync(args.inspecao,'utf8')) : null;
  if (acao !== 'inspecionar' && (!anterior || anterior.projeto !== args.projeto || !args.relatorio)) throw Error('Aplicação/reversão exige relatório de inspeção do mesmo projeto e destino de relatório.');
  if (acao !== 'inspecionar' && eventos.some(evento => !anterior.resultados?.some(r => r.evento === evento && typeof r.assinatura === 'string'))) throw Error('Todos os eventos precisam de inspeção prévia.');
  const resultados = [];
  const relatorio = {schema:1,projeto:args.projeto,acao,concluido:false,resultados};
  // Reserva exclusiva antes de qualquer escrita remota; falhas parciais ficam registradas.
  if (args.relatorio) fs.writeFileSync(args.relatorio,JSON.stringify(relatorio,null,2),{flag:'wx'});
  try { for (const evento of eventos) {
    const assinatura = anterior?.resultados?.find(r => r.evento === evento)?.assinatura;
    if (acao !== 'inspecionar' && !assinatura) throw Error('Evento sem inspeção prévia.');
    const resposta = await fetch(`http://${host}/${args.projeto}/southamerica-east1/migrarPlanejamentoCalculadora`,{
      method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
      body:JSON.stringify({data:{evento,projeto:args.projeto,acao,...assinatura ? {assinatura} : {}}})});
    const corpo = await resposta.json();
    if (!resposta.ok || corpo.error) throw Error(`Migração recusada: ${corpo.error?.status || resposta.status}.`);
    resultados.push({evento,...corpo.result});
    if (args.relatorio) fs.writeFileSync(args.relatorio,JSON.stringify(relatorio,null,2));
  } } catch (e) {
    if (args.relatorio) fs.writeFileSync(args.relatorio,JSON.stringify({...relatorio,estado:'interrompido'},null,2));
    throw e;
  }
  relatorio.concluido = true;
  if (args.relatorio) fs.writeFileSync(args.relatorio,JSON.stringify(relatorio,null,2));
  return relatorio;
}
module.exports = {argumentos,executar};
if (require.main === module) {
  executar(argumentos(process.argv.slice(2)),process.env.MIGRACAO_ID_TOKEN,process.env.FUNCTIONS_EMULATOR_HOST)
      .then(r => console.log(JSON.stringify(r,null,2)))
      .catch(e => {console.error(e.message);process.exitCode = 1;});
}
