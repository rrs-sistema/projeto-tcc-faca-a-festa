# Google Play — Faça a Festa

Pacote Android: `com.rrs.system.technology.facafesta`  
Versão atual: `1.0.0` (versionCode `2`)

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
2. Publique a política pública (obrigatória na ficha):
   - `firebase deploy --only hosting` depois do `flutter build web`
   - URL: https://faca-a-festa.web.app/privacidade.html
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
**E-mail de contato:** o mesmo da conta de desenvolvedor da Play  
**Política de privacidade:** https://faca-a-festa.web.app/privacidade.html

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
