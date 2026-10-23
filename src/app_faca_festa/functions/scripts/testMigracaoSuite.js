const {spawnSync} = require('node:child_process');
const path = require('node:path');
for (const arquivo of [path.join(__dirname,'testMigracaoGovernancaEmulator.js'),
  path.resolve(__dirname,'../../test/firestore/calculadora.rules.test.js')]) {
  const result = spawnSync(process.execPath,[arquivo],{stdio:'inherit',env:process.env});
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status || 1);
}
