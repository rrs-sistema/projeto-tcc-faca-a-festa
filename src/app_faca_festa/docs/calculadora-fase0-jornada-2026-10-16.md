# Primeira etapa: coerência da jornada da Calculadora Inteligente

16/10/2026. Implementação local da entrega 0 do plano de autonomia. Nenhum aplicativo, função, regra ou site foi publicado nesta etapa.

## Base registrada antes da implementação

Commit `7419d28` enviado a `origin/main`, com código, testes e documentação que já estavam no workspace. Instaladores gerados e preferências locais da IDE ficaram fora do commit e foram preservados. A implementação desta fase é posterior a esse checkpoint.

## Alterações

- O cadastro novo abre uma estimativa explicitamente sem evento. O contexto do evento ativo não fornece convidados, cardápios ou limite por fallback nesse caminho.
- O limite digitado no formulário chega à calculadora. O retorno da prévia atualiza as contagens e o limite no formulário.
- Um rascunho próprio guarda regras, seleções, perfil, duração e reserva. Reabrir a prévia restaura essas escolhas; os dados alterados no formulário continuam prevalecendo.
- Ao salvar o evento, a estimativa é arquivada como simulação daquele evento. ID determinístico impede simulações repetidas nas novas tentativas. Não cria cardápio, compra ou pagamento automaticamente.
- O evento também recebe uma identidade estável antes da rede. Se a gravação da simulação falhar, o evento não é recriado numa tentativa seguinte.
- Um armazenamento local, separado por organizador e evento, preserva a vinculação pendente antes da gravação remota. Reabrir a edição desse evento no mesmo dispositivo permite recuperar e concluir o vínculo. A pendência local é removida após sucesso.
- A simulação pendente não é colocada no documento compartilhado do evento. Rascunhos que ainda não passaram por uma tentativa de salvar permanecem em memória durante o cadastro; não há promessa de recuperação entre dispositivos ou de cadastro ainda não salvo após fechar o app.
- Mudanças no público e orçamento do formulário após a prévia são refletidas no cálculo arquivado.
- Edição preserva status, ativo, data de cadastro e campos não editados do evento. A escrita por merge preserva metadados fora do formulário; remover a data de término envia uma exclusão explícita.
- Bases de público: previstos, todos cadastrados, não recusados, confirmados e manual. O padrão da calculadora aberta no evento é não recusados; sem lista, usa a previsão do cadastro. Todos recusados resulta em público zero nessa base.
- Os acessos pela home acompanham alterações da lista de convidados enquanto a calculadora está aberta. Público manual e simulações históricas são preservados. Outros pontos de entrada que não forneçam a lista continuam dispondo de atualização explícita.
- Cardápios passam a declarar refeição, categoria, serviço compartilhado ou escopo ainda não definido. Cadastro/edição e persistência preservam a escolha. Registros antigos não são classificados ou migrados silenciosamente.
- Uma categoria/serviço compartilhado não recebe diagnóstico de refeição completa nem compartilhamento automático entre arroz e massa. Isso define o escopo; ainda não implementa distribuição automática entre refeições.
- O fechamento de uma cotação agora gera orçamento fechado e mantém pagamento zero, coerente com a ação de contratação e com a leitura da calculadora. Não converte uma cotação em pagamento realizado.
- Medição em memória registra campos distintos alterados, decisões explícitas instrumentadas, correções de referências e resultados de salvar/aplicar. O tempo ativo é aproximado, usa relógio monotônico, pausa em segundo plano e limita intervalos ociosos a 30 segundos. Metadados gerados ao salvar uma regra não contam como informações digitadas. Não é uma medição completa de todas as telas nem comprova redução de 70%–80%.
- O aviso da prévia temporária orienta a manter o cadastro aberto e salvar o evento. O resumo inicial também deixou de consultar a duração de outro evento ativo ao abrir um rascunho.

## Revisão de fechamento

A revisão encontrou e corrigiu a lacuna de tempo ativo/correções/resultados. O teste da jornada móvel real da interface exporta uma linha de base técnica em `.dart_tool/calculadora-linha-base-jornada.txt`, com o cenário e as limitações identificados. É uma execução automatizada com dependências substituídas; seus segundos não representam velocidade humana e suas contagens não demonstram a meta de autonomia. A comparação com organizadores reais pertence à entrega 4.

Regressões da fase: isolamento entre eventos; ida e retorno do cadastro; vínculo repetido e recuperação após falha; preservação do ciclo de vida; fontes de público; escopos do cardápio; contratação sem pagamento; medição com pausa/ociosidade e correções. A entrega seguinte começa pela prévia do conjunto, descrita em `calculadora-fase1-proposta-inicial-2026-10-16.md`.

## Verificações e limites

Validação original da fase: 475 testes aprovados. Após a revisão e o primeiro incremento seguinte: suíte Flutter com 489 testes aprovados; análise estática dos arquivos e módulos envolvidos sem problemas. `npm run check:calculadora` e `node scripts/testFecharCotacaoPlanejamento.js` foram aprovados na validação do backend. `git diff --check` não encontrou erros de whitespace nas alterações de código.

Testes novos cobrem isolamento com outro evento ativo, retorno da prévia, regras preservadas, vínculo repetido, recuperação da pendência, público atualizado no cadastro, bases de convidados, atualização com a calculadora aberta, edição de evento finalizado, remoção de término, escopo legado e cadastro/edição de categoria em tela pequena.

Teste do backend exercita autorização, criação de contratação consistente, valor pago zero e rejeição de cotação já concluída. As verificações usam substitutos de dependências, sem gravações no evento real e sem executar serviços publicados.

Logs: `.dart_tool/calculadora-fase0-suite-final.log`, `.dart_tool/calculadora-fase0-aceite.log`, `.dart_tool/calculadora-fase0-integracoes.log`, `.dart_tool/calculadora-fase0-analysis.log`.

A proposta automática do evento inteiro, capacidade por orçamento, catálogo ampliado, rendimentos de referência, distribuição automática do estoque e executor agrupado permanecem nas entregas seguintes. Esta etapa corrige as ligações e prepara a base; não declara a meta de autonomia atingida.

A correção de `fecharCotacao` está apenas no código local e exigirá publicação da função para produzir efeito no ambiente remoto. Não houve deploy.
