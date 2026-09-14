part of 'evento_cadastro_controller.dart';

extension EventoCadastroTipos on EventoCadastroController {
  Future<void> carregarTiposEvento() async {
    try {
      tiposEvento.assignAll(await _repository.listarTiposAtivos());
    } catch (e) {
      debugPrint('❌ Erro ao carregar tipos de evento: $e');
    }
  }

  String get tokenTipoEvento => TemaFestaViewModel.normalizarTipo(
      tipoEventoSelecionado.value?.nome ?? '');

  bool get exibeSeletorTemaFesta {
    final token = tokenTipoEvento;
    return token.contains('aniversario') ||
        token.contains('infantil') ||
        token.contains('formatura') ||
        token.contains('cha') ||
        token.contains('casamento') ||
        token.contains('corporativo');
  }

  bool get temaFestaObrigatorio {
    final token = tokenTipoEvento;
    return token.contains('aniversario') || token.contains('infantil');
  }

  void selecionarTemaFesta(TemaFestaViewModel? tema, {bool outro = false}) {
    if (outro || tema?.slug == TemaFestaViewModel.slugOutro) {
      idTema.value = TemaFestaViewModel.slugOutro;
      temaLivre.value = true;
      dressCode.value = '';
      return;
    }

    temaLivre.value = false;
    if (tema == null) {
      idTema.value = '';
      dressCode.value = '';
      return;
    }

    idTema.value = tema.idTema;
    this.tema.text = tema.nome;
    final dress = (tema.dressCodeSugerido ?? '').trim();
    if (dress.isNotEmpty) {
      dressCode.value = dress;
    }
  }

// ===============================
// 🔹 ATUALIZAR PRÉ-VISUALIZAÇÃO DO EVENTO
// ===============================
  void atualizarPreview() {
    if (tipoEventoSelecionado.value == null) return;
    final nomeTipoEvento =
        _normalizeTipoEvento(tipoEventoSelecionado.value!.nome.toLowerCase());

    switch (nomeTipoEvento) {
      case 'casamento':
        nomeEventoPreview.value = '💍 Casamento\n ${nomeEvento.text}';
        break;
      case 'festa infantil':
        nomeEventoPreview.value = '🎈 Festa Infantil\n ${nomeEvento.text}';
        break;
      case 'chá de bebê':
      case 'ch de beb':
        nomeEventoPreview.value = '🍼 Chá de Bebê\n ${nomeEvento.text}';
        break;
      case 'aniversário':
      case 'aniversrio':
        nomeEventoPreview.value = '🎂 Aniversário\n ${nomeEvento.text}';
        break;
      case 'evento corporativo':
      case 'corporativo':
        nomeEventoPreview.value = '💼 Evento Corporativo\n ${nomeEvento.text}';
        break;
      case 'formatura':
        nomeEventoPreview.value = '🎓 Formatura \n ${nomeEvento.text}';
        break;
      default:
        nomeEventoPreview.value =
            '🎉 ${_capitalizar(tipoEventoSelecionado.value!.nome)}';
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
}
