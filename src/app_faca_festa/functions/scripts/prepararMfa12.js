// Composição local das callables TOTP para o emulador demo-mfa12. Sem deploy.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const destino = path.join(root, '.dart_tool/mfa12-functions');
fs.mkdirSync(destino, { recursive: true });
const modulos = path.join(root, 'functions/node_modules');
const link = path.join(destino, 'node_modules');
if (!fs.existsSync(link)) fs.symlinkSync(modulos, link, 'junction');
fs.writeFileSync(
  path.join(destino, 'package.json'),
  JSON.stringify({
    name: 'mfa12-demo',
    private: true,
    main: 'index.js',
    engines: { node: '22' },
    dependencies: {
      'firebase-functions': '^6.0.1',
      'firebase-admin': '^12.7.0',
    },
  }),
);
fs.writeFileSync(
  path.join(destino, '.secret.local'),
  'PASSWORD_RESET_SECRET=homologacao-mfa12-local-somente-demo\n',
);
const ts = path.join(modulos, 'typescript');
const totpMfa = path.join(root, 'functions/src/functions/auth/totpMfa.ts');
const index = `const fs=require('node:fs'),ts=require(${JSON.stringify(ts)});
require.extensions['.ts']=(m,file)=>m._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,file);
const mfa=require(${JSON.stringify(totpMfa)});
exports.iniciarTotpMfa=mfa.iniciarTotpMfa;
exports.confirmarTotpMfa=mfa.confirmarTotpMfa;
exports.verificarTotpMfa=mfa.verificarTotpMfa;
`;
fs.writeFileSync(path.join(destino, 'index.js'), index);
console.log('Composição MFA12 preparada em .dart_tool, sem deploy.');
