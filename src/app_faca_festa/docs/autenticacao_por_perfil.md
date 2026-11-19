# Verificação em duas etapas por perfil

Fornecedores (`F`) e administradores (`A`) precisam confirmar um segundo fator após o login com senha ou Google. Organizadores (`O`) e convidados (`C`) entram diretamente por padrão e podem ativar essa proteção em **Conta → Segurança da conta**.

A preferência é armazenada em `usuarios/{uid}.mfa_login_opcional`. Ausência do campo equivale a `false`; métodos cadastrados anteriormente não representam adesão à proteção opcional. A preferência só pode ser alterada pela função `definirMfaOpcional`, após confirmação recente de um método cadastrado. Perfis obrigatórios não podem desativá-la.

A confirmação por e-mail, autenticador ou código de recuperação registra uma prova no servidor, vinculada ao UID e ao `auth_time` do token Firebase. A prova vale até 30 dias para a mesma sessão restaurada. Um novo login exige nova confirmação. A autorização para gerenciar métodos continua válida por apenas 10 minutos.

As funções privadas usam `callableComMfa`; operações de login, cadastro e confirmação dos fatores permanecem disponíveis para concluir o desafio. As regras do Firestore verificam a mesma prova para operações protegidas e impedem sua criação pelo cliente. Perfil próprio e dados necessários ao cadastro continuam acessíveis antes da confirmação.

Ao publicar esta mudança, atualizar primeiro as funções afetadas e depois as regras do Firestore. Aplicativos antigos que pulavam a confirmação no login Google de fornecedores ou administradores precisam ser atualizados. A nova política do organizador depende também da atualização do aplicativo.

Confirmações feitas antes dessa publicação não criaram a prova no servidor. Na primeira utilização após a atualização, fornecedores e administradores precisam confirmar o código uma vez, mesmo que o Firebase tenha restaurado seu login. Nas próximas aberturas, a prova válida é recuperada para a mesma sessão. Não é seguro criar essa prova apenas a partir dos indicadores de métodos cadastrados no perfil.

Validação: testes Flutter de autenticação e persistência do perfil, testes existentes de métodos MFA e teste `functions/scripts/testMfaPerfisEmulator.js` com Auth, Functions e Firestore locais. A matriz cobre os quatro perfis com senha e Google, adesão opcional, bloqueio de sessões sem confirmação e proteção das regras.
