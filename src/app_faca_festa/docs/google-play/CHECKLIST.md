# Google Play — Faça a Festa

Pacote Android: `com.rrs.system.technology.facafesta`  
Versão atual: `1.0.4` (versionCode `6`)

## Antes de enviar o AAB

1. Crie a chave de upload (uma vez, na sua máquina):

```powershell
powershell -ExecutionPolicy Bypass -File android\create-upload-keystore.ps1
```

Guarde em local seguro (fora do Git):
- `%USERPROFILE%\facafesta-upload-keystore.jks`
- `android/key.properties` (senhas da chave)

Não reutilize keystore de outro aplicativo.

Digitais da **chave de upload** (cadastrar no Firebase Console → app Android):

- SHA-1: `C5:58:11:F8:15:23:D4:A9:0D:B7:CC:5F:AA:F1:30:DD:4B:95:9A:2E`
- SHA-256: `D8:49:5B:13:2A:F5:3E:CD:22:CB:F6:8C:37:BB:DD:8C:64:3D:CE:72:D1:F5:3F:41:0B:12:B2:F4:61:A7:B7:95`
2. Política pública (obrigatória na ficha), no site da RRS:
   - URL: https://rrs-sistema.github.io/site-rrs-system-tecnology/politica-faca-a-festa.html
   - O texto fica em `D:\repository\site\site-rrs-system-tecnology`. Publique esse site para a URL acima refletir a alteração.
3. No Firebase Console → Projeto **faca-a-festa** → App Android → adicionar as digitais SHA-1 e SHA-256 da **chave de upload** (impressas após o build) e, depois do primeiro envio, também as da **chave de assinatura da Play**.
4. Sem essas digitais, o botão **Entrar com Google** falha na versão da loja.

## Ficha da loja (pt-BR)

**Nome:** Faça a Festa  

**Descrição curta (até 80 caracteres):**  
Planeje festas, convites, orçamento e fornecedores em um só app.

**Descrição completa:**

Faça a Festa reúne o planejamento do evento em um único lugar: organizadores montam a festa, convidados confirmam presença e fornecedores recebem cotações.

• Crie o evento, defina data, tema e checklist  
• Monte a lista de convidados e envie convites  
• Calcule quantidades e orçamento da festa  
• Encontre fornecedores por categoria e região  
• Peça cotações e compare respostas  
• Área do convidado com informações do evento  

O aplicativo pede localização só em primeiro plano (fornecedores próximos) e acesso aos contatos apenas se você quiser importar convidados. Não usamos anúncios nem rastreamos localização em segundo plano.

**Categoria sugerida:** Eventos / Estilo de vida  
**E-mail de contato:** rrs.sistema@gmail.com  
**Política de privacidade:** https://rrs-sistema.github.io/site-rrs-system-tecnology/politica-faca-a-festa.html  
**URL de exclusão da conta:** https://rrs-sistema.github.io/site-rrs-system-tecnology/exclusao-de-dados.html#faca-a-festa

## Declarações que ainda estão abertas no Play Console

A política de privacidade já está concluída. Nas demais, use estas respostas:

1. **Detalhes do login.** O app exige conta. Cadastro de organizador é imediato, sem aprovação. Instruções: na tela inicial, Cadastre-se → Organizador → nome, e-mail, senha e aceite da política. Com essa conta dá para criar evento, convidados, orçamento e cotação. Fornecedor é um segundo cadastro, com categorias de serviço. Crie uma conta de avaliador e cole usuário e senha no formulário.
2. **Anúncios.** O app não contém anúncios.
3. **Classificação de conteúdo.** Sem violência, sexo, linguagem imprópria ou compras digitais. Há menção a bebidas alcoólicas no planejamento (cardápio e calculadora), sem ser o foco. Usuários trocam informações (convite, cotação e chat). A localização do aparelho não é compartilhada ao vivo com outras pessoas.
4. **Público-alvo.** Somente 18 anos ou mais. O app não é dirigido a crianças. Nome de criança ou bebê na lista de convidados é informado pelo adulto responsável.
5. **Segurança dos dados.** Coleta nome, e-mail, fotos enviadas, endereço, dados do evento, token de notificação, localização em primeiro plano e contatos (opcional). Finalidade: conta e funcionamento. Compartilha com Firebase/Google e com outros usuários só no fluxo do evento. Não vende dados e não usa para publicidade. Criptografado em trânsito. Exclusão: URL acima. Conta pode ser excluída.
6. **Apps governamentais.** Não.
7. **Recursos financeiros.** Não. O orçamento da festa é anotação do usuário; o app não processa pagamento, crédito, cripto nem conta bancária.
8. **Saúde.** Não.
9. **Categoria e contato.** Eventos ou Estilo de vida. E-mail: rrs.sistema@gmail.com.

## Segurança de dados (Play Console)

- Coleta: nome, e-mail, fotos enviadas pelo usuário, endereço, dados do evento, token de notificação, localização aproximada/precisa em primeiro plano, contatos (opcional, para convites).
- Finalidade: funcionalidade do app, conta, comunicação.
- Compartilhamento: infraestrutura Google/Firebase; outros usuários só vêem o necessário ao fluxo (catálogo, cotação, convite).
- Não é vendido. Não é usado para publicidade.
- Criptografado em trânsito. Usuário pode solicitar exclusão da conta.
- Público-alvo: maiores de 18 anos (festas infantis são planejadas pelo adulto responsável).

## Permissões a declarar

- Localização (aproximada e precisa): busca de fornecedores e território. Sem segundo plano.
- Contatos: importar convidados.
- Notificações: avisos de cotação, convite e avaliação.
- Fotos: seletor do sistema, sem permissão ampla de galeria.
- Sem câmera, sem anúncios (AD_ID removido).

## Arte da loja

- Ícone de alta resolução: 512 × 512 PNG em `docs/google-play/assets/play-icon-512.png`.
- Gráfico de recurso: 1024 × 500 em `docs/google-play/assets/play-feature-1024x500.png`.
- Pelo menos 2 capturas de tela de telefone (16:9 ou 9:16).

## Enviar o pacote

Arquivo gerado:

`build/app/outputs/bundle/release/app-release.aab` (52,4 MB)

Na Play Console: teste interno → teste fechado → produção. Ative **Play App Signing**.
