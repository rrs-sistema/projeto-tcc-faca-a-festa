# Prompt 10 — Validação integrada da operação do fornecedor

Valide e estabilize a operação do fornecedor do Faça a Festa no repositório `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Stack Flutter/GetX e Firebase/Cloud Functions TypeScript, Windows/PowerShell. Este prompt solicita execução de testes, correção de defeitos do escopo e evidências reproduzíveis.

Leia AGENTS.md, confira Git e preserve alterações existentes. Não faça deploy, commit/push, cobrança, envio externo ou operação em produção. Testes integrados devem recusar projetos não-demo e endpoints de produção. Reutilize scripts/emuladores/fixtures atuais. Não use capturas antigas ou documentação como comprovação do estado atual.

## Preparação

Inspecione módulos reais de atendimentos, agenda/capacidade, financeiro e reputação. Consulte `docs/prompts-operacao-fornecedor/` e evidências existentes como contexto, mas verifique o código. Este prompt é a checagem final: funcionalidade ainda ausente deve ser registrada como lacuna, sem simular sua aprovação. Corrija defeitos encontrados dentro das funcionalidades implementadas.

## Cenários obrigatórios

1. Crie dois clientes, dois fornecedores, usuário sem vínculo e papéis autorizados de suporte. Demonstre isolamento de conversas, contratos, avaliações e dados financeiros privados por leitura direta, consulta e comando.
2. Percorra solicitação → proposta versionada → negociação → contratação → agenda/preparação → entrega → aceite/contestação. Verifique próxima ação, histórico e acesso contínuo à conversa autorizada.
3. Contrato de R$ 3.150,00 com comissão descontada de R$ 157,50: líquido previsto de R$ 2.992,50. Pagamento declarado do cliente não vira recebido do fornecedor. Repasse confirmado de R$ 1.000,00 deixa R$ 1.992,50 pendentes em todas as visões pertinentes.
4. Dois contratos no mesmo evento, R$ 2.000,00 e R$ 3.000,00; recebimento de R$ 500,00 alocado ao primeiro deixa R$ 1.500,00 e R$ 3.000,00 pendentes. Caixa recebe R$ 500,00 uma única vez antes/depois de refresh.
5. Cubra retry, timeout após persistência, payload conflitante com mesma chave e concorrência de recebimento, repasse, contratação e capacidade. Não devem existir escrita parcial, excesso de reserva ou comissão liquidada duas vezes.
6. Após conclusão elegível, cliente avalia uma vez; fornecedor responde sem editar nota. Terceiros e autoavaliação são bloqueados. Denúncia não apaga crítica automaticamente. Médias e quantidades convergem.
7. Cubra cancelamento, estorno, legado sem vínculo, ausência de datas/custos e indisponibilidade da API. Verifique que erro/ausência não viram zero, aceite ou quitação.
8. Confirme que painel, detalhe, relatórios/exportação e fatos persistidos conciliam; teste troca de sessão, dispositivos/larguras disponíveis, fonte ampliada e conteúdo sob navegação fixa.

## Execução e entrega

Selecione testes pertinentes nos package.json e suites Flutter. Execute build/análise estática das partes alteradas, testes de domínio/widgets, regras Firestore e integração Functions/persistência em emuladores. Mocks não comprovam regras nem atomicidade. Corrija o fake incompatível de cotações caso ainda bloqueie a suite, sem enfraquecer assertions. Não trate saída de lint ignorado como validação concluída.

Registre em `docs/evidencias_validacao/operacao-fornecedor/10-validacao-integrada.md`: cenário, comando, resultado real, identidade dos dados sintéticos, arquivos alterados, falhas corrigidas e o que não foi executado. Classifique a prontidão para piloto com base nessas evidências, sem declarar prontidão de produção a partir de testes locais. Entregue uma lista objetiva de bloqueadores remanescentes, se houver.
