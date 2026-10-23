# Prompts independentes — jornada do evento à Calculadora Inteligente

Conjunto de 12 prompts de implementação elaborado em 19/10/2026 para o aplicativo Faça a Festa.

## Como usar

Abra um arquivo e copie **todo o conteúdo** para um novo chat com acesso ao repositório. Não é necessário copiar uma instrução comum, anexar esta conversa ou executar um prompt anterior. Cada arquivo contém contexto, contrato de negócio, escopo, pontos de entrada, critérios de aceite, validação e entrega.

Independência significa que qualquer prompt pode iniciar o trabalho a partir do código atual. As alterações têm relações técnicas: cada executor deve reutilizar o que já existir e implementar a fundação mínima necessária para seu próprio escopo. Isso não torna seguro executar alterações concorrentes nos mesmos arquivos. Recomenda-se execução sequencial na ordem abaixo para reduzir retrabalho; não há obrigação de criar chats novos ou automações.

Estes arquivos são instruções, não alterações já implementadas nem garantia de homologação. Somente o prompt 12 trata da verificação integral; ele deve declarar falhas e capacidades ausentes, sem ocultar lacunas usando mocks.

## Arquivos

| Prompt | Entrega | Relação com o plano integral |
|---|---|---|
| [01](01-contexto-e-prontidao.md) | Contexto único, prontidão e atualização das fontes | J0 + prontidão |
| [02](02-cadastro-e-rascunho-duravel.md) | Cadastro, rascunho durável e vínculo recuperável | J1 |
| [03](03-publico-e-completude.md) | Público, origem e completude da lista de convidados | J2 |
| [04](04-persistencia-das-configuracoes.md) | Persistência uniforme das escolhas da calculadora | J3 |
| [05](05-agenda-e-ocorrencias.md) | Agenda e serviços alimentares por ocorrência | J4 |
| [06](06-catalogo-contextual-versionado.md) | Referências e modelos contextuais configuráveis | J5 |
| [07](07-planejador-hibrido.md) | Planejador híbrido e perguntas por impacto | J6 |
| [08](08-financeiro-e-capacidade.md) | Financeiro real, verba alimentar e capacidade | J7 — financeiro |
| [09](09-aplicacao-e-execucao.md) | Aplicação agrupada, estoque e execução idempotente | J7 — aplicação |
| [10](10-experiencia-integral.md) | Ergonomia e intuitividade da jornada completa | J8 |
| [11](11-migracao-e-governanca.md) | Compatibilidade, migração e governança do catálogo | J9 — compatibilidade |
| [12](12-homologacao-ponta-a-ponta.md) | Homologação integral pelo cadastro e retomada real | J9 — homologação |

## Contrato repetido em todos os arquivos

Os prompts preservam isolamento entre eventos, referências e cálculos verificáveis, confirmação antes de gravar, distinção entre planejamento e fatos reais, compatibilidade de dados e privacidade. Pedem implementação integrada, testes e evidências, sem deploy ou migração de produção automáticos.

Cada execução deve gravar evidências em `docs/evidencias_validacao/jornada/`, com o nome indicado no próprio prompt. Caso outro prompt já tenha implementado um contrato, a orientação é reutilizar e verificar, não criar versões paralelas.

## Rastreabilidade

Os identificadores A01–A36 abaixo apontam para os casos do plano integral. Eles são um índice adicional: os prompts descrevem por extenso os cenários necessários e não exigem consultar o documento de origem para entender a tarefa.

- Prompt 01: A11, A12, A13, A32, A34.
- Prompt 02: A01, A02, A03, A04, A05, A06.
- Prompt 03: A07, A08, A09, A10.
- Prompt 04: A14, A15, A16, A17, A32.
- Prompt 05: A19, A20, A21, A25.
- Prompt 06: A18, A22, A23, A24, A36.
- Prompt 07: A18, A21, A22, A23, A24, A27.
- Prompt 08: A26, A27, A28, A29.
- Prompt 09: A24, A25, A29, A30, A31, A35.
- Prompt 10: A02, A03, A06, A13, A15, A33, A34.
- Prompt 11: A10, A22, A32, A35, A36.
- Prompt 12: A01, A02, A03, A04, A05, A06, A07, A08, A09, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36.

Documentos de origem: `docs/plano-integral-jornada-evento-calculadora-2026-10-19.md` e `docs/auditoria-inteligencia-eventos-2026-10-19.md`. Sua leitura é complementar; os prompts são completos por si.
