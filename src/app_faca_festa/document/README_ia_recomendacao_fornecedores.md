# IA de Recomendação de Fornecedores — Faça a Festa

## Objetivo

Implementar uma primeira versão avançada e demonstrável para o TCC, usando:

- Flutter + GetX no app.
- Firebase Functions como backend de recomendação.
- Firestore como base de fornecedores, eventos, avaliações, territórios e interações.
- Score inteligente explicável, sem depender de grande volume de dados.

Esta versão não treina um modelo pesado. Ela usa uma abordagem híbrida:

1. Compatibilidade por tipo de evento.
2. Compatibilidade por categoria/serviço.
3. Compatibilidade por cidade, estado ou território.
4. Avaliações do fornecedor.
5. Destaque/top categoria.
6. Aprendizado por interações do usuário.

## Arquivos criados

### Flutter

Copiar para o app:

```text
flutter/lib/data/models/fornecedor_recomendacao_model.dart
flutter/lib/data/models/fornecedor_interacao_model.dart
flutter/lib/controllers/fornecedor_recomendacao_controller.dart
flutter/lib/presentation/widgets/fornecedor_recomendado_card.dart
```

### Firebase Functions

Copiar para o projeto de Functions:

```text
functions/src/recomendacao-fornecedores/recomendarFornecedoresParaEvento.ts
functions/src/recomendacao-fornecedores/registrarInteracaoFornecedor.ts
functions/src/recomendacao-fornecedores/index.ts
functions/src/index.ts.sample
```

Se seu `src/index.ts` já existir, não substitua diretamente. Apenas adicione:

```ts
export {
  recomendarFornecedoresParaEvento,
  registrarInteracaoFornecedor,
} from "./recomendacao-fornecedores";
```

Também garanta que exista:

```ts
import { initializeApp } from "firebase-admin/app";
initializeApp();
```

## Coleções usadas

### Já existentes

```text
eventos ou evento
fornecedor
fornecedor_categoria
territorio
```

### Novas

```text
fornecedor_interacoes
fornecedor_recomendacoes
```

## Como usar no Flutter

Registre o controller no binding:

```dart
Get.lazyPut<FornecedorRecomendacaoController>(
  () => FornecedorRecomendacaoController(),
  fenix: true,
);
```

Ao abrir a tela Meus Fornecedores:

```dart
final recomendacaoController = Get.find<FornecedorRecomendacaoController>();

await recomendacaoController.atualizarRecomendacoes(
  idEvento: eventoAtual.id,
  idUsuario: usuarioLogado.uid,
);
```

Na tela:

```dart
Obx(() {
  if (recomendacaoController.gerando.value ||
      recomendacaoController.carregando.value) {
    return const Center(child: CircularProgressIndicator());
  }

  if (recomendacaoController.recomendacoes.isEmpty) {
    return const SizedBox.shrink();
  }

  return SizedBox(
    height: 310,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: recomendacaoController.recomendacoes.length,
      itemBuilder: (_, index) {
        final item = recomendacaoController.recomendacoes[index];

        return FornecedorRecomendadoCard(
          recomendacao: item,
          onTap: () {
            recomendacaoController.visualizarFornecedor(
              idEvento: item.idEvento,
              idFornecedor: item.idFornecedor,
            );
          },
          onReservar: () {
            recomendacaoController.reservarFornecedor(
              idEvento: item.idEvento,
              idFornecedor: item.idFornecedor,
            );
          },
          onPedirOrcamento: () {
            recomendacaoController.pedirOrcamentoFornecedor(
              idEvento: item.idEvento,
              idFornecedor: item.idFornecedor,
            );
          },
          onDispensar: () {
            recomendacaoController.dispensarFornecedor(
              idEvento: item.idEvento,
              idFornecedor: item.idFornecedor,
            );
          },
        );
      },
    ),
  );
});
```

## Deploy das Functions

Na pasta `functions`:

```bash
npm install
npm run build
firebase deploy --only functions:recomendarFornecedoresParaEvento,functions:registrarInteracaoFornecedor
```

## Ajustes recomendados no FornecedorModel

Veja o arquivo:

```text
patches/fornecedor_model_patch.diff
```

Ele adiciona campos úteis para a IA:

```text
tipo_evento_ids
tipo_evento_nomes
tipo_evento_slugs
preco_medio
total_contratacoes
tempo_medio_resposta_horas
```

Também corrige dois pontos:

1. `fromMap` passar a carregar `fcm_token`.
2. `copyWith` preservar `dataCadastro`.

## Observações importantes

- A Function tenta buscar o evento em `eventos/{id}` e depois em `evento/{id}` para manter compatibilidade.
- A recomendação funciona mesmo com poucos fornecedores.
- Se o evento não tiver latitude/longitude, a Function tenta usar cidade/estado.
- Se não houver categorias necessárias no evento, a Function ainda recomenda com base nas categorias cadastradas do fornecedor.
- O score é limitado entre 0 e 100.

## Para a banca

Descrição sugerida:

> O sistema utiliza recomendação híbrida baseada em conteúdo e comportamento. A recomendação considera o perfil do evento, tipo de festa, categorias de serviço, localização, avaliações, fornecedor em destaque e interações do usuário. Cada recomendação é acompanhada de motivos explicáveis, aumentando a confiança do usuário e demonstrando transparência no processo de decisão da IA.
