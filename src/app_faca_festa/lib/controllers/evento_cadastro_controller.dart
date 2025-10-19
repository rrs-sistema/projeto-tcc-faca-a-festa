import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import '../presentation/pages/endereco/endereco_section_controller.dart';
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
  final nome = TextEditingController();
  final parceiro = TextEditingController();
  final idade = TextEditingController();
  final bebe = TextEditingController();
  final tema = TextEditingController();
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
    final nomeStr = _capitalizar(nome.text);
    final parceiroStr = _capitalizar(parceiro.text);
    final idadeStr = idade.text;
    final bebeStr = _capitalizar(bebe.text);

    if (tipoEventoModel.value == null) return;
    final nomeTipoEvento = _normalizeTipoEvento(tipoEventoModel.value!.nome.toLowerCase());

    switch (nomeTipoEvento) {
      case 'casamento':
        if (nomeStr.isNotEmpty && parceiroStr.isNotEmpty) {
          nomeEventoPreview.value = 'Casamento de $nomeStr & $parceiroStr';
        } else if (nomeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Casamento de $nomeStr';
        } else if (parceiroStr.isNotEmpty) {
          nomeEventoPreview.value = 'Casamento de $parceiroStr';
        } else {
          nomeEventoPreview.value = '💍 Casamento';
        }
        break;

      case 'festa infantil':
        if (nomeStr.isNotEmpty && idadeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Festa da $nomeStr - $idadeStr anos';
        } else if (nomeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Festa da $nomeStr';
        } else {
          nomeEventoPreview.value = '🎈 Festa Infantil';
        }
        break;

      case 'chá de bebê':
        if (bebeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Chá do $bebeStr';
        } else if (nomeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Chá de bebê de $nomeStr';
        } else {
          nomeEventoPreview.value = '🍼 Chá de Bebê';
        }
        break;

      case 'aniversário':
        if (nomeStr.isNotEmpty && idadeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Aniversário de $nomeStr - $idadeStr anos';
        } else if (nomeStr.isNotEmpty) {
          nomeEventoPreview.value = 'Aniversário de $nomeStr';
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
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    idEvento.value = evento.idEvento;
    nome.text = evento.nomeNoiva ?? evento.nomeAniversariante ?? '';
    parceiro.text = evento.nomeNoivo ?? '';
    tema.text = evento.tema ?? '';
    idade.text = evento.idade?.toString() ?? '';
    bebe.text = evento.nomeBebe ?? '';
    tipoCerimonia.value = evento.tipoCerimonia ?? '';
    estiloCasamento.value = evento.estiloCasamento ?? '';
    dataFesta.text = DateFormat('dd/MM/yyyy', 'pt_BR').format(evento.data);
    horaFesta.text = evento.hora ?? '';
    padrinhos.assignAll(evento.padrinhos ?? []);

    // ✅ formata custo estimado no padrão BR
    if (evento.custoEstimado != null && evento.custoEstimado! > 0) {
      custoEstimado.text = currencyFormat.format(evento.custoEstimado);
    } else {
      custoEstimado.text = '';
    }

    // ✅ seleciona tipo de evento, se existir
    tipoEventoModel.value = tiposEvento.firstWhereOrNull(
      (t) => t.idTipoEvento == evento.idTipoEvento,
    );

    atualizarPreview();
  }

  // ===============================
  // 🔹 SALVAR EVENTO (NOVO / EDIÇÃO)
  // ===============================
  Future<void> salvarEvento() async {
    if (!formKey.currentState!.validate()) return;
    carregando.value = true;

    try {
      final user = app.usuarioLogado.value;
      if (user == null) throw Exception('Usuário não autenticado.');

      // Data e hora
      final dataSelecionada = dataFesta.text.isNotEmpty
          ? DateFormat('dd/MM/yyyy', 'pt_BR').parse(dataFesta.text)
          : DateTime.now().add(const Duration(days: 30));

      DateTime dataCompleta = dataSelecionada;
      if (horaFesta.text.isNotEmpty) {
        final partes = horaFesta.text.split(':');
        if (partes.length == 2) {
          dataCompleta = DateTime(
            dataSelecionada.year,
            dataSelecionada.month,
            dataSelecionada.day,
            int.tryParse(partes[0]) ?? 0,
            int.tryParse(partes[1]) ?? 0,
          );
        }
      }

      final endereco = enderecoController.value.toModel('');
      final tipoAtual = tipoEventoModel.value;
      if (tipoAtual == null) throw Exception('Tipo de evento não selecionado.');

      // ✅ converte valor formatado (ex: "R$ 1.234,56")
      double? valor = 0.0;
      if (custoEstimado.text.isNotEmpty) {
        final texto = custoEstimado.text
            .replaceAll('R\$', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();
        valor = double.tryParse(texto) ?? 0.0;
      }

      final evento = EventoModel(
        idEvento: idEvento.value.isEmpty ? uuid.v4() : idEvento.value,
        idTipoEvento: tipoAtual.idTipoEvento,
        idUsuario: user.idUsuario,
        nome: nomeEventoPreview.value,
        custoEstimado: valor,
        data: dataCompleta,
        hora: horaFesta.text,
        ativo: true,
        tema: tema.text,
        tipoCerimonia: tipoCerimonia.value,
        estiloCasamento: estiloCasamento.value,
        padrinhos: padrinhos.toList(),
        nomeNoiva: nome.text,
        nomeNoivo: parceiro.text,
        nomeResponsavel: user.nome,
        cep: endereco.cep,
        logradouro: endereco.logradouro,
        numero: endereco.numero,
        complemento: endereco.complemento,
        bairro: endereco.bairro,
      );

      // ✅ salva ou atualiza conforme idEvento
      await db.collection('evento').doc(evento.idEvento).set(evento.toMap());

      app.eventoModel.value = evento;
      carregando.value = false;
      Get.back();

      Get.snackbar(
        'Sucesso',
        isEditando ? 'Evento atualizado com sucesso!' : 'Evento salvo com sucesso!',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
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
  void limpar() {
    idEvento.value = '';
    tipoEventoModel.value = null;
    nome.clear();
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
