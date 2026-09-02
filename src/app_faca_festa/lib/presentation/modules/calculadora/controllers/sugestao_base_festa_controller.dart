import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/models/evento/sugestao_base_festa_model.dart';
import 'package:app_faca_festa/domain/repositories/sugestao_base_festa_repository_contract.dart';

class SugestaoBaseFestaController extends GetxController {
  SugestaoBaseFestaController({
    required SugestaoBaseFestaRepositoryContract repository,
  }) : _repository = repository;

  final SugestaoBaseFestaRepositoryContract _repository;

  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;

  final RxList<SugestaoBaseFestaModel> listaSugestoes =
      <SugestaoBaseFestaModel>[].obs;
  final RxList<SugestaoBaseFestaModel> listaFiltrada =
      <SugestaoBaseFestaModel>[].obs;

  final RxString filtroModulo = ''.obs;
  final RxString filtroTema = ''.obs;
  final RxString filtroTipoEvento = ''.obs;
  final RxString filtroPerfilFesta = ''.obs;
  final RxString filtroAtivo = 'todos'.obs;
  final RxString buscaTexto = ''.obs;

  final Rxn<SugestaoBaseFestaModel> sugestaoSelecionada =
      Rxn<SugestaoBaseFestaModel>();

  final TextEditingController buscaController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    carregarSugestoes();

    debounce<String>(
      buscaTexto,
      (_) => aplicarFiltros(),
      time: const Duration(milliseconds: 350),
    );

    everAll([
      filtroModulo,
      filtroTema,
      filtroTipoEvento,
      filtroPerfilFesta,
      filtroAtivo,
    ], (_) => aplicarFiltros());

    //importarSugestoesTeste(sobrescrever: true);
  }

  Future<int> importarSugestoesTeste({
    bool sobrescrever = true,
  }) async {
    return _repository.importarSugestoesTeste(
      sugestoesBaseFestaSeed,
      sobrescrever: sobrescrever,
    );
  }

  List<Map<String, dynamic>> sugestoesBaseFestaSeed = [
// CALCULADORA (10)
    {
      'id': 'calc_bebidas_clima_ajuste',
      'titulo': 'Ajuste de bebidas por clima',
      'descricao':
          'Oriente a IA a sugerir incremento em bebidas não alcoólicas e água caso a data coincida com meses de alta temperatura.',
      'modulo': 'calculadora',
      'tema': 'bebidas',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {'dias_antes_evento': 30},
      'tags': ['bebidas', 'clima'],
      'ativo': true,
      'ordem': 1
    },
    {
      'id': 'calc_buffet_infantil_proporcao',
      'titulo': 'Proporção buffet infantil',
      'descricao':
          'Indique que o volume de comida para crianças deve ser calculado com base na média de idade.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {'criancas_minimo': 10},
      'tags': ['buffet', 'infantil'],
      'ativo': true,
      'ordem': 2
    },
    {
      'id': 'calc_corporativo_coffee_break',
      'titulo': 'Dimensionamento coffee break',
      'descricao':
          'Sugira quantidades moderadas de snacks para eventos de curta duração focados em networking.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {'duracao_minima_horas': 2},
      'tags': ['corporativo', 'coffee'],
      'ativo': true,
      'ordem': 3
    },
    {
      'id': 'calc_casamento_espumante_brinde',
      'titulo': 'Cálculo brinde casamento',
      'descricao':
          'Recomende a estimativa de espumante baseada no número de brindes previstos.',
      'modulo': 'calculadora',
      'tema': 'bebidas',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['premium'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'bebidas'],
      'ativo': true,
      'ordem': 4
    },
    {
      'id': 'calc_formatura_convidados_finais',
      'titulo': 'Ajuste de margem de convidados',
      'descricao':
          'Oriente a sugerir uma margem de segurança de convidados para garantir estoque de lembranças.',
      'modulo': 'calculadora',
      'tema': 'convidados',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'alta',
      'gatilhos': {'quantidade_minima_convidados': 50},
      'tags': ['formatura', 'logistica'],
      'ativo': true,
      'ordem': 5
    },
    {
      'id': 'calc_cha_bebe_lembrancas',
      'titulo': 'Cálculo lembrancinhas',
      'descricao':
          'Sugira considerar 1.2 unidades por convidado para evitar falta em caso de extras.',
      'modulo': 'calculadora',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['economico'],
      'categoria': 'economia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'lembranca'],
      'ativo': true,
      'ordem': 6
    },
    {
      'id': 'calc_aniversario_doces_padrao',
      'titulo': 'Cálculo docinhos',
      'descricao':
          'Oriente sobre a quantidade padrão de doces finos e tradicionais por pessoa.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'consumo',
      'prioridade': 'baixa',
      'gatilhos': {'adultos_minimo': 20},
      'tags': ['aniversario', 'doces'],
      'ativo': true,
      'ordem': 7
    },
    {
      'id': 'calc_alcool_controle',
      'titulo': 'Consumo de bebidas alcoolicas',
      'descricao':
          'Recomende um cálculo baseado na estimativa de perfil dos convidados para evitar desperdício.',
      'modulo': 'calculadora',
      'tema': 'bebidas',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'consumo',
      'prioridade': 'alta',
      'gatilhos': {'adultos_minimo': 30},
      'tags': ['bebidas', 'alcool'],
      'ativo': true,
      'ordem': 8
    },
    {
      'id': 'calc_buffet_longa_duracao',
      'titulo': 'Ajuste para longa duracao',
      'descricao':
          'Oriente a aumentar a estimativa de consumo para eventos que excedem 5 horas.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {'duracao_minima_horas': 5},
      'tags': ['buffet', 'duracao'],
      'ativo': true,
      'ordem': 9
    },
    {
      'id': 'calc_percentual_criancas',
      'titulo': 'Impacto do percentual infantil',
      'descricao':
          'Sugerir a readequação do cardápio se o percentual de crianças for superior a 30%.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {'percentual_criancas_minimo': 30},
      'tags': ['cardapio', 'infantil'],
      'ativo': true,
      'ordem': 10
    },

// ORCAMENTO (10)
    {
      'id': 'orc_reserva_emergencia',
      'titulo': 'Fundo de emergência',
      'descricao':
          'Sugira a criação de uma reserva de 10% do orçamento para imprevistos.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {'diferenca_orcamento_maxima': 1000},
      'tags': ['financeiro', 'reserva'],
      'ativo': true,
      'ordem': 11
    },
    {
      'id': 'orc_formatura_rateio',
      'titulo': 'Gestão de rateio',
      'descricao':
          'Oriente sobre a necessidade de definir custos fixos claros para transparência.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'critica',
      'gatilhos': {},
      'tags': ['formatura', 'rateio'],
      'ativo': true,
      'ordem': 12
    },
    {
      'id': 'orc_corporativo_prestacao',
      'titulo': 'Documentacao de despesas',
      'descricao':
          'Recomende o registro rigoroso para facilitar a prestação de contas corporativa.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'contas'],
      'ativo': true,
      'ordem': 13
    },
    {
      'id': 'orc_prioridade_gastos',
      'titulo': 'Priorização de verbas',
      'descricao':
          'Sugerir que o usuário defina os itens inegociáveis para direcionar a verba.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'prioridades'],
      'ativo': true,
      'ordem': 14
    },
    {
      'id': 'orc_cha_bebe_economico',
      'titulo': 'Foco no essencial',
      'descricao':
          'Oriente a priorização de gastos com itens de bem-estar do bebê.',
      'modulo': 'orcamento',
      'tema': 'economia',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['economico'],
      'categoria': 'economia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'economia'],
      'ativo': true,
      'ordem': 15
    },
    {
      'id': 'orc_infantil_entretenimento',
      'titulo': 'Verba de recreação',
      'descricao':
          'Sugerir alocação de verba específica para entretenimento infantil.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['infantil', 'entretenimento'],
      'ativo': true,
      'ordem': 16
    },
    {
      'id': 'orc_aniversario_limite',
      'titulo': 'Teto de gastos',
      'descricao':
          'Recomende o acompanhamento do saldo restante para não ultrapassar o limite.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'media',
      'gatilhos': {'diferenca_orcamento_maxima': 500},
      'tags': ['aniversario', 'controle'],
      'ativo': true,
      'ordem': 17
    },
    {
      'id': 'orc_pagamento_fornecedores',
      'titulo': 'Cronograma pagamentos',
      'descricao': 'Sugerir organização das datas de vencimento dos contratos.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {'fornecedores_pendentes_minimo': 2},
      'tags': ['fornecedores', 'pagamento'],
      'ativo': true,
      'ordem': 18
    },
    {
      'id': 'orc_reducao_custos_decor',
      'titulo': 'Otimizacao decorativa',
      'descricao':
          'Oriente sobre o uso de flores da estação para reduzir custos de decoração.',
      'modulo': 'orcamento',
      'tema': 'economia',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.aniversario],
      'perfis_festa': ['economico'],
      'categoria': 'economia',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['decoracao', 'economia'],
      'ativo': true,
      'ordem': 19
    },
    {
      'id': 'orc_conferencia_faturas',
      'titulo': 'Conferencia de faturas',
      'descricao':
          'Recomende a verificação detalhada de todas as faturas emitidas por fornecedores.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['financeiro', 'fatura'],
      'ativo': true,
      'ordem': 20
    },

// CONVIDADOS (10)
    {
      'id': 'conv_rsvp_ativo',
      'titulo': 'Gestão de convidados',
      'descricao':
          'Recomende acompanhamento ativo das respostas para confirmação.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.formatura],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'convidados',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 15},
      'tags': ['convidados', 'rsvp'],
      'ativo': true,
      'ordem': 21
    },
    {
      'id': 'conv_infantil_acompanhantes',
      'titulo': 'Controle de acompanhantes',
      'descricao':
          'Sugerir solicitar confirmação de presença dos pais junto aos filhos.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['infantil', 'convidados'],
      'ativo': true,
      'ordem': 22
    },
    {
      'id': 'conv_corporativo_checkin',
      'titulo': 'Credenciamento',
      'descricao': 'Indicar uso de lista digital para facilitar a recepção.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'media',
      'gatilhos': {'quantidade_minima_convidados': 30},
      'tags': ['corporativo', 'checkin'],
      'ativo': true,
      'ordem': 23
    },
    {
      'id': 'conv_cha_bebe_lista',
      'titulo': 'Lista de convidados',
      'descricao':
          'Oriente a classificação de convidados para facilitar o envio.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'convidados',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'convidados'],
      'ativo': true,
      'ordem': 24
    },
    {
      'id': 'conv_aniversario_idade',
      'titulo': 'Perfil por idade',
      'descricao': 'Sugerir separar convidados por faixa etária.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['aniversario', 'organizacao'],
      'ativo': true,
      'ordem': 25
    },
    {
      'id': 'conv_restricoes_alimentares',
      'titulo': 'Restricoes no convite',
      'descricao':
          'Oriente a solicitar informações sobre restrições alimentares.',
      'modulo': 'convidados',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'convidados',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['convidados', 'inclusao'],
      'ativo': true,
      'ordem': 26
    },
    {
      'id': 'conv_formatura_familia',
      'titulo': 'Prioridade familiar',
      'descricao': 'Sugerir destacar a cota de convites para família imediata.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['formatura', 'convites'],
      'ativo': true,
      'ordem': 27
    },
    {
      'id': 'conv_lista_digital',
      'titulo': 'Convite interativo',
      'descricao': 'Recomende envio de convites digitais para rastreabilidade.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'convidados',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['convite', 'digital'],
      'ativo': true,
      'ordem': 28
    },
    {
      'id': 'conv_lista_espera',
      'titulo': 'Gestão de espera',
      'descricao':
          'Oriente o usuário a criar lista de espera caso convidados declinem.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['convidados', 'gestao'],
      'ativo': true,
      'ordem': 29
    },
    {
      'id': 'conv_agrupamento_familia',
      'titulo': 'Agrupamento familiar',
      'descricao':
          'Sugira agrupar convidados por família ou afinidade na lista.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['convidados', 'organizacao'],
      'ativo': true,
      'ordem': 30
    },

// FORNECEDORES (10)
    {
      'id': 'forn_casamento_contratos',
      'titulo': 'Revisao de contratos',
      'descricao': 'Sugerir atenção minuciosa a cláusulas de rescisão.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 90},
      'tags': ['casamento', 'contrato'],
      'ativo': true,
      'ordem': 31
    },
    {
      'id': 'forn_infantil_referencias',
      'titulo': 'Checagem de referencias',
      'descricao':
          'Oriente verificar a reputação de fornecedores de recreação.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['infantil', 'seguranca'],
      'ativo': true,
      'ordem': 32
    },
    {
      'id': 'forn_corporativo_tecnico',
      'titulo': 'Suporte tecnico',
      'descricao': 'Recomende testar equipamentos de som e imagem.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'tecnico'],
      'ativo': true,
      'ordem': 33
    },
    {
      'id': 'forn_formatura_foto',
      'titulo': 'Experiencia em formaturas',
      'descricao':
          'Sugerir priorizar fotógrafos com experiência em cerimônias.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['formatura', 'foto'],
      'ativo': true,
      'ordem': 34
    },
    {
      'id': 'forn_cha_bebe_bolos',
      'titulo': 'Confeitaria especializada',
      'descricao': 'Recomende buscar profissionais em bolos decorados.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'bolo'],
      'ativo': true,
      'ordem': 35
    },
    {
      'id': 'forn_aniversario_dj',
      'titulo': 'DJ e repertorio',
      'descricao':
          'Sugerir validar se o DJ possui experiência com o estilo da festa.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['aniversario', 'dj'],
      'ativo': true,
      'ordem': 36
    },
    {
      'id': 'forn_avaliacoes_finais',
      'titulo': 'Feedback de fornecedores',
      'descricao': 'Recomende registrar feedbacks para futuras referências.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['fornecedor', 'feedback'],
      'ativo': true,
      'ordem': 37
    },
    {
      'id': 'forn_orcamento_acordo',
      'titulo': 'Negociação de prazos',
      'descricao': 'Oriente sobre alinhar cronogramas de montagem.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['fornecedor', 'cronograma'],
      'ativo': true,
      'ordem': 38
    },
    {
      'id': 'forn_seguranca_juridica',
      'titulo': 'Conformidade legal',
      'descricao':
          'Oriente verificar se fornecedores possuem alvarás e seguros necessários.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.corporativo, EventoConsts.formatura],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'critica',
      'gatilhos': {},
      'tags': ['fornecedor', 'legal'],
      'ativo': true,
      'ordem': 39
    },
    {
      'id': 'forn_degustacao',
      'titulo': 'Degustacao previa',
      'descricao':
          'Recomende solicitar degustação de cardápio antes do fechamento.',
      'modulo': 'fornecedores',
      'tema': 'fornecedor',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.aniversario],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['fornecedor', 'cardapio'],
      'ativo': true,
      'ordem': 40
    },

// CHECKLIST (10)
    {
      'id': 'chk_casamento_semana',
      'titulo': 'Checklist de ultima hora',
      'descricao': 'Recomende verificar confirmações na semana do evento.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 7},
      'tags': ['casamento', 'checklist'],
      'ativo': true,
      'ordem': 41
    },
    {
      'id': 'chk_aniversario_tarefas',
      'titulo': 'Tarefas pendentes',
      'descricao': 'Sugira priorizar tarefas de decoração e convites.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'media',
      'gatilhos': {'tarefas_pendentes_minimo': 3},
      'tags': ['aniversario', 'tarefas'],
      'ativo': true,
      'ordem': 42
    },
    {
      'id': 'chk_corporativo_cronograma',
      'titulo': 'Cronograma do evento',
      'descricao': 'Oriente a criação de um checklist minuto a minuto.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'agenda'],
      'ativo': true,
      'ordem': 43
    },
    {
      'id': 'chk_formatura_documentos',
      'titulo': 'Documentacao academica',
      'descricao': 'Recomende listar todas as obrigações junto à instituição.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'critica',
      'gatilhos': {},
      'tags': ['formatura', 'checklist'],
      'ativo': true,
      'ordem': 44
    },
    {
      'id': 'chk_cha_bebe_brincadeiras',
      'titulo': 'Itens para brincadeiras',
      'descricao': 'Sugira verificar materiais para o chá de bebê.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'checklist',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'tarefas'],
      'ativo': true,
      'ordem': 45
    },
    {
      'id': 'chk_infantil_seguranca',
      'titulo': 'Verificacao de segurança',
      'descricao': 'Oriente um checklist de segurança no espaço.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['infantil', 'seguranca'],
      'ativo': true,
      'ordem': 46
    },
    {
      'id': 'chk_kit_emergencia',
      'titulo': 'Kit de emergencia',
      'descricao':
          'Sugira preparar um kit com itens básicos (fita, costura, remédios).',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['checklist', 'utilidades'],
      'ativo': true,
      'ordem': 47
    },
    {
      'id': 'chk_sinalizacao_local',
      'titulo': 'Sinalizacao do local',
      'descricao':
          'Oriente verificar se o local está bem sinalizado para convidados.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['checklist', 'logistica'],
      'ativo': true,
      'ordem': 48
    },
    {
      'id': 'chk_teste_som',
      'titulo': 'Teste de som',
      'descricao':
          'Recomende realizar teste de som antes da abertura das portas.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.corporativo, EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['checklist', 'tecnico'],
      'ativo': true,
      'ordem': 49
    },
    {
      'id': 'chk_pos_evento',
      'titulo': 'Checklist pos-evento',
      'descricao':
          'Sugerir tarefas de encerramento, como pagamento final e avaliação.',
      'modulo': 'checklist',
      'tema': 'checklist',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['checklist', 'pos_evento'],
      'ativo': true,
      'ordem': 50
    },

// CARDAPIO (10)
    {
      'id': 'card_restricoes_cardapio',
      'titulo': 'Cardapio inclusivo',
      'descricao': 'Recomende incluir opções vegetarianas se necessário.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['inclusao', 'cardapio'],
      'ativo': true,
      'ordem': 51
    },
    {
      'id': 'card_casamento_menu',
      'titulo': 'Escolha do menu',
      'descricao':
          'Sugerir menu equilibrado que agrade a diferentes paladares.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'cardapio'],
      'ativo': true,
      'ordem': 52
    },
    {
      'id': 'card_corporativo_almoco',
      'titulo': 'Menu corporativo',
      'descricao': 'Oriente a escolha de refeições leves para produtividade.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['corporativo', 'menu'],
      'ativo': true,
      'ordem': 53
    },
    {
      'id': 'card_infantil_saudavel',
      'titulo': 'Menu infantil saudavel',
      'descricao': 'Sugira integrar frutas no cardápio das crianças.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['infantil', 'cardapio'],
      'ativo': true,
      'ordem': 54
    },
    {
      'id': 'card_formatura_coquetel',
      'titulo': 'Coquetel volante',
      'descricao': 'Recomende coquetel para eventos sem mesas fixas.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['formatura', 'cardapio'],
      'ativo': true,
      'ordem': 55
    },
    {
      'id': 'card_cha_bebe_leve',
      'titulo': 'Lanches para cha',
      'descricao': 'Sugerir finger foods leves.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'cardapio',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'cardapio'],
      'ativo': true,
      'ordem': 56
    },
    {
      'id': 'card_hidratação',
      'titulo': 'Pontos de hidratação',
      'descricao': 'Recomende ilhas de água em eventos longos.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cardapio', 'bebidas'],
      'ativo': true,
      'ordem': 57
    },
    {
      'id': 'card_mesa_doces',
      'titulo': 'Mesa de doces',
      'descricao':
          'Sugerir montagem estética da mesa de doces como ponto focal.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.aniversario],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cardapio', 'doces'],
      'ativo': true,
      'ordem': 58
    },
    {
      'id': 'card_estacoes_tematicas',
      'titulo': 'Estacoes tematicas',
      'descricao': 'Oriente o uso de estações de comida ao vivo.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.formatura],
      'perfis_festa': ['premium'],
      'categoria': 'cardapio',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cardapio', 'experiencia'],
      'ativo': true,
      'ordem': 59
    },
    {
      'id': 'card_alergias_sinalizacao',
      'titulo': 'Sinalizacao de alergias',
      'descricao':
          'Recomende informar os convidados sobre ingredientes alergênicos.',
      'modulo': 'cardapio',
      'tema': 'cardapio',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['cardapio', 'seguranca'],
      'ativo': true,
      'ordem': 60
    },

// DECORACAO (10)
    {
      'id': 'decor_corporativo_marca',
      'titulo': 'Identidade visual',
      'descricao': 'Recomende cores alinhadas ao branding.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'decoracao',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['corporativo', 'branding'],
      'ativo': true,
      'ordem': 61
    },
    {
      'id': 'decor_casamento_estilo',
      'titulo': 'Consistencia visual',
      'descricao': 'Oriente a escolha de paleta de cores consistente.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'decoracao',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'decoracao'],
      'ativo': true,
      'ordem': 62
    },
    {
      'id': 'decor_infantil_temas',
      'titulo': 'Temas em alta',
      'descricao': 'Sugerir temas populares.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['infantil', 'temas'],
      'ativo': true,
      'ordem': 63
    },
    {
      'id': 'decor_formatura_solene',
      'titulo': 'Decoracao solene',
      'descricao': 'Recomende elementos decorativos sóbrios.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['formatura', 'decoracao'],
      'ativo': true,
      'ordem': 64
    },
    {
      'id': 'decor_aniversario_baloes',
      'titulo': 'Decoracao de baloes',
      'descricao': 'Sugira uso de balões orgânicos.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['aniversario', 'decoracao'],
      'ativo': true,
      'ordem': 65
    },
    {
      'id': 'decor_cha_bebe_delicado',
      'titulo': 'Estilo delicado',
      'descricao': 'Recomende cores pastéis.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['padrao'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'estilo'],
      'ativo': true,
      'ordem': 66
    },
    {
      'id': 'decor_iluminacao_cenica',
      'titulo': 'Iluminacao cenica',
      'descricao':
          'Sugira uso de iluminação cênica para transformar o ambiente.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.corporativo],
      'perfis_festa': ['premium'],
      'categoria': 'decoracao',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['decoracao', 'iluminacao'],
      'ativo': true,
      'ordem': 67
    },
    {
      'id': 'decor_flores_estacao',
      'titulo': 'Flores da estacao',
      'descricao': 'Oriente o uso de flores da estação para custo-benefício.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['decoracao', 'flores'],
      'ativo': true,
      'ordem': 68
    },
    {
      'id': 'decor_personalizacao',
      'titulo': 'Itens personalizados',
      'descricao':
          'Sugira incluir detalhes que reflitam a personalidade do evento.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.aniversario, EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['decoracao', 'personalizacao'],
      'ativo': true,
      'ordem': 69
    },
    {
      'id': 'decor_acessos',
      'titulo': 'Decoracao de entrada',
      'descricao': 'Recomende atenção à entrada como impacto visual inicial.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'decoracao',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['decoracao', 'impacto'],
      'ativo': true,
      'ordem': 70
    },

// PRESENTES (10)
    {
      'id': 'pres_casamento_lista',
      'titulo': 'Lista de presentes',
      'descricao': 'Sugerir sites online.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'presentes',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'lista'],
      'ativo': true,
      'ordem': 71
    },
    {
      'id': 'pres_cha_bebe_essenciais',
      'titulo': 'Lista de enxoval',
      'descricao': 'Oriente a criação de lista essencial.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.chaDeBebe],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'enxoval'],
      'ativo': true,
      'ordem': 72
    },
    {
      'id': 'pres_aniversario_sugestoes',
      'titulo': 'Sugestoes de presentes',
      'descricao': 'Recomende incluir no convite.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['aniversario', 'presentes'],
      'ativo': true,
      'ordem': 73
    },
    {
      'id': 'pres_lembrancas_formatura',
      'titulo': 'Lembrancas de formatura',
      'descricao': 'Sugerir itens que remetam à conquista.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['formatura', 'lembranca'],
      'ativo': true,
      'ordem': 74
    },
    {
      'id': 'pres_agradecimento',
      'titulo': 'Cartao agradecimento',
      'descricao':
          'Oriente enviar agradecimentos após o recebimento dos presentes.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.chaDeBebe],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['presentes', 'agradecimento'],
      'ativo': true,
      'ordem': 75
    },
    {
      'id': 'pres_cota_lua_mel',
      'titulo': 'Cotar lua de mel',
      'descricao': 'Sugira a criação de cotas de lua de mel como presente.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.casamento],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'presentes',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['presentes', 'casamento'],
      'ativo': true,
      'ordem': 76
    },
    {
      'id': 'pres_infantil_didatico',
      'titulo': 'Brinquedos didaticos',
      'descricao': 'Sugerir focar em presentes didáticos para festas infantis.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['presentes', 'infantil'],
      'ativo': true,
      'ordem': 77
    },
    {
      'id': 'pres_gestao_lista',
      'titulo': 'Atualização de lista',
      'descricao': 'Recomende manter a lista de presentes sempre atualizada.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.chaDeBebe],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['presentes', 'gestao'],
      'ativo': true,
      'ordem': 78
    },
    {
      'id': 'pres_lembrancas_corporativas',
      'titulo': 'Mimos corporativos',
      'descricao': 'Sugira brindes úteis para eventos corporativos.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['presentes', 'corporativo'],
      'ativo': true,
      'ordem': 79
    },
    {
      'id': 'pres_estratégia_convidado',
      'titulo': 'Estrategia de presentes',
      'descricao': 'Oriente sobre manter uma faixa de preços variada na lista.',
      'modulo': 'presentes',
      'tema': 'presentes',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['presentes', 'estrategia'],
      'ativo': true,
      'ordem': 80
    },

// ESPACO_CONVIDADOS (10)
    {
      'id': 'esp_acessibilidade',
      'titulo': 'Verificacao de acessibilidade',
      'descricao': 'Oriente conferir se o espaço é adaptado.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['acessibilidade', 'local'],
      'ativo': true,
      'ordem': 81
    },
    {
      'id': 'esp_estacionamento',
      'titulo': 'Logistica de chegada',
      'descricao': 'Sugerir verificar estacionamento.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['logistica', 'estacionamento'],
      'ativo': true,
      'ordem': 82
    },
    {
      'id': 'esp_clima_plano_b',
      'titulo': 'Plano B para clima',
      'descricao': 'Oriente ter opção coberta em locais ao ar livre.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['local', 'clima'],
      'ativo': true,
      'ordem': 83
    },
    {
      'id': 'esp_conforto_termico',
      'titulo': 'Conforto termico',
      'descricao': 'Sugerir verificar sistemas de climatização do salão.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['local', 'conforto'],
      'ativo': true,
      'ordem': 84
    },
    {
      'id': 'esp_iluminacao_natural',
      'titulo': 'Iluminacao natural',
      'descricao': 'Oriente o uso de luz natural para eventos diurnos.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.chaDeBebe, EventoConsts.festaInfantil],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['local', 'ambiente'],
      'ativo': true,
      'ordem': 85
    },
    {
      'id': 'esp_acustica',
      'titulo': 'Acustica do ambiente',
      'descricao':
          'Sugerir avaliar a acústica para eventos com música ao vivo.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['local', 'acustica'],
      'ativo': true,
      'ordem': 86
    },
    {
      'id': 'esp_wifi',
      'titulo': 'Disponibilidade de rede',
      'descricao': 'Recomende testar o Wi-Fi para convidados.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.corporativo, EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['local', 'tecnologia'],
      'ativo': true,
      'ordem': 87
    },
    {
      'id': 'esp_banheiros',
      'titulo': 'Capacidade de banheiros',
      'descricao':
          'Oriente verificar se a capacidade de banheiros atende o número de convidados.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['local', 'servicos'],
      'ativo': true,
      'ordem': 88
    },
    {
      'id': 'esp_sala_apoio',
      'titulo': 'Sala de apoio',
      'descricao':
          'Sugira verificar se existe sala para troca de roupas ou apoio.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.chaDeBebe],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['local', 'apoio'],
      'ativo': true,
      'ordem': 89
    },
    {
      'id': 'esp_seguranca_local',
      'titulo': 'Seguranca predial',
      'descricao':
          'Recomende conferir se o espaço oferece equipe de segurança.',
      'modulo': 'espaco_convidados',
      'tema': 'experiencia',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['local', 'seguranca'],
      'ativo': true,
      'ordem': 90
    },

// REFERENCIAS (10)
    {
      'id': 'ref_painel_visual',
      'titulo': 'Painel de inspiracoes',
      'descricao': 'Recomende ao usuário criar painel visual.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['inspiracao', 'visual'],
      'ativo': true,
      'ordem': 91
    },
    {
      'id': 'ref_estilo_convite',
      'titulo': 'Estilo de convite',
      'descricao': 'Sugerir buscar referências que combinem.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['convite', 'design'],
      'ativo': true,
      'ordem': 92
    },
    {
      'id': 'ref_paleta_cores',
      'titulo': 'Paleta de cores',
      'descricao': 'Oriente o uso de ferramentas para definir paleta de cores.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.aniversario],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'cores'],
      'ativo': true,
      'ordem': 93
    },
    {
      'id': 'ref_tendencias_decor',
      'titulo': 'Tendencias de decoracao',
      'descricao': 'Sugerir buscar tendências anuais.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'decoracao'],
      'ativo': true,
      'ordem': 94
    },
    {
      'id': 'ref_layout_mesa',
      'titulo': 'Layout de mesas',
      'descricao': 'Recomende buscar referências de disposição de mesas.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.corporativo],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'layout'],
      'ativo': true,
      'ordem': 95
    },
    {
      'id': 'ref_inspiracao_foto',
      'titulo': 'Inspiracao fotografica',
      'descricao': 'Sugira criar lista de poses ou ângulos desejados.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.casamento, EventoConsts.formatura],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'foto'],
      'ativo': true,
      'ordem': 96
    },
    {
      'id': 'ref_estilo_bolo',
      'titulo': 'Estilo de bolos',
      'descricao': 'Oriente a buscar referências de bolos temáticos.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.aniversario, EventoConsts.casamento],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'bolo'],
      'ativo': true,
      'ordem': 97
    },
    {
      'id': 'ref_identidade_visual',
      'titulo': 'Identidade visual completa',
      'descricao': 'Recomende alinhar todos os materiais gráficos.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.corporativo, EventoConsts.casamento],
      'perfis_festa': ['premium'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'identidade'],
      'ativo': true,
      'ordem': 98
    },
    {
      'id': 'ref_temas_infantis',
      'titulo': 'Temas infantis',
      'descricao': 'Sugira buscar referências de temas lúdicos.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.festaInfantil, EventoConsts.chaDeBebe],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'infantil'],
      'ativo': true,
      'ordem': 99
    },
    {
      'id': 'ref_organização_referências',
      'titulo': 'Pasta de referências',
      'descricao': 'Oriente organizar as referências salvas por categoria.',
      'modulo': 'referencias',
      'tema': 'referencias',
      'tipo_evento': [EventoConsts.todos],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['referencias', 'organizacao'],
      'ativo': true,
      'ordem': 100
    },
  ];

  List<Map<String, dynamic>> sugestoesBaseFestaSeed002 = [
// CALCULADORA
    {
      'id': 'calculadora_bebidas_ajuste_calor',
      'titulo': 'Ajuste de bebidas por clima',
      'descricao':
          'Recomende aumentar o volume estimado de bebidas não alcoólicas e água caso a data do evento coincida com meses de temperaturas elevadas na região.',
      'modulo': 'calculadora',
      'tema': 'bebidas',
      'tipo_evento': ['todos'],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {'dias_antes_evento': 30},
      'tags': ['bebidas', 'clima'],
      'ativo': true,
      'ordem': 1,
    },
    {
      'id': 'calculadora_buffet_infantil_ajuste',
      'titulo': 'Cálculo de buffet infantil',
      'descricao':
          'Oriente a IA a considerar que crianças consomem menos que adultos, sugerindo o cálculo proporcional baseado na idade média dos pequenos convidados.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {'criancas_minimo': 10},
      'tags': ['buffet', 'infantil'],
      'ativo': true,
      'ordem': 2,
    },
    {
      'id': 'calculadora_almoco_corporativo_padrao',
      'titulo': 'Cálculo para almoço corporativo',
      'descricao':
          'Indique porções padrão para eventos corporativos, focando em opções versáteis que agradem diferentes paladares em ambientes de negócios.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {'adultos_minimo': 20},
      'tags': ['corporativo', 'almoço'],
      'ativo': true,
      'ordem': 3,
    },

// ORCAMENTO
    {
      'id': 'orcamento_reserva_emergencia',
      'titulo': 'Fundo de reserva',
      'descricao':
          'Sugerir a criação de um fundo de emergência de 10% a 15% sobre o total do orçamento para cobrir imprevistos de última hora.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {'diferenca_orcamento_maxima': 1000},
      'tags': ['financeiro', 'casamento'],
      'ativo': true,
      'ordem': 4,
    },
    {
      'id': 'orcamento_formatura_rateio',
      'titulo': 'Rateio de custos em formatura',
      'descricao':
          'Orientar sobre a importância de definir custos fixos e variáveis para garantir que o rateio entre formandos seja justo.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'critica',
      'gatilhos': {'quantidade_minima_convidados': 50},
      'tags': ['formatura', 'rateio'],
      'ativo': true,
      'ordem': 5,
    },

// CONVIDADOS
    {
      'id': 'convidados_cha_bebe_acompanhantes',
      'titulo': 'Gestão de acompanhantes',
      'descricao':
          'Lembrar de perguntar aos convidados se virão acompanhados de crianças, para ajustar a contagem de buffet e lembrancinhas no Chá de Bebê.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'convidados',
      'prioridade': 'media',
      'gatilhos': {'convidados_equivalentes_minimo': 30},
      'tags': ['cha_de_bebe', 'lista'],
      'ativo': true,
      'ordem': 6,
    },
    {
      'id': 'convidados_corporativo_checkin',
      'titulo': 'Check-in em eventos corporativos',
      'descricao':
          'Sugerir a criação de uma lista digital para facilitar o credenciamento e o controle de presença no evento corporativo.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'convidados',
      'prioridade': 'media',
      'gatilhos': {'adultos_minimo': 50},
      'tags': ['corporativo', 'checkin'],
      'ativo': true,
      'ordem': 7,
    },

// FORNECEDORES
    {
      'id': 'fornecedores_casamento_contrato',
      'titulo': 'Verificação de contratos',
      'descricao':
          'Alertar para a necessidade de revisar todas as cláusulas de rescisão e multas em contratos de fornecedores de casamento.',
      'modulo': 'fornecedores',
      'tema': 'seguranca',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 90},
      'tags': ['contrato', 'casamento'],
      'ativo': true,
      'ordem': 8,
    },
    {
      'id': 'fornecedores_infantil_recreacao',
      'titulo': 'Seleção de recreação',
      'descricao':
          'Priorizar fornecedores de recreação infantil com referências comprovadas e equipe treinada para segurança dos pequenos.',
      'modulo': 'fornecedores',
      'tema': 'animacao',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'alta',
      'gatilhos': {'criancas_minimo': 15},
      'tags': ['recreacao', 'infantil'],
      'ativo': true,
      'ordem': 9,
    },

// CHECKLIST
    {
      'id': 'checklist_aniversario_atraso',
      'titulo': 'Monitoramento de tarefas',
      'descricao':
          'Identificar tarefas pendentes próximas ao prazo de vencimento para evitar acúmulo de trabalho na semana do aniversário.',
      'modulo': 'checklist',
      'tema': 'gestao',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'checklist',
      'prioridade': 'alta',
      'gatilhos': {'tarefas_pendentes_minimo': 5},
      'tags': ['gestao', 'aniversario'],
      'ativo': true,
      'ordem': 10,
    },
    {
      'id': 'checklist_formatura_documentacao',
      'titulo': 'Prazo de documentos',
      'descricao':
          'Lembrar que eventos de formatura possuem prazos rigorosos com instituições de ensino e cerimonial, sugerindo atenção extra.',
      'modulo': 'checklist',
      'tema': 'formatura',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 60},
      'tags': ['documentos', 'formatura'],
      'ativo': true,
      'ordem': 11,
    },

// CARDAPIO
    {
      'id': 'cardapio_restricoes_alimentares',
      'titulo': 'Atenção a restrições',
      'descricao':
          'Sugerir a inclusão de opções vegetarianas, veganas ou sem glúten se houver convidados com restrições listados.',
      'modulo': 'cardapio',
      'tema': 'alimentacao',
      'tipo_evento': ['todos'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'cardapio',
      'prioridade': 'alta',
      'gatilhos': {'quantidade_minima_convidados': 20},
      'tags': ['dieta', 'inclusao'],
      'ativo': true,
      'ordem': 12,
    },
    {
      'id': 'cardapio_cha_bebe_leve',
      'titulo': 'Menu para chá de bebê',
      'descricao':
          'Recomendar opções de comidas leves, finger foods e estações de doces condizentes com o ambiente diurno do chá de bebê.',
      'modulo': 'cardapio',
      'tema': 'alimentacao',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'cardapio'],
      'ativo': true,
      'ordem': 13,
    },

// DECORACAO
    {
      'id': 'decoracao_corporativo_identidade',
      'titulo': 'Identidade visual',
      'descricao':
          'Orientar o uso de paleta de cores alinhada à marca da empresa para fortalecer o branding no evento corporativo.',
      'modulo': 'decoracao',
      'tema': 'identidade',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'decoracao',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['corporativo', 'branding'],
      'ativo': true,
      'ordem': 14,
    },
    {
      'id': 'decoracao_infantil_tematica',
      'titulo': 'Segurança na decoração',
      'descricao':
          'Recomendar que elementos de decoração infantil não possuam quinas vivas ou peças pequenas que possam ser ingeridas.',
      'modulo': 'decoracao',
      'tema': 'seguranca',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'decoracao',
      'prioridade': 'alta',
      'gatilhos': {'criancas_minimo': 5},
      'tags': ['infantil', 'seguranca'],
      'ativo': true,
      'ordem': 15,
    },

// PRESENTES
    {
      'id': 'presentes_cha_bebe_lista',
      'titulo': 'Lista de presentes prática',
      'descricao':
          'Sugerir criar uma lista de presentes organizada por categorias de utilidade (higiene, vestuário, quarto) para facilitar a vida dos convidados.',
      'modulo': 'presentes',
      'tema': 'cha_bebe',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'presentes',
      'prioridade': 'media',
      'gatilhos': {'dias_antes_evento': 45},
      'tags': ['cha_de_bebe', 'lista_presentes'],
      'ativo': true,
      'ordem': 16,
    },
    {
      'id': 'presentes_casamento_cota',
      'titulo': 'Cotas de lua de mel',
      'descricao':
          'Sugestão de incluir cotas de lua de mel como alternativa à lista tradicional, muito comum em casamentos atuais.',
      'modulo': 'presentes',
      'tema': 'casamento',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'presentes',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'lua_de_mel'],
      'ativo': true,
      'ordem': 17,
    },

// ESPACO CONVIDADOS
    {
      'id': 'espaco_formatura_acessibilidade',
      'titulo': 'Acessibilidade do espaço',
      'descricao':
          'Certificar-se de que o local do evento de formatura possua rampas e banheiros adaptados para receber todos os formandos e convidados.',
      'modulo': 'espaco_convidados',
      'tema': 'local',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['formatura', 'acessibilidade'],
      'ativo': true,
      'ordem': 18,
    },
    {
      'id': 'espaco_corporativo_internet',
      'titulo': 'Conectividade do local',
      'descricao':
          'Recomendar a verificação da qualidade do Wi-Fi no local para eventos corporativos que utilizam apresentações interativas ou votações online.',
      'modulo': 'espaco_convidados',
      'tema': 'tecnologia',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'internet'],
      'ativo': true,
      'ordem': 19,
    },

// REFERENCIAS
    {
      'id': 'referencias_casamento_estilo',
      'titulo': 'Consistência de estilo',
      'descricao':
          'Orientar o usuário a salvar referências visuais que mantenham uma paleta de cores consistente para a decoração do casamento.',
      'modulo': 'referencias',
      'tema': 'estilo',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'referencias',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'decoracao'],
      'ativo': true,
      'ordem': 20,
    },
    {
      'id': 'referencias_aniversario_tematico',
      'titulo': 'Ideias para festa temática',
      'descricao':
          'Sugerir a busca por referências visuais que combinem com o tema do aniversário, garantindo que o convite e decoração conversem entre si.',
      'modulo': 'referencias',
      'tema': 'estilo',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['padrao'],
      'categoria': 'referencias',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['aniversario', 'estilo'],
      'ativo': true,
      'ordem': 21,
    },

// ADICIONAIS PARA FECHAR 60 (Exemplos de expansão)
    {
      'id': 'orcamento_corporativo_despesas',
      'titulo': 'Controle de custos corporativos',
      'descricao':
          'Enfatizar a necessidade de registro detalhado de todas as despesas para facilitar a prestação de contas do evento corporativo.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'financas'],
      'ativo': true,
      'ordem': 22,
    },
    {
      'id': 'checklist_cha_bebe_cronograma',
      'titulo': 'Cronograma do Chá',
      'descricao':
          'Sugestão de definir uma ordem para as brincadeiras e abertura de presentes para não exceder o tempo de locação.',
      'modulo': 'checklist',
      'tema': 'organizacao',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'checklist',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'agenda'],
      'ativo': true,
      'ordem': 23,
    },
    {
      'id': 'fornecedores_formatura_fotografia',
      'titulo': 'Qualidade do registro',
      'descricao':
          'Recomendar a contratação de profissionais com portfólio específico de formaturas para capturar os momentos solenes com precisão.',
      'modulo': 'fornecedores',
      'tema': 'fotografia',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['formatura', 'foto'],
      'ativo': true,
      'ordem': 24,
    },
    {
      'id': 'cardapio_aniversario_bebidas',
      'titulo': 'Cálculo de bebidas alcóolicas',
      'descricao':
          'Recomendar a oferta de opções não alcoólicas variadas em aniversários para garantir o conforto de todos os convidados.',
      'modulo': 'cardapio',
      'tema': 'bebidas',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['padrao'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {'adultos_minimo': 30},
      'tags': ['aniversario', 'bebidas'],
      'ativo': true,
      'ordem': 25,
    },
    {
      'id': 'espaco_infantil_estacionamento',
      'titulo': 'Logística para os pais',
      'descricao':
          'Sugerir avaliar se o local possui fácil estacionamento ou acesso seguro para embarque e desembarque de crianças em festas infantis.',
      'modulo': 'espaco_convidados',
      'tema': 'local',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['infantil', 'logistica'],
      'ativo': true,
      'ordem': 26,
    },
    {
      'id': 'presentes_formatura_lembrancinhas',
      'titulo': 'Mimos de formatura',
      'descricao':
          'Sugerir a criação de pequenas lembranças personalizadas que marquem a conquista acadêmica dos formandos.',
      'modulo': 'presentes',
      'tema': 'formatura',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['formatura', 'lembrancinhas'],
      'ativo': true,
      'ordem': 27,
    },
    {
      'id': 'calculadora_casamento_buffet',
      'titulo': 'Estimativa de buffet',
      'descricao':
          'Orientar sobre o cálculo de buffet para casamentos, considerando o tempo de duração da festa para evitar falta de comida.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'consumo',
      'prioridade': 'alta',
      'gatilhos': {'duracao_minima_horas': 5},
      'tags': ['casamento', 'buffet'],
      'ativo': true,
      'ordem': 28,
    },
    {
      'id': 'orcamento_infantil_variacoes',
      'titulo': 'Custo de atrações extras',
      'descricao':
          'Alertar sobre custos adicionais com brinquedos infláveis ou entretenimento em festas infantis que podem impactar o orçamento.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['infantil', 'orcamento'],
      'ativo': true,
      'ordem': 29,
    },
    {
      'id': 'referencias_corporativo_layout',
      'titulo': 'Layout do evento',
      'descricao':
          'Recomendar o uso de referências visuais de layouts de auditório ou mesas para otimizar o espaço e a interação no evento corporativo.',
      'modulo': 'referencias',
      'tema': 'estilo',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao'],
      'categoria': 'referencias',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['corporativo', 'layout'],
      'ativo': true,
      'ordem': 30,
    },
    {
      'id': 'checklist_casamento_final',
      'titulo': 'Checklist de última semana',
      'descricao':
          'Reforçar tarefas críticas na última semana antes do casamento, como confirmação final de convidados e fornecedores.',
      'modulo': 'checklist',
      'tema': 'organizacao',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'checklist',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 7},
      'tags': ['casamento', 'checklist'],
      'ativo': true,
      'ordem': 31,
    },
    {
      'id': 'fornecedores_cha_bebe_bolo',
      'titulo': 'Especialistas em bolo temático',
      'descricao':
          'Sugerir busca por confeiteiros com expertise em bolos de fraldas ou decoração temática para Chá de Bebê.',
      'modulo': 'fornecedores',
      'tema': 'gastronomia',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'bolo'],
      'ativo': true,
      'ordem': 32,
    },
    {
      'id': 'cardapio_formatura_coquetel',
      'titulo': 'Coquetel de recepção',
      'descricao':
          'Sugerir opções de coquetel volante para recepções de formatura, permitindo maior mobilidade dos convidados.',
      'modulo': 'cardapio',
      'tema': 'alimentacao',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['formatura', 'coquetel'],
      'ativo': true,
      'ordem': 33,
    },
    {
      'id': 'espaco_aniversario_clima',
      'titulo': 'Plano B para chuva',
      'descricao':
          'Sugerir verificar se o local do aniversário possui área coberta disponível em caso de intempéries.',
      'modulo': 'espaco_convidados',
      'tema': 'local',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['aniversario', 'clima'],
      'ativo': true,
      'ordem': 34,
    },
    {
      'id': 'convidados_casamento_RSVP',
      'titulo': 'Gestão ativa do RSVP',
      'descricao':
          'Orientar sobre a importância de contatar convidados que não confirmaram presença no prazo estipulado para o casamento.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'convidados',
      'prioridade': 'critica',
      'gatilhos': {'dias_antes_evento': 15},
      'tags': ['casamento', 'rsvp'],
      'ativo': true,
      'ordem': 35,
    },
    {
      'id': 'decoracao_formatura_classica',
      'titulo': 'Decoração sóbria',
      'descricao':
          'Recomendar elementos de decoração clássicos para formaturas, mantendo o tom solene do evento.',
      'modulo': 'decoracao',
      'tema': 'estilo',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['formatura', 'decoracao'],
      'ativo': true,
      'ordem': 36,
    },
    {
      'id': 'presentes_aniversario_lista',
      'titulo': 'Sugestões de presentes',
      'descricao':
          'Sugerir incluir uma lista de sugestões de presentes no convite de aniversário para facilitar aos convidados.',
      'modulo': 'presentes',
      'tema': 'aniversario',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['aniversario', 'presentes'],
      'ativo': true,
      'ordem': 37,
    },
    {
      'id': 'calculadora_corporativo_coffee',
      'titulo': 'Cálculo de coffee break',
      'descricao':
          'Indicar proporções de itens de café e lanches para eventos corporativos curtos.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {'duracao_minima_horas': 2},
      'tags': ['corporativo', 'coffee'],
      'ativo': true,
      'ordem': 38,
    },
    {
      'id': 'orcamento_cha_bebe_detalhado',
      'titulo': 'Checklist de itens essenciais',
      'descricao':
          'Ajudar a priorizar gastos com itens essenciais no Chá de Bebê, como fraldas e itens básicos de higiene.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['economico'],
      'categoria': 'economia',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'orcamento'],
      'ativo': true,
      'ordem': 39,
    },
    {
      'id': 'fornecedores_aniversario_animador',
      'titulo': 'Verificação de antecedentes',
      'descricao':
          'Recomendar checar referências de animadores para aniversários infantis.',
      'modulo': 'fornecedores',
      'tema': 'animacao',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'fornecedor',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['infantil', 'animador'],
      'ativo': true,
      'ordem': 40,
    },
    {
      'id': 'referencias_infantil_temas',
      'titulo': 'Tendências de temas',
      'descricao':
          'Sugestão de temas em alta para festas infantis, facilitando a escolha da decoração.',
      'modulo': 'referencias',
      'tema': 'estilo',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'referencias',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['infantil', 'decoracao'],
      'ativo': true,
      'ordem': 41,
    },
    {
      'id': 'cardapio_casamento_bolo',
      'titulo': 'Seleção do bolo',
      'descricao':
          'Orientar sobre sabores de bolo para casamento, focando em clássicos que agradam a maioria.',
      'modulo': 'cardapio',
      'tema': 'gastronomia',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'cardapio',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['casamento', 'bolo'],
      'ativo': true,
      'ordem': 42,
    },
    {
      'id': 'espaco_corporativo_equipamento',
      'titulo': 'Suporte técnico do espaço',
      'descricao':
          'Verificar se o local possui projetor e som de qualidade antes de fechar o contrato do evento corporativo.',
      'modulo': 'espaco_convidados',
      'tema': 'tecnologia',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'tecnologia'],
      'ativo': true,
      'ordem': 43,
    },
    {
      'id': 'checklist_formatura_traje',
      'titulo': 'Indicação de traje',
      'descricao':
          'Lembrar de incluir no convite de formatura o traje recomendado para os convidados.',
      'modulo': 'checklist',
      'tema': 'organizacao',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao'],
      'categoria': 'checklist',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['formatura', 'convite'],
      'ativo': true,
      'ordem': 44,
    },
    {
      'id': 'convidados_aniversario_infantil',
      'titulo': 'Gerenciamento de convites',
      'descricao':
          'Sugestão de convite digital para aniversário infantil facilitando o controle de respostas.',
      'modulo': 'convidados',
      'tema': 'organizacao',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'convidados',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['infantil', 'convite'],
      'ativo': true,
      'ordem': 45,
    },
    {
      'id': 'calculadora_aniversario_doces',
      'titulo': 'Cálculo de docinhos',
      'descricao':
          'Recomendar a quantidade padrão de docinhos por pessoa para festas de aniversário.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'consumo',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['aniversario', 'doces'],
      'ativo': true,
      'ordem': 46,
    },
    {
      'id': 'orcamento_casamento_prioridades',
      'titulo': 'Priorização de gastos',
      'descricao':
          'Ajudar a definir o que é prioridade no orçamento de casamento (ex: foto vs buffet).',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['casamento', 'orcamento'],
      'ativo': true,
      'ordem': 47,
    },
    {
      'id': 'fornecedores_formatura_musica',
      'titulo': 'DJ ou Banda',
      'descricao':
          'Recomendar a escolha entre DJ ou Banda baseado no estilo dos formandos e orçamento disponível.',
      'modulo': 'fornecedores',
      'tema': 'musica',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['formatura', 'musica'],
      'ativo': true,
      'ordem': 48,
    },
    {
      'id': 'decoracao_aniversario_baloes',
      'titulo': 'Arco de balões',
      'descricao':
          'Sugestão de arcos de balões para decoração de festas infantis e aniversários.',
      'modulo': 'decoracao',
      'tema': 'decoracao',
      'tipo_evento': [
        '7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda',
        'ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'
      ],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['decoracao', 'aniversario'],
      'ativo': true,
      'ordem': 49,
    },
    {
      'id': 'presentes_casamento_lista_online',
      'titulo': 'Lista de presentes online',
      'descricao':
          'Incentivar o uso de listas de presentes em sites especializados para facilitar a compra pelos convidados.',
      'modulo': 'presentes',
      'tema': 'tecnologia',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'presentes',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'presentes'],
      'ativo': true,
      'ordem': 50,
    },
    {
      'id': 'espaco_cha_bebe_conforto',
      'titulo': 'Espaço para amamentação',
      'descricao':
          'Recomendar a reserva de um local reservado para amamentação/troca de fraldas no Chá de Bebê.',
      'modulo': 'espaco_convidados',
      'tema': 'local',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['padrao'],
      'categoria': 'experiencia',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'conforto'],
      'ativo': true,
      'ordem': 51,
    },
    {
      'id': 'referencias_corporativo_palestrantes',
      'titulo': 'Busca por palestrantes',
      'descricao':
          'Sugerir o uso de plataformas de busca para contratar palestrantes relevantes para o tema do evento corporativo.',
      'modulo': 'referencias',
      'tema': 'conteudo',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['premium'],
      'categoria': 'referencias',
      'prioridade': 'alta',
      'gatilhos': {},
      'tags': ['corporativo', 'palestrante'],
      'ativo': true,
      'ordem': 52,
    },
    {
      'id': 'checklist_aniversario_convites',
      'titulo': 'Envio de convites',
      'descricao':
          'Lembrar o prazo ideal para envio de convites de aniversário.',
      'modulo': 'checklist',
      'tema': 'organizacao',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'checklist',
      'prioridade': 'media',
      'gatilhos': {'dias_antes_evento': 20},
      'tags': ['aniversario', 'convites'],
      'ativo': true,
      'ordem': 53,
    },
    {
      'id': 'cardapio_corporativo_bebidas',
      'titulo': 'Bebidas em coquetel',
      'descricao':
          'Sugerir variedades de sucos e águas aromatizadas para recepções corporativas.',
      'modulo': 'cardapio',
      'tema': 'bebidas',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao'],
      'categoria': 'cardapio',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['corporativo', 'bebidas'],
      'ativo': true,
      'ordem': 54,
    },
    {
      'id': 'fornecedores_cha_bebe_fotografia',
      'titulo': 'Fotógrafo para o Chá',
      'descricao':
          'Recomendar a contratação de um fotógrafo para registrar o Chá de Bebê.',
      'modulo': 'fornecedores',
      'tema': 'fotografia',
      'tipo_evento': ['1eab2c53-a7d3-4a97-b473-02572464e779'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['cha_de_bebe', 'foto'],
      'ativo': true,
      'ordem': 55,
    },
    {
      'id': 'decoracao_formatura_iluminacao',
      'titulo': 'Iluminação de palco',
      'descricao':
          'Sugerir iluminação cênica para valorizar o local da cerimônia de formatura.',
      'modulo': 'decoracao',
      'tema': 'iluminacao',
      'tipo_evento': ['WlLdfdmu4Chvw2p8daUm'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'decoracao',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['formatura', 'iluminacao'],
      'ativo': true,
      'ordem': 56,
    },
    {
      'id': 'presentes_aniversario_crianca',
      'titulo': 'Lembrancinhas infantis',
      'descricao': 'Recomendar lembrancinhas criativas para festas infantis.',
      'modulo': 'presentes',
      'tema': 'infantil',
      'tipo_evento': ['ccbdb965-8f3c-4c92-bc94-2331c0ca2bb8'],
      'perfis_festa': ['padrao'],
      'categoria': 'presentes',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['infantil', 'lembrancinhas'],
      'ativo': true,
      'ordem': 57,
    },
    {
      'id': 'calculadora_casamento_bebidas',
      'titulo': 'Volume de bebidas',
      'descricao':
          'Cálculo de quantidade de espumante para brinde em casamentos.',
      'modulo': 'calculadora',
      'tema': 'bebidas',
      'tipo_evento': ['302191a2-dbf3-4ac6-ba53-08273b384cab'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['casamento', 'bebidas'],
      'ativo': true,
      'ordem': 58,
    },
    {
      'id': 'orcamento_aniversario_limite',
      'titulo': 'Controle de gastos fixos',
      'descricao':
          'Sugerir definição de orçamento para itens fixos de festa como aluguel de salão.',
      'modulo': 'orcamento',
      'tema': 'financeiro',
      'tipo_evento': ['7f8aa427-9b80-45ef-9b7c-f4e7c08ffcda'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'financeiro',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['aniversario', 'orcamento'],
      'ativo': true,
      'ordem': 59,
    },
    {
      'id': 'checklist_corporativo_agenda',
      'titulo': 'Cronograma do evento',
      'descricao':
          'Reforçar a criação de um cronograma minuto a minuto para eventos corporativos complexos.',
      'modulo': 'checklist',
      'tema': 'gestao',
      'tipo_evento': ['lXf0M5vMNvyRn52yQ2fY'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'checklist',
      'prioridade': 'alta',
      'gatilhos': {'dias_antes_evento': 14},
      'tags': ['corporativo', 'agenda'],
      'ativo': true,
      'ordem': 60,
    },
  ];

  List<Map<String, dynamic>> sugestoesBaseFestaSeed001 = [
    {
      'id': 'calculadora_bebidas_duracao_4h',
      'titulo': 'Atenção ao consumo de bebidas',
      'descricao':
          'Eventos com duração acima de 4 horas tendem a exigir maior atenção ao volume de bebidas, principalmente água, refrigerante e sucos.',
      'modulo': 'calculadora',
      'tema': 'bebidas',
      'tipo_evento': [
        'todos',
        'aniversario',
        'aniversario_infantil',
        'cha_de_bebe',
        'casamento',
        'natal',
        'ano_novo',
      ],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'alerta',
      'prioridade': 'alta',
      'gatilhos': {
        'duracao_minima_horas': 4,
        'risco_minimo': 40,
      },
      'tags': ['bebidas', 'duracao', 'consumo'],
      'ativo': true,
      'ordem': 1,
    },
    {
      'id': 'calculadora_bolo_convidados_equivalentes',
      'titulo': 'Bolo deve acompanhar convidados equivalentes',
      'descricao':
          'Use os convidados equivalentes como referência para analisar conforto de consumo, evitando estimar bolo apenas pelo número bruto de pessoas.',
      'modulo': 'calculadora',
      'tema': 'bolo',
      'tipo_evento': [
        'todos',
        'aniversario',
        'aniversario_infantil',
        'cha_de_bebe',
        'casamento',
      ],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'consumo',
      'prioridade': 'media',
      'gatilhos': {
        'convidados_equivalentes_minimo': 20,
      },
      'tags': ['bolo', 'convidados_equivalentes'],
      'ativo': true,
      'ordem': 2,
    },
    {
      'id': 'calculadora_salgadinhos_risco_faltar',
      'titulo': 'Salgadinhos são item sensível ao risco de falta',
      'descricao':
          'Quando a festa possui muitos adultos ou longa duração, salgadinhos e comidas salgadas devem receber atenção especial no planejamento.',
      'modulo': 'calculadora',
      'tema': 'salgadinhos',
      'tipo_evento': [
        'todos',
        'aniversario',
        'aniversario_infantil',
        'cha_de_bebe',
      ],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'alerta',
      'prioridade': 'alta',
      'gatilhos': {
        'risco_minimo': 50,
        'adultos_minimo': 20,
      },
      'tags': ['salgadinhos', 'comidas', 'risco'],
      'ativo': true,
      'ordem': 3,
    },
    {
      'id': 'calculadora_orcamento_acima_previsto',
      'titulo': 'Orçamento acima do previsto exige priorização',
      'descricao':
          'Quando o custo estimado ultrapassar o orçamento, priorize alimentos, bebidas e estrutura básica antes de decoração extra ou itens opcionais.',
      'modulo': 'calculadora',
      'tema': 'orcamento',
      'tipo_evento': ['todos'],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'financeiro',
      'prioridade': 'critica',
      'gatilhos': {
        'diferenca_orcamento_maxima': -1,
      },
      'tags': ['orcamento', 'priorizacao', 'custos'],
      'ativo': true,
      'ordem': 4,
    },
    {
      'id': 'calculadora_premium_orcamento_baixo',
      'titulo': 'Perfil premium com orçamento baixo precisa de ajuste',
      'descricao':
          'Se o perfil escolhido for premium e o orçamento estiver baixo, recomende reduzir escopo, negociar fornecedores ou migrar para um perfil padrão.',
      'modulo': 'calculadora',
      'tema': 'perfil_festa',
      'tipo_evento': ['todos'],
      'perfis_festa': ['premium'],
      'categoria': 'alerta',
      'prioridade': 'alta',
      'gatilhos': {
        'perfil': 'premium',
        'economia_minima': 50,
      },
      'tags': ['premium', 'orcamento', 'ajuste_de_escopo'],
      'ativo': true,
      'ordem': 5,
    },
    {
      'id': 'calculadora_muitas_criancas',
      'titulo': 'Festa com muitas crianças pede cardápio e recreação adequados',
      'descricao':
          'Quando houver muitas crianças, avalie porções menores, bebidas sem cafeína, recreação, espaço seguro e cardápio simples.',
      'modulo': 'calculadora',
      'tema': 'criancas',
      'tipo_evento': [
        'aniversario_infantil',
        'aniversario',
        'cha_de_bebe',
      ],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'organizacao',
      'prioridade': 'alta',
      'gatilhos': {
        'percentual_criancas_minimo': 35,
      },
      'tags': ['criancas', 'cardapio', 'recreacao'],
      'ativo': true,
      'ordem': 6,
    },
    {
      'id': 'calculadora_bebes_conforto',
      'titulo': 'Bebês exigem planejamento de conforto',
      'descricao':
          'Eventos com bebês devem prever espaço tranquilo, trocador, água, facilidade de acesso e horários adequados.',
      'modulo': 'calculadora',
      'tema': 'bebes',
      'tipo_evento': [
        'cha_de_bebe',
        'aniversario_infantil',
        'aniversario',
      ],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'organizacao',
      'prioridade': 'media',
      'gatilhos': {
        'bebes_minimo': 1,
      },
      'tags': ['bebes', 'conforto', 'familia'],
      'ativo': true,
      'ordem': 7,
    },
    {
      'id': 'calculadora_duracao_acima_4h',
      'titulo': 'Duração acima de 4 horas aumenta consumo geral',
      'descricao':
          'Festas longas tendem a elevar consumo de bebidas, salgados, descartáveis e necessidade de reposição.',
      'modulo': 'calculadora',
      'tema': 'duracao',
      'tipo_evento': ['todos'],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'alerta',
      'prioridade': 'alta',
      'gatilhos': {
        'duracao_minima_horas': 4,
      },
      'tags': ['duracao', 'consumo', 'reposicao'],
      'ativo': true,
      'ordem': 8,
    },
    {
      'id': 'calculadora_risco_faltar_itens',
      'titulo': 'Risco de faltar itens deve virar ação prática',
      'descricao':
          'Quando o risco de falta for alto, a análise deve indicar quais itens revisar e sugerir margem de segurança sem recalcular quantidades.',
      'modulo': 'calculadora',
      'tema': 'risco',
      'tipo_evento': ['todos'],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'alerta',
      'prioridade': 'critica',
      'gatilhos': {
        'risco_minimo': 70,
      },
      'tags': ['risco', 'itens', 'revisao'],
      'ativo': true,
      'ordem': 9,
    },
    {
      'id': 'calculadora_economia_sem_perder_essencial',
      'titulo': 'Economia deve preservar itens essenciais',
      'descricao':
          'Para economizar, reduza itens decorativos extras, lembrancinhas e personalizações antes de cortar alimentos, bebidas e conforto dos convidados.',
      'modulo': 'calculadora',
      'tema': 'economia',
      'tipo_evento': ['todos'],
      'perfis_festa': ['economico', 'padrao'],
      'categoria': 'economia',
      'prioridade': 'alta',
      'gatilhos': {
        'economia_minima': 45,
      },
      'tags': ['economia', 'essencial', 'prioridade'],
      'ativo': true,
      'ordem': 10,
    },
    {
      'id': 'calculadora_fornecedores_antecedencia',
      'titulo': 'Fornecedores devem ser acionados com antecedência',
      'descricao':
          'Itens como bolo, buffet, decoração e recreação dependem de disponibilidade; recomende solicitar orçamento cedo quando houver muitos convidados.',
      'modulo': 'calculadora',
      'tema': 'fornecedores',
      'tipo_evento': ['todos'],
      'perfis_festa': ['padrao', 'premium'],
      'categoria': 'fornecedor',
      'prioridade': 'media',
      'gatilhos': {
        'convidados_equivalentes_minimo': 30,
      },
      'tags': ['fornecedores', 'orcamento', 'antecedencia'],
      'ativo': true,
      'ordem': 11,
    },
    {
      'id': 'calculadora_cardapio_equilibrado',
      'titulo': 'Cardápio equilibrado melhora a experiência',
      'descricao':
          'Uma festa confortável combina bebidas, salgados, doces e bolo em equilíbrio, considerando adultos, crianças e duração.',
      'modulo': 'calculadora',
      'tema': 'cardapio',
      'tipo_evento': ['todos'],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'cardapio',
      'prioridade': 'media',
      'gatilhos': {},
      'tags': ['cardapio', 'equilibrio', 'experiencia'],
      'ativo': true,
      'ordem': 12,
    },
    {
      'id': 'calculadora_decoracao_priorizar_identidade_visual',
      'titulo': 'Decoração deve seguir prioridade visual',
      'descricao':
          'Para melhorar o impacto sem elevar demais o custo, priorize mesa principal, painel e poucos pontos fotográficos bem definidos.',
      'modulo': 'calculadora',
      'tema': 'decoracao',
      'tipo_evento': [
        'aniversario',
        'aniversario_infantil',
        'cha_de_bebe',
        'casamento',
      ],
      'perfis_festa': ['economico', 'padrao', 'premium'],
      'categoria': 'decoracao',
      'prioridade': 'baixa',
      'gatilhos': {},
      'tags': ['decoracao', 'identidade_visual', 'fotos'],
      'ativo': true,
      'ordem': 13,
    },
  ];

  @override
  void onClose() {
    buscaController.dispose();
    super.onClose();
  }

  Future<void> carregarSugestoes() async {
    try {
      loading.value = true;
      error.value = '';

      final sugestoes = await _repository.listarSugestoes();
      listaSugestoes.assignAll(sugestoes);
      aplicarFiltros();
    } catch (e) {
      error.value = 'Erro ao carregar sugestões IA: $e';
      listaFiltrada.clear();
    } finally {
      loading.value = false;
    }
  }

  void aplicarFiltros() {
    final modulo = filtroModulo.value.trim();
    final tema = filtroTema.value.trim();
    final tipoEvento = filtroTipoEvento.value.trim();
    final perfilFesta = filtroPerfilFesta.value.trim();
    final ativo = filtroAtivo.value.trim();
    final busca = buscaTexto.value.trim().toLowerCase();

    final filtradas = listaSugestoes.where((item) {
      if (modulo.isNotEmpty && item.modulo != modulo) return false;
      if (tema.isNotEmpty && item.tema != tema) return false;
      if (tipoEvento.isNotEmpty &&
          !item.tipoEvento.contains(tipoEvento) &&
          !item.tipoEvento.contains('todos')) {
        return false;
      }
      if (perfilFesta.isNotEmpty &&
          !item.perfisFesta.contains(perfilFesta) &&
          !item.perfisFesta.contains('todos')) {
        return false;
      }
      if (ativo == 'ativos' && !item.ativo) return false;
      if (ativo == 'inativos' && item.ativo) return false;

      if (busca.isNotEmpty) {
        final alvo = [
          item.titulo,
          item.descricao,
          item.modulo,
          item.tema,
          item.categoria,
          item.prioridade,
          item.tags.join(' '),
          item.tipoEvento.join(' '),
          item.perfisFesta.join(' '),
        ].join(' ').toLowerCase();

        if (!alvo.contains(busca)) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final ordemCompare = a.ordem.compareTo(b.ordem);
        if (ordemCompare != 0) return ordemCompare;
        return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
      });

    listaFiltrada.assignAll(filtradas);
  }

  void limparFiltros() {
    filtroModulo.value = '';
    filtroTema.value = '';
    filtroTipoEvento.value = '';
    filtroPerfilFesta.value = '';
    filtroAtivo.value = 'todos';
    buscaTexto.value = '';
    buscaController.clear();
    aplicarFiltros();
  }

  Future<void> salvar(SugestaoBaseFestaModel sugestao) async {
    try {
      saving.value = true;
      error.value = '';

      if (sugestao.isNew) {
        await _repository.salvarSugestao(sugestao);
      } else {
        await _repository.atualizarSugestao(sugestao);
      }

      await carregarSugestoes();

      Get.snackbar(
        'Sugestões IA',
        'Sugestão salva com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Erro ao salvar sugestão: $e';
      Get.snackbar(
        'Erro ao salvar',
        error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      rethrow;
    } finally {
      saving.value = false;
    }
  }

  Future<void> editar(SugestaoBaseFestaModel sugestao) async {
    sugestaoSelecionada.value = sugestao;
  }

  Future<void> ativarDesativar(SugestaoBaseFestaModel sugestao) async {
    try {
      await _repository.ativarDesativarSugestao(
        id: sugestao.id,
        ativo: !sugestao.ativo,
      );
      await carregarSugestoes();

      Get.snackbar(
        'Sugestões IA',
        sugestao.ativo ? 'Sugestão desativada.' : 'Sugestão ativada.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível alterar o status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> excluirLogicamente(SugestaoBaseFestaModel sugestao) async {
    try {
      await _repository.excluirLogicamente(sugestao.id);
      await carregarSugestoes();

      Get.snackbar(
        'Sugestões IA',
        'Sugestão removida da listagem.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível excluir a sugestão: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  List<String> get modulosDisponiveis => _uniqueSorted(
        listaSugestoes.map((e) => e.modulo),
        fallback: SugestaoBaseFestaOptions.modulos,
      );

  List<String> get temasDisponiveis => _uniqueSorted(
        listaSugestoes.map((e) => e.tema),
        fallback: SugestaoBaseFestaOptions.temas,
      );

  List<String> get tiposEventoDisponiveis => _uniqueSorted(
        listaSugestoes.expand((e) => e.tipoEvento),
        fallback: SugestaoBaseFestaOptions.tiposEvento,
      );

  List<String> get perfisFestaDisponiveis => _uniqueSorted(
        listaSugestoes.expand((e) => e.perfisFesta),
        fallback: SugestaoBaseFestaOptions.perfisFesta,
      );

  List<String> _uniqueSorted(
    Iterable<String> values, {
    required List<String> fallback,
  }) {
    final set = <String>{
      ...fallback,
      ...values.where((e) => e.trim().isNotEmpty)
    };
    final list = set.toList()..sort();
    return list;
  }
}

class SugestaoBaseFestaOptions {
  static const List<String> modulos = [
    'calculadora',
    'orcamento',
    'convidados',
    'fornecedores',
    'checklist',
    'espaco_convidados',
    'referencias',
    'cardapio',
    'decoracao',
    'presentes',
  ];

  static const List<String> temas = [
    'geral',
    'bebidas',
    'bolo',
    'salgadinhos',
    'docinhos',
    'lembrancinhas',
    'orcamento',
    'fornecedores',
    'cardapio',
    'decoracao',
    'presentes',
  ];

  static const List<String> tiposEvento = [
    'todos',
    'aniversario',
    'aniversario_infantil',
    'cha_de_bebe',
    'casamento',
    'natal',
    'ano_novo',
    'confraternizacao',
  ];

  static const List<String> perfisFesta = [
    'todos',
    'economico',
    'padrao',
    'premium',
  ];

  static const List<String> categorias = [
    'dica',
    'alerta',
    'risco',
    'economia',
    'organizacao',
    'fornecedor',
  ];

  static const List<String> prioridades = [
    'baixa',
    'media',
    'alta',
    'critica',
  ];
}

class EventoConsts {
  static const String todos = 'Todos';
  static const String chaDeBebe = '🍼 Chá de Bebê';
  static const String aniversario = '🎂 Aniversário';
  static const String festaInfantil = '🎈 Festa Infantil';
  static const String formatura = '🎓 Formatura';
  static const String casamento = '💍 Casamento';
  static const String corporativo = '💼 Evento Corporativo';
}
