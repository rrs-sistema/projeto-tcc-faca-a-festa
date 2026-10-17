# Calculadora inteligente: cálculo, revisão e persistência

A calculadora oferece **Estimar do zero** e **Revisar meu cardápio**. No primeiro modo, usa o catálogo por tipo/perfil e itens manuais. No segundo, calcula somente os itens do cardápio escolhido. Correspondências usam nome normalizado, unidade e público; nomes diferentes, unidades incompatíveis ou regras ambíguas exigem configuração explícita. A porção deve considerar a refeição completa; não há coeficientes arbitrários para substituir almoço, salgados ou bebidas.

## Quantidades e custos

O consumo usa apenas o público do item, com pesos adulto 1, criança 0,6 e bebê 0,2. Kg e litros são arredondados para cima em passos de 0,01; unidades, pacotes, garrafas e centos são inteiros. O custo usa a mesma quantidade exibida multiplicada pelo preço cadastrado, sem um segundo multiplicador de preço por perfil. Descartáveis não recebem aumento pela duração. Preço ausente mantém o cálculo de quantidade e sinaliza estimativa parcial.

Carregamento, falha técnica, falta de configuração, ausência de pessoas e ausência de seleção têm mensagens próprias. Regras manuais permitem continuar sem catálogo. Atualizar a tela mantém regras manuais e seleções. Salvar/aplicar fica indisponível sem resultado válido.

## Cardápio e histórico

A aplicação passa por uma revisão, com seleção de itens e comparação entre quantidade planejada e sugerida. Atualiza somente a sugestão dos itens existentes: quantidade final, confirmação e observações manuais permanecem intactas. Novos itens têm quantidade final zero, até revisão pelo organizador. Identidade estável evita duplicação entre simulações; ambiguidades são bloqueadas. Nome/unidade/público diferentes não são tratados como equivalentes automaticamente.

A transação grava a simulação completa, mesmo quando só parte das sugestões é aplicada ao cardápio. Remoções de itens também removem os resultados antigos do histórico. A reabertura restaura regras e preços dos resultados salvos. Documentos parciais antigos criados somente pela IA não aparecem como simulações completas.

## Orçamento e IA

Gastos existentes são observados continuamente. A projeção soma os compromissos existentes ao custo adicional por identidade de item; não conta novamente o custo já contemplado para uma correspondência exata. Serviços agregados ou produtos com nomes diferentes precisam de revisão do organizador: não há correspondência semântica automática entre um contrato de buffet e seus alimentos.

A conversão de uma simulação aprovada cria gastos novos ou vincula gastos correspondentes. Valores contratados/pagos são preservados; propostas para gastos existentes ficam em `quantidade_sugerida_calculadora` e `custo_sugerido_calculadora`, para revisão no orçamento. A conversão é atômica e evita duplicar o item ao converter outra simulação.

A IA recebe cardápio, regras pendentes, gastos, projeção e limite total. Números financeiros são derivados do cálculo, não da resposta generativa. Dados incompletos não produzem conclusão de adequação ao orçamento. Falha na base editorial não impede o fallback. Falhas da análise não removem quantidades. Respostas antigas são descartadas. A análise automática não grava no histórico: a versão atual acompanha o salvamento explícito.

As regras do Firestore restringem simulações e resultados ao dono/organizador/admin. A callable confere usuário e propriedade da festa/simulação, ignorando o UID fornecido pelo cliente. Não há migração destrutiva dos documentos existentes.

## Validação e publicação

- `npm run test:calculadora`: testes Flutter dos módulos e validação TypeScript/contrato da IA.
- `npm run test:rules:calculadora`: testes de isolamento, criação em lote, legado e exclusão no emulador do Firestore. A versão atual da Firebase CLI exige Java 21.
- Antes de publicar, revisar com um evento real: catálogo ausente; item sem preço; cardápio com quantidades finais editadas; envio repetido; reabertura e edição de histórico; conversão de duas simulações com o mesmo item.

O backend requer publicação das Cloud Functions e de `firestore.rules`, junto da versão atualizada do aplicativo. O `predeploy` existente compila o TypeScript. Implementação e testes locais não publicam no Firebase.
