import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import '../core/utils/biblioteca.dart';
import './../presentation/pages/endereco/endereco_section_controller.dart';
import './../controllers/app_controller.dart';
import './../data/models/model.dart';

class EventoCadastroController extends GetxController {
  final db = FirebaseFirestore.instance;
  final uuid = const Uuid();
  final app = Get.find<AppController>();

  /// ===============================
  /// 🔹 LISTA E MODELO DE TIPO DE EVENTO
  /// ===============================
  final tiposEvento = <TipoEventoModel>[].obs;
  final Rx<TipoEventoModel?> tipoEventoModel = Rx<TipoEventoModel?>(null);

  /// ===============================
  /// 🔹 CAMPOS CONTROLADOS PELO CONTROLLER
  /// ===============================
  final idEvento = ''.obs;
  final nomeEvento = TextEditingController();
  final nomePessoalPrincipal = TextEditingController();
  final localEvento = TextEditingController();
  final nomeNoiva = TextEditingController();
  final parceiro = TextEditingController();
  final idade = TextEditingController();
  final bebe = TextEditingController();
  final tema = TextEditingController();
  final descricao = TextEditingController();
  final custoEstimado = TextEditingController();

  final tipoCerimonia = ''.obs;
  final estiloCasamento = ''.obs;

  final dataFesta = TextEditingController();
  final horaFesta = TextEditingController();
  final cidade = TextEditingController();
  final uf = TextEditingController(text: 'PR');
  final email = TextEditingController();
  final celular = TextEditingController();

  final enderecoController = EnderecoSectionController().obs;
  final padrinhos = <String>[].obs;

  final formKey = GlobalKey<FormState>();
  final nomeEventoPreview = ''.obs;
  final carregando = false.obs;

  bool get isEditando => idEvento.value.isNotEmpty;

  // ===============================
  // 🔹 CARREGAR TIPOS DE EVENTO DO FIRESTORE
  // ===============================
  Future<void> carregarTiposEvento() async {
    try {
      final snapshot = await db.collection('tipo_evento').where('ativo', isEqualTo: true).get();
      tiposEvento.assignAll(
        snapshot.docs.map((d) => TipoEventoModel.fromMap(d.data())).toList(),
      );
    } catch (e) {
      debugPrint('❌ Erro ao carregar tipos de evento: $e');
    }
  }

// ===============================
// 🔹 ATUALIZAR PRÉ-VISUALIZAÇÃO DO EVENTO
// ===============================
  void atualizarPreview() {
    final nomeNoivaStr = _capitalizar(nomeNoiva.text);
    final parceiroStr = _capitalizar(parceiro.text);
    final idadeStr = idade.text;
    final bebeStr = _capitalizar(bebe.text);

    if (tipoEventoModel.value == null) return;
    final nomeTipoEvento = _normalizeTipoEvento(tipoEventoModel.value!.nome.toLowerCase());

    switch (nomeTipoEvento) {
      case 'casamento':
        if (nomeNoivaStr.isNotEmpty && parceiroStr.isNotEmpty) {
          nomeEventoPreview.value = 'Casamento de $nomeNoivaStr & $parceiroStr';
        } else if (nomeNoivaStr.isNotEmpty) {
          nomeEventoPreview.value = 'Casamento de $nomeNoivaStr';
        } else if (parceiroStr.isNotEmpty) {
          nomeEventoPreview.value = 'Casamento de $parceiroStr';
        } else {
          nomeEventoPreview.value = '💍 Casamento';
        }
        break;

      case 'festa infantil':
        if (nomeNoivaStr.isNotEmpty && idadeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Festa de $nomeNoivaStr - $idadeStr anos';
        } else if (nomeNoivaStr.isNotEmpty) {
          nomeEventoPreview.value = 'Festa de $nomeNoivaStr';
        } else {
          nomeEventoPreview.value = '🎈 Festa Infantil';
        }
        break;

      case 'chá de bebê':
        if (bebeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Chá do $bebeStr';
        } else if (nomeNoivaStr.isNotEmpty) {
          nomeEventoPreview.value = 'Chá de bebê de $nomeNoivaStr';
        } else {
          nomeEventoPreview.value = '🍼 Chá de Bebê';
        }
        break;

      case 'aniversário':
        if (nomeNoivaStr.isNotEmpty && idadeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Aniversário de $nomeNoivaStr - $idadeStr anos';
        } else if (nomeNoivaStr.isNotEmpty) {
          nomeEventoPreview.value = 'Aniversário de $nomeNoivaStr';
        } else {
          nomeEventoPreview.value = '🎂 Aniversário';
        }
        break;

      default:
        nomeEventoPreview.value = '🎉 ${_capitalizar(tipoEventoModel.value!.nome)}';
    }
  }

  // ===============================
  // 🔹 PADRINHOS
  // ===============================
  void addPadrinho(String nome) {
    if (nome.trim().isNotEmpty && !padrinhos.contains(nome.trim())) {
      padrinhos.add(nome.trim());
    }
  }

  void removePadrinho(String nome) => padrinhos.remove(nome);

// ===============================
// 🔹 CARREGAR EVENTO EXISTENTE (EDIÇÃO)
// ===============================
  void carregarEvento(EventoModel evento) {
    carregando.value = false;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    idEvento.value = evento.idEvento;
    nomeEvento.text = evento.nomeEvento;
    nomePessoalPrincipal.text = evento.nomePessoalPrincipal ?? '';
    nomeNoiva.text = evento.nomeNoiva ?? evento.nomeAniversariante ?? '';
    parceiro.text = evento.nomeNoivo ?? '';
    tema.text = evento.tema ?? '';
    idade.text = evento.idade?.toString() ?? '';
    bebe.text = evento.nomeBebe ?? '';
    tipoCerimonia.value = evento.tipoCerimonia ?? '';
    estiloCasamento.value = evento.estiloCasamento ?? '';
    dataFesta.text = DateFormat('dd/MM/yyyy', 'pt_BR').format(evento.data);
    horaFesta.text = evento.hora ?? '';
    padrinhos.assignAll(evento.padrinhos ?? []);

    // ✅ Formata custo estimado no padrão BR
    if (evento.custoEstimado != null && evento.custoEstimado! > 0) {
      custoEstimado.text = currencyFormat.format(evento.custoEstimado);
    } else {
      custoEstimado.text = '';
    }

    // ✅ Seleciona tipo de evento, se existir
    tipoEventoModel.value = tiposEvento.firstWhereOrNull(
      (t) => t.idTipoEvento == evento.idTipoEvento,
    );

    // ✅ Preenche endereço (se existir)
    if (evento.cep != null ||
        evento.logradouro != null ||
        evento.bairro != null ||
        evento.numero != null) {
      final end = enderecoController.value;

      end.cepController.text = evento.cep ?? '';
      end.logradouroController.text = evento.logradouro ?? '';
      end.numeroController.text = evento.numero ?? '';
      end.complementoController.text = evento.complemento ?? '';
      end.bairroController.text = evento.bairro ?? '';
      end.nomeCidadeController.text = evento.nomeCidade ?? '';
      end.ufController.text = evento.uf ?? 'PR';

      // 🔹 Atualiza seleção reativa da cidade/UF no UFCidadeController
      if (evento.uf != null) {
        end.ufCidadeController.estadoSelecionado.value = {
          'nome': evento.uf,
          'uf': evento.uf,
        };
      }

      if (evento.idCidade != null || evento.nomeCidade != null) {
        end.ufCidadeController.cidadeSelecionada.value = {
          'id_cidade': evento.idCidade,
          'nome': evento.nomeCidade ?? '',
          'uf': evento.uf ?? '',
        };
      }
    }

    atualizarPreview();
  }

  Future<void> salvarEvento() async {
    if (!formKey.currentState!.validate()) return;

    final tipoAtual = tipoEventoModel.value;
    final dataStr = dataFesta.text.trim();
    final horaStr = horaFesta.text.trim();

    // ✅ VALIDAÇÕES DE NEGÓCIO
    if (tipoAtual == null) {
      Get.snackbar(
        'Atenção',
        'Selecione o tipo de evento antes de salvar.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (dataStr.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe a data do evento.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (horaStr.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Informe a hora do evento.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // ✅ VALIDAÇÃO DO CUSTO ESTIMADO
    double valor = 0.0;
    if (custoEstimado.text.isNotEmpty) {
      final texto =
          custoEstimado.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim();
      valor = Biblioteca.toDouble(texto);
    }

    if (valor <= 1.0) {
      Get.snackbar(
        'Atenção',
        'O custo estimado deve ser superior a R\$ 1,00.',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = app.usuarioLogado.value;
      if (user == null) throw Exception('Usuário não autenticado.');

      // ✅ Monta data/hora completa
      final dataSelecionada = DateFormat('dd/MM/yyyy', 'pt_BR').parse(dataStr);
      final partesHora = horaStr.split(':');
      final dataCompleta = DateTime(
        dataSelecionada.year,
        dataSelecionada.month,
        dataSelecionada.day,
        int.tryParse(partesHora[0]) ?? 0,
        int.tryParse(partesHora[1]) ?? 0,
      );

      // ✅ Endereço
      final end = enderecoController.value;
      final endereco = end.toModel(user.idUsuario);
      if (!_validarCamposEnderecor(endereco)) return;

      carregando.value = true;

      // ⚙️ Mapeamento da cidade e estado
      final idCidade = end.ufCidadeController.idCidadeSelecionada?.toString();
      final nomeCidade = end.nomeCidadeController.text.trim();
      final uf = end.ufController.text.trim().isNotEmpty
          ? end.ufController.text.trim().toUpperCase()
          : null;

      // ✅ Criação do modelo do evento
      final evento = EventoModel(
        idEvento: idEvento.value.isEmpty ? uuid.v4() : idEvento.value,
        idTipoEvento: tipoAtual.idTipoEvento,
        idUsuario: user.idUsuario,
        nomeEvento: nomeEvento.text.trim().isNotEmpty
            ? nomeEvento.text.trim()
            : nomeEventoPreview.value.trim(),
        nomePessoalPrincipal: nomePessoalPrincipal.text,
        localEvento: localEvento.text.trim(),
        custoEstimado: valor,
        data: dataCompleta,
        hora: horaStr,
        ativo: true,
        status: StatusEvento.planejamento,
        descricao: descricao.text,
        tema: tema.text,
        tipoCerimonia: tipoCerimonia.value,
        estiloCasamento: estiloCasamento.value,
        padrinhos: padrinhos.toList(),
        nomeNoiva: nomeNoiva.text,
        nomeNoivo: parceiro.text,
        nomeResponsavel: user.nome,
        idCidade: idCidade,
        nomeCidade: nomeCidade.isNotEmpty ? nomeCidade : null,
        uf: uf,
        cep: endereco.cep,
        logradouro: endereco.logradouro,
        numero: endereco.numero,
        complemento: endereco.complemento,
        bairro: endereco.bairro,
      );

      // ✅ Gravação no Firestore
      await db.collection('evento').doc(evento.idEvento).set(evento.toMap());

      carregando.value = false;
      Get.back();

      await Future.delayed(const Duration(milliseconds: 350));

      await app.buscarUltimoEvento(user.idUsuario);
      if (idEvento.value.isEmpty) {
        Get.offAllNamed('/splash', arguments: {'novoEvento': true});
      }
    } catch (e) {
      carregando.value = false;
      Get.snackbar(
        'Erro',
        'Falha ao salvar evento: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ===============================
  // 🔹 LIMPAR CAMPOS
  // ===============================
  void limpar({bool manterEndereco = false}) {
    idEvento.value = '';
    nomeEvento.clear();
    nomePessoalPrincipal.clear();
    localEvento.clear();
    nomeNoiva.clear();
    parceiro.clear();
    idade.clear();
    bebe.clear();
    tema.clear();
    tipoCerimonia.value = '';
    estiloCasamento.value = '';
    dataFesta.clear();
    horaFesta.clear();
    cidade.clear();
    uf.text = 'PR';
    email.clear();
    celular.clear();
    padrinhos.clear();
    custoEstimado.clear();
    nomeEventoPreview.value = '';

    // ✅ Só limpa o endereço se não for pedido para manter
    if (!manterEndereco) {
      enderecoController.value.limpar();
    }
  }

  bool _validarCamposEnderecor(EnderecoUsuarioModel endereco) {
    // ------------------------------
    // 🔹 Endereço
    // ------------------------------
    if (endereco.cep.isEmpty) {
      _showError('Informe o CEP');
      return false;
    }
    if (endereco.logradouro.isEmpty) {
      _showError('Informe o endereço completo');
      return false;
    }
    if (endereco.numero.isEmpty) {
      _showError('Informe o número do enredeço');
      return false;
    }
    if (endereco.bairro == null || endereco.bairro!.isEmpty) {
      _showError('Informe o bairro');
      return false;
    }
    if (endereco.uf == null || endereco.uf!.isEmpty) {
      _showError('Informe o estado (UF)');
      return false;
    }
    if (endereco.nomeCidade == null || endereco.nomeCidade!.isEmpty) {
      _showError('Informe a cidade');
      return false;
    }

    return true;
  }

  /// 🔹 Exibe mensagens elegantes de erro
  void _showError(String mensagem) {
    Get.snackbar(
      'Verificação necessária',
      mensagem,
      backgroundColor: Colors.red.shade600.withValues(alpha: 0.95),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  // ===============================
  // 🔹 UTILITÁRIOS INTERNOS
  // ===============================
  String _normalizeTipoEvento(String tipo) {
    return tipo.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
  }

  String _capitalizar(String nome) {
    if (nome.isEmpty) return '';
    return nome
        .split(' ')
        .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }
}
