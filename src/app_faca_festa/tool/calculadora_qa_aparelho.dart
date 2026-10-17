// Alvo de QA no aparelho: dados fictícios em memória, sem inicialização Firebase.
// flutter run --dart-define=CALCULADORA_QA=true -t tool/calculadora_qa_aparelho.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/data/models/calculadora/calculadora_evento_item_model.dart';
import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show RepoJornada, CardapioQA, EventoQA, MigracaoQA;
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AuthQA, BaseQA, AiQA;

class _BaseAparelho extends BaseQA {
  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback(
          {required String tipoEvento, String? perfilFesta}) async =>
      (jsonDecode(_catalogo) as List)
          .map((r) => CalculadoraEventoItemModel.fromMap(
              Map<String, dynamic>.from(r as Map)))
          .toList();
}

void main() {
  if (!const bool.fromEnvironment('CALCULADORA_QA')) {
    throw StateError(
        'Execute apenas com --dart-define=CALCULADORA_QA=true no pacote isolado de QA.');
  }
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  Get.put<FirebaseAuth>(AuthQA());
  final repo = RepoJornada();
  final calc = CalculadoraFestaController(
      aiService: AiQA(),
      repository: repo,
      itensBaseRepository: _BaseAparelho());
  final menus = CardapioQA();
  final cardapio = CardapioController(repository: menus);
  menus.aoSalvar = (item) => cardapio.itensPorCardapio[item.idCardapio] =
      cardapio
          .itensDoCardapio(item.idCardapio)
          .map((i) => i.idItem == item.idItem ? item : i)
          .toList();
  final tema = Get.put(EventThemeController());
  runApp(GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          useMaterial3: true),
      builder: (_, child) => Banner(
          message: 'QA LOCAL', location: BannerLocation.topEnd, child: child!),
      home: CalculadoraFestaScreen(
          idEvento: 'qa',
          tipoEvento: 'Aniversário',
          adultosIniciais: 21,
          criancasIniciais: 5,
          calculadoraController: calc,
          eventoController: EventoQA(),
          themeController: tema,
          cardapioController: cardapio,
          fornecedorMigracaoAdminController: MigracaoQA())));
}

const _catalogo = r'''[
  {
    "id": "referencia_v1_churrasco",
    "id_item_base": "churrasco",
    "tipo_evento": "todos",
    "nome": "Churrasco",
    "categoria": "comida",
    "unidade": "kg",
    "publico_alvo": "todos",
    "quantidade_por_convidado_equivalente": 0.4,
    "valor_unitario_medio": 0,
    "perfis_festa": [
      "economico",
      "padrao",
      "premium"
    ],
    "selecionado_padrao": true,
    "obrigatorio": false,
    "ativo": true,
    "ordem": 0,
    "observacao": "Referência inicial ajustável. Sem preço presumido.",
    "premissas": {
      "versao": 1,
      "fonte": "https://www.assai.com.br/blog/churrasco-no-assai-atacadista",
      "origem": "referencia_publicada",
      "estado": "referência da fonte; confirmar cru/preparado",
      "grupo": "proteinas",
      "participacao": 1,
      "rendimento": 1,
      "embalagem": 0,
      "aliases": [
        "carne",
        "carne para churrasco"
      ],
      "nota": "Referência inicial por serviço. A presença de outros itens não divide a porção. Divisão e escala por duração exigem ativação explícita. Ajuste a porção à refeição; confirme cru/seco ou pronto.",
      "unidade_consumo": "kg",
      "dividir_grupo": false,
      "ajustar_por_duracao": false,
      "numero_servicos": 1
    }
  },
  {
    "id": "referencia_v1_arroz",
    "id_item_base": "arroz",
    "tipo_evento": "todos",
    "nome": "Arroz",
    "categoria": "comida",
    "unidade": "kg",
    "publico_alvo": "todos",
    "quantidade_por_convidado_equivalente": 0.05,
    "valor_unitario_medio": 0,
    "perfis_festa": [
      "economico",
      "padrao",
      "premium"
    ],
    "selecionado_padrao": true,
    "obrigatorio": false,
    "ativo": true,
    "ordem": 1,
    "observacao": "Referência inicial ajustável. Sem preço presumido.",
    "premissas": {
      "versao": 1,
      "fonte": "https://www.assai.com.br/blog/churrasco-no-assai-atacadista",
      "origem": "referencia_publicada",
      "estado": "referência da fonte; confirmar cru/preparado",
      "grupo": "acompanhamentos",
      "participacao": 1,
      "rendimento": 1,
      "embalagem": 0,
      "aliases": [],
      "nota": "Referência inicial por serviço. A presença de outros itens não divide a porção. Divisão e escala por duração exigem ativação explícita. Ajuste a porção à refeição; confirme cru/seco ou pronto.",
      "unidade_consumo": "kg",
      "dividir_grupo": false,
      "ajustar_por_duracao": false,
      "numero_servicos": 1
    }
  },
  {
    "id": "referencia_v1_macarrao",
    "id_item_base": "macarrao",
    "tipo_evento": "todos",
    "nome": "Macarrão",
    "categoria": "comida",
    "unidade": "kg",
    "publico_alvo": "todos",
    "quantidade_por_convidado_equivalente": 0.08,
    "valor_unitario_medio": 0,
    "perfis_festa": [
      "economico",
      "padrao",
      "premium"
    ],
    "selecionado_padrao": false,
    "obrigatorio": false,
    "ativo": true,
    "ordem": 2,
    "observacao": "Referência inicial ajustável. Sem preço presumido.",
    "premissas": {
      "versao": 1,
      "fonte": "https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa",
      "origem": "referencia_publicada",
      "estado": "seco",
      "grupo": "acompanhamentos",
      "participacao": 1,
      "rendimento": 1,
      "embalagem": 0,
      "aliases": [
        "massa",
        "macarrao"
      ],
      "nota": "Referência inicial por serviço. A presença de outros itens não divide a porção. Divisão e escala por duração exigem ativação explícita. Ajuste a porção à refeição; confirme cru/seco ou pronto.",
      "unidade_consumo": "kg",
      "dividir_grupo": false,
      "ajustar_por_duracao": false,
      "numero_servicos": 1
    }
  },
  {
    "id": "referencia_v1_refrigerante",
    "id_item_base": "refrigerante",
    "tipo_evento": "todos",
    "nome": "Refrigerante",
    "categoria": "bebida",
    "unidade": "L",
    "publico_alvo": "todos",
    "quantidade_por_convidado_equivalente": 0.6,
    "valor_unitario_medio": 0,
    "perfis_festa": [
      "economico",
      "padrao",
      "premium"
    ],
    "selecionado_padrao": true,
    "obrigatorio": false,
    "ativo": true,
    "ordem": 3,
    "observacao": "Referência inicial ajustável. Sem preço presumido.",
    "premissas": {
      "versao": 1,
      "fonte": "https://institucional.ifood.com.br/clientes/como-calcular-quantidades-para-festa-calculos-e-o-que-considerar/",
      "origem": "referencia_publicada",
      "estado": "pronto",
      "grupo": "bebidas_sem_alcool",
      "participacao": 1,
      "rendimento": 1,
      "embalagem": 0,
      "aliases": [],
      "nota": "Referência inicial por serviço. A presença de outros itens não divide a porção. Divisão e escala por duração exigem ativação explícita. Ajuste a porção à refeição; confirme cru/seco ou pronto.",
      "unidade_consumo": "L",
      "dividir_grupo": false,
      "ajustar_por_duracao": false,
      "numero_servicos": 1
    }
  },
  {
    "id": "referencia_v1_suco",
    "id_item_base": "suco",
    "tipo_evento": "todos",
    "nome": "Suco",
    "categoria": "bebida",
    "unidade": "L",
    "publico_alvo": "todos",
    "quantidade_por_convidado_equivalente": 0.6,
    "valor_unitario_medio": 0,
    "perfis_festa": [
      "economico",
      "padrao",
      "premium"
    ],
    "selecionado_padrao": false,
    "obrigatorio": false,
    "ativo": true,
    "ordem": 4,
    "observacao": "Referência inicial ajustável. Sem preço presumido.",
    "premissas": {
      "versao": 1,
      "fonte": "https://institucional.ifood.com.br/clientes/como-calcular-quantidades-para-festa-calculos-e-o-que-considerar/",
      "origem": "referencia_publicada",
      "estado": "pronto",
      "grupo": "bebidas_sem_alcool",
      "participacao": 1,
      "rendimento": 1,
      "embalagem": 0,
      "aliases": [],
      "nota": "Referência inicial por serviço. A presença de outros itens não divide a porção. Divisão e escala por duração exigem ativação explícita. Ajuste a porção à refeição; confirme cru/seco ou pronto.",
      "unidade_consumo": "L",
      "dividir_grupo": false,
      "ajustar_por_duracao": false,
      "numero_servicos": 1
    }
  }
]
''';
