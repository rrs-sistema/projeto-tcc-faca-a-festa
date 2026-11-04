# Documentação consolidada do Faça a Festa

Esta pasta contém a edição consolidada de 29/10/2026, organizada como relatório técnico acadêmico para revisão e apresentação à banca.

- `Documentacao_do_Software_Faca_a_Festa.docx`: documento editável em Word.
- `documentacao-software-faca-a-festa.md`: fonte textual de manutenção.
- `gerar_documentacao.py`: gerador do Word e dos diagramas.
- `assets/arquitetura.png` e `assets/arquitetura-servicos.png`: visões de dependências e comunicação.
- `diagramas_arquitetura.py`: geração dos diagramas documentais.
- `diagramas_fluxos.py`: estados, sequência de confirmação e relações lógicas dos dados.
- `avaliacao-profundidade-documental.md`: diagnóstico das lacunas e do aprofundamento da edição 4.
- `historico/Documentacao_do_Software_Faca_a_Festa_edicao3.docx`: cópia preservada da edição anterior.

Os originais do acervo foram preservados. As referências internas S01 a S31 permitem localizar as fontes. As capturas de interface vêm de evidências de widgets com dados fictícios; resultados de testes são atribuídos às entregas em que foram registrados, sem somar execuções sobrepostas ou declarar nova execução das suítes.

Antes da entrega institucional, confirmar nomes e identificação acadêmica dos autores, orientador e exigências de formatação. Identificar a compilação e o backend efetivamente usados na demonstração. A versão do manifesto do cliente é 1.0.17+19, enquanto há evidências locais e de backend posteriores à publicação dessa compilação.

Para gerar o Word, executar `gerar_documentacao.py` com o Python das dependências de documentos do Codex. A geração altera apenas os arquivos desta pasta. A paginação e o sumário devem ser atualizados e inspecionados em um processador de texto antes de nova entrega.

## Comparação com o aplicativo atual

A edição 3 incorpora a revisão dos 21 módulos e os resultados executados em 29/10/2026. O [relatório comparativo](analise-aplicativo-2026-10-29/comparacao-aplicativo-documentacao.md) reúne diferenças, evidências, limitações e prioridades. O inventário reproduzível, hashes e logs estão na mesma pasta. A suíte Flutter não está integralmente aprovada; o relatório preserva as 11 falhas reproduzidas.

## Edição 4 Aprofundamento técnico

A edição atual possui 59 páginas, 14 casos de uso, 22 regras de negócio e 9 figuras. O núcleo de planejamento, negociação e intermediação recebeu descrição de entradas, revisões, alternativas, resultados e critérios de aceitação. Os capítulos 8 a 10 incluem sequência transacional, decisões reconstruídas do código, relacionamentos, campos centrais, memória de cálculo e contratos de integração. A matriz de rastreabilidade distingue testes existentes e cenários propostos para homologação.

A ampliação documental não reexecutou a suíte de negócio nem corrigiu as falhas do aplicativo. O dicionário é um recorte dos agregados centrais, e a revisão bibliográfica institucional e avaliações empíricas continuam necessárias para a entrega acadêmica definitiva.
