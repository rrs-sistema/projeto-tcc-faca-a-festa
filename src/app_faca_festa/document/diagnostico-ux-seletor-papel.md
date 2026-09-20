# Diagnóstico UX — tela “Como você quer participar?”

**App:** Faça a Festa  
**Tela:** seletor de papel (primeiro acesso)  
**Arquivo:** `lib/presentation/modules/auth/pages/role_selector_screen.dart`  
**Casca visual:** `AuthFestaShell` em `lib/presentation/modules/auth/widgets/auth_festa_brand.dart`  
**Data:** 19/09/2026  
**Status:** análise apenas — nada foi implementado a partir deste documento.

Este texto é para o time alinhar o que manter, o que cortar e o que ainda falta nesta tela. Não é backlog de código; é diagnóstico de **ergonomia** e **intuitividade**.

---

## 1. Critérios usados

| Critério | Pergunta que a tela precisa responder |
|---|---|
| **Intuitividade** | Em 3 segundos, o usuário entende *quem ele é neste app* e *o que acontece se tocar*? |
| **Ergonomia** | O próximo passo cabe no polegar, sem scroll desnecessário e sem ler quatro linhas para decidir? |

A tarefa desta tela é **uma**: escolher o caminho (Organizador, Fornecedor, já tenho conta, ou convite). Tudo que não fecha essa tarefa compete com ela.

---

## 2. O que já temos (manter)

### Intuitividade

- A pergunta **“Como você quer participar?”** deixa claro o objetivo da tela.
- Dois caminhos visuais distintos: **Sou Organizador** e **Sou Fornecedor** (cor, ícone e vocabulário diferentes).
- Quem já tem conta encontra **Entrar aqui**.
- O papel **Convidado** não aparece como terceiro cadastro. O recado é: entra pelo link do organizador. Isso evita a confusão “preciso me cadastrar como convidado?”.

### Ergonomia

- Os dois cartões são alvos grandes, fáceis de tocar.
- A tela rola (`SingleChildScrollView` + `SafeArea`).
- Em altura menor que 740 px o shell já compacta um pouco logo e espaçamentos.

**Conclusão:** a estrutura de decisão (2 cartões + login) está certa. O problema não é “não dá para escolher”; é **ruído em volta da escolha**.

---

## 3. O que não temos (lacunas)

### Intuitividade

| Lacuna | Por que atrapalha |
|---|---|
| Aviso de convite **não é ação** | “Abra o link enviado pelo organizador” não explica o que fazer *dentro do app* se a pessoa já abriu a loja sem o link. |
| Sem expectativa do próximo passo | Tocar o cartão abre **cadastro** (`/register` com `tipo` O ou F). A tela não diz isso. Pode parecer que já entra no painel. |
| Convidado “sumiu” da escolha | Quem recebeu WhatsApp mas abriu o app pela loja não tem caminho nesta tela. |
| Prova social sem fonte | “+12.000 eventos” e “4.9” não dizem de onde vêm. Em contexto de TCC, pode soar como marketing, não como orientação. |
| Sem volta explícita | Existe o voltar do sistema; na UI a tela parece um beco. |

### Ergonomia

| Lacuna | Por que atrapalha |
|---|---|
| Decisão útil no meio-alto da tela | Cartões + Entrar competem com créditos, política e prova social. Em celular médio, parte do conteúdo pede scroll. |
| Cartão com 4 camadas de texto | Eyebrow + título + descrição + lista colorida. O polegar acerta o bloco; o olho precisa varrer demais. |
| Login mais fraco que o cadastro | “Entrar aqui” é um link pequeno. Quem só quer logar trabalha mais do que quem vai se cadastrar. |

---

## 4. O que temos demais (cortar ou mover)

Estes elementos **não ajudam a escolher o papel**. Podem viver no cadastro, no “Sobre” ou sair desta tela.

| Elemento | Onde está hoje | Por que sobra aqui |
|---|---|---|
| Subtítulo *Escolha como deseja participar* | `RoleSelectorScreen` | Repete o título. |
| Eyebrow `PLANEJAR EVENTO` / `OFERECER SERVIÇO` | `_RoleChoiceCard` | O título do cartão já diz o papel. |
| Descrição **e** a linha rosa/roxa com seta | `_RoleChoiceCard` | Duas vezes o “o que você ganha”. Ficar com **uma** linha. |
| `+12.000` / `4.9` + avatares | `AuthFestaSocialProof` (shell) | Prova social de landing, não de primeiro passo. |
| A palavra **“ou”** entre prova social e Entrar | `AuthFestaShell` | Sugere um terceiro caminho. Entrar não é alternativa aos papéis; é “já tenho conta”. |
| Bolinhas decorativas | `AuthFestaDots` | Sem função. |
| Nomes da equipe + © | `AuthFestaCredits` | Rodapé de site. Útil na splash/sobre, cedo demais na escolha de papel. |
| Política de privacidade | `AuthFestaCredits` | Faz sentido **no cadastro**, não na escolha de papel. |

No print atual o olhar desce nesta ordem: logo → pergunta → 2 cartões → convite → avatares/nota → entrar → créditos → privacidade.  
Só **os cartões e o Entrar** fecham a tarefa.

---

## 5. Recorte proposto (quando formos implementar)

Ordem sugerida, do que mais impacta a decisão:

1. **Um título, sem subtítulo.**
2. **Cartão magro:** título + uma linha (descrição *ou* highlight, não os dois) + ícone + chevron.
3. **Convite acionável** *ou* fora desta tela. Se ficar, precisa ser botão/link com próximo passo real (colar link, abrir WhatsApp, “não tenho o link”).
4. **“Já tem conta? Entrar”** com o mesmo peso visual de uma ação secundária, não de rodapé de site.
5. **Prova social, créditos e política** saem desta tela (cadastro / sobre / splash).

O `AuthFestaShell` é compartilhado com login e cadastro. Qualquer corte de prova social/créditos precisa ser **por tela** (`mostrarProvaSocial`, `mostrarCreditos`), para não esvaziar as outras de uma vez sem alinhamento.

---

## 6. O que não precisa mudar agora

- Paleta, logo e cartões brancos com faixa colorida — identidade está ok.
- Dois papéis de cadastro (O e F) — modelo de domínio correto.
- Não voltar o terceiro cartão “Sou Convidado” como cadastro. O problema é o **caminho do convite**, não a ausência de um terceiro tipo de usuário.

---

## 7. Critério de pronto (quando o time aceitar o recorte)

A tela está boa o suficiente quando:

- [ ] Sem scroll para ver os dois cartões e o Entrar em um celular ~6,1".
- [ ] Cada cartão tem no máximo **duas** linhas de texto além do título.
- [ ] Tocar o cartão tem expectativa clara (ex.: “Criar conta de organizador”).
- [ ] Convite ou some, ou vira ação — texto morto não conta.
- [ ] Política de privacidade aparece no **cadastro**, não nesta escolha.

---

## 8. Para discussão rápida no grupo

1. Convite nesta tela vira **botão** ou **sai**?
2. Login sobe para o topo (ao lado da pergunta) ou fica abaixo dos cartões, só mais visível?
3. Créditos do TCC ficam na splash / tela Sobre — ok para todo mundo?

Se o time concordar nesses três pontos, o recorte da seção 5 cabe em um ajuste local nesta tela + flags no `AuthFestaShell`.
