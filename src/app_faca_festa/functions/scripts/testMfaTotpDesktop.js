// MFA TOTP nas telas reais (widget test; sem OAuth/Firebase nativo).
const { spawn } = require('node:child_process');
const path = require('node:path');

async function main() {
  await new Promise((resolve, reject) => {
    const c = spawn('cmd.exe', ['/d', '/s', '/c',
      'flutter test test/features/auth/mfa_totp_interface_test.dart test/features/auth/app_totp_sessao_test.dart'], {
      cwd: path.resolve(__dirname, '../..'),
      stdio: 'inherit',
    });
    c.on('error', reject);
    c.on('exit', (n) => n === 0 ? resolve() : reject(Error(`MFA UI/sessão: ${n}`)));
  });
  console.log('MFA TOTP pela interface e sessão Google-pula-MFA OK.');
}
main().catch((e) => { console.error(e); process.exitCode = 1; });
