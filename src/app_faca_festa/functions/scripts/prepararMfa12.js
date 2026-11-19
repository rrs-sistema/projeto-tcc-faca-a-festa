// Composição local das callables MFA para o emulador demo-mfa12.
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
  'PASSWORD_RESET_SECRET=homologacao-mfa12-local-somente-demo\n' +
    'SMTP_HOST=127.0.0.1\nSMTP_PORT=2525\nSMTP_USER=fixture\n' +
    'SMTP_PASS=fixture\nSMTP_FROM=fixture@example.test\n',
);
const ts = path.join(modulos, 'typescript');
const totpMfa = path.join(root, 'functions/src/functions/auth/totpMfa.ts');
const emailMfa = path.join(root, 'functions/src/functions/auth/emailMfa.ts');
const recuperacaoMfa = path.join(root, 'functions/src/functions/auth/recuperacaoMfa.ts');
const preferenciaMfa = path.join(root, 'functions/src/functions/auth/preferenciaMfa.ts');
const emailCodigo = path.join(root, 'functions/src/shared/emailCodigo.ts');
const index = `const fs=require('node:fs'),ts=require(${JSON.stringify(ts)});
require.extensions['.ts']=(m,file)=>m._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,file);
const mfa=require(${JSON.stringify(totpMfa)});
exports.iniciarTotpMfa=mfa.iniciarTotpMfa;
exports.confirmarTotpMfa=mfa.confirmarTotpMfa;
exports.verificarTotpMfa=mfa.verificarTotpMfa;
const {admin}=require(${JSON.stringify(path.join(root, 'functions/src/shared/firebaseAdmin.ts'))});
require(${JSON.stringify(emailCodigo)}).enviarEmailCodigo=async ({ para, texto }) => {
  if (process.env.FUNCTIONS_EMULATOR !== 'true' || !para.endsWith('@example.test')) {
    throw new Error('Envio permitido apenas para fixtures no emulador');
  }
  const codigo=texto.match(/\\b\\d{6}\\b/)[0];
  await admin.firestore().collection('_qa_mfa_email').doc(para).set({codigo});
};
Object.assign(exports,require(${JSON.stringify(emailMfa)}),require(${JSON.stringify(recuperacaoMfa)}));
Object.assign(exports,require(${JSON.stringify(preferenciaMfa)}));
exports.consultarResumoFinanceiroFornecedor =
  require(${JSON.stringify(path.join(root, 'functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts'))}).consultarResumoFinanceiroFornecedor;
exports.consultarDashboardFinanceiroAdmin =
  require(${JSON.stringify(path.join(root, 'functions/src/functions/financeiro/consultarDashboardFinanceiroAdmin.ts'))}).consultarDashboardFinanceiroAdmin;
exports.consultarPrevisaoFinanceiraGerente =
  require(${JSON.stringify(path.join(root, 'functions/src/functions/financeiro/consultarPrevisaoGerente.ts'))}).consultarPrevisaoFinanceiraGerente;
`;
fs.writeFileSync(path.join(destino, 'index.js'), index);
console.log('Composição MFA12 preparada em .dart_tool, sem deploy.');
