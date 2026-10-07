part of 'inspiracao_controller.dart';

extension InspiracaoEventoPlanejamento on InspiracaoController {
  Future<void> salvarInspiracaoNoEvento(
    Inspiracao inspiracao, {
    bool favorito = false,
    bool showSuccessMessage = true,
    String status = 'salva',
    String prioridade = 'media',
    String anotacao = '',
  }) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de salvar uma inspiração.');
      return;
    }

    try {
      salvando.value = true;

      if (showSuccessMessage) {
        EasyLoading.show(status: 'Salvando inspiração...');
      }

      final docId = _referenciaDocId(inspiracao.id);

      await _inspiracoes.salvarReferenciaInspiracao(
        eventoId: _eventoIdAtual!,
        userId: _userIdAtual!,
        referenciaId: docId,
        inspiracao: inspiracao,
        favorito: favorito || favoritasIds.contains(inspiracao.id),
        status: status,
        prioridade: prioridade,
        anotacao: anotacao,
      );

      referenciasSalvasIds.add(inspiracao.id);

      if (favorito) {
        favoritasIds.add(inspiracao.id);
      }

      referenciasSalvasIds.refresh();
      favoritasIds.refresh();

      _atualizarFavoritosLocais();
      _aplicarFiltroAtual();

      if (showSuccessMessage) {
        EasyLoading.showSuccess('Inspiração salva no evento ✨');
      }
    } catch (e) {
      EasyLoading.showError('Erro ao salvar inspiração');
      if (kDebugMode) {
        print('❌ Erro ao salvar inspiração no evento: $e');
      }
    } finally {
      salvando.value = false;
      EasyLoading.dismiss();
    }
  }

  Future<void> alternarFavorito(String id) async {
    final index = todasInspiracoes.indexWhere((i) => i.id == id);
    if (index == -1) return;

    if (!_temContextoEvento) {
      EasyLoading.showInfo(
          'Carregue o evento antes de favoritar uma inspiração.');
      return;
    }

    final inspiracao = todasInspiracoes[index];
    final novoFavorito = !favoritasIds.contains(id);

    try {
      final docId = _referenciaDocId(id);
      final existe = await _inspiracoes.referenciaExiste(
        eventoId: _eventoIdAtual!,
        referenciaId: docId,
      );

      if (!existe) {
        await _inspiracoes.salvarReferenciaInspiracao(
          eventoId: _eventoIdAtual!,
          userId: _userIdAtual!,
          referenciaId: docId,
          inspiracao: inspiracao,
          favorito: novoFavorito,
          status: 'salva',
          prioridade: 'media',
          anotacao: '',
        );
        referenciasSalvasIds.add(id);
      } else {
        await _inspiracoes.atualizarFavoritoReferencia(
          eventoId: _eventoIdAtual!,
          referenciaId: docId,
          favorito: novoFavorito,
        );
      }

      if (novoFavorito) {
        favoritasIds.add(id);
      } else {
        favoritasIds.remove(id);
      }

      favoritasIds.refresh();
      referenciasSalvasIds.refresh();

      _atualizarFavoritosLocais();
      _aplicarFiltroAtual();
    } catch (e) {
      EasyLoading.showError('Erro ao favoritar inspiração');
      if (kDebugMode) {
        print('❌ Erro ao favoritar inspiração: $e');
      }
    }
  }

  Future<void> adicionarReferenciaPessoal() async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo(
          'Carregue o evento antes de adicionar uma referência pessoal.');
      return;
    }

    final autorizado = await confirmarDireitoImagem();
    if (!autorizado) return;

    try {
      final picker = ImagePicker();
      final image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (image == null) {
        EasyLoading.showInfo('Nenhuma imagem selecionada');
        return;
      }

      EasyLoading.show(status: 'Enviando imagem...');

      await _inspiracoes.adicionarReferenciaPessoal(
        eventoId: _eventoIdAtual!,
        userId: _userIdAtual!,
        bytes: await image.readAsBytes(),
        nomeArquivo: image.name,
      );

      EasyLoading.showSuccess('Referência adicionada ao evento ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao adicionar referência');
      if (kDebugMode) {
        print('❌ Erro ao adicionar referência pessoal: $e');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  bool inspiracaoJaSalva(String inspiracaoId) {
    if (inspiracaoId.trim().isEmpty) return false;
    return referenciasSalvasIds.contains(inspiracaoId.trim());
  }

  bool checklistJaCriado(String inspiracaoId) {
    return tarefasInspiracaoEvento
        .any((t) => t.pertenceAInspiracao(inspiracaoId));
  }

  bool orcamentoJaCriado(String inspiracaoId) {
    return orcamentosInspiracaoEvento
        .any((item) => item.pertenceAInspiracao(inspiracaoId));
  }

  Future<void> _atualizarIndicadoresReferencia({
    required Inspiracao inspiracao,
    bool? checklistCriado,
    bool? orcamentoCriado,
  }) async {
    if (!_temContextoEvento) return;

    await _inspiracoes.atualizarIndicadoresReferencia(
      eventoId: _eventoIdAtual!,
      referenciaId: _referenciaDocId(inspiracao.id),
      checklistCriado: checklistCriado,
      orcamentoCriado: orcamentoCriado,
    );
  }

  Future<void> gerarChecklistDaInspiracao(Inspiracao inspiracao) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de criar checklist.');
      return;
    }

    try {
      final jaExisteLocal = checklistJaCriado(inspiracao.id);
      final jaExisteRemoto = jaExisteLocal
          ? true
          : await _inspiracoes.existeDocumentoAtivoDaInspiracao(
              eventoId: _eventoIdAtual!,
              subcolecao: GerenciarInspiracoes.subcolecaoTarefas,
              inspiracaoId: inspiracao.id,
            );

      if (jaExisteRemoto) {
        EasyLoading.showInfo(
          'Essa inspiração já gerou um checklist para este evento.',
        );
        return;
      }

      EasyLoading.show(status: 'Criando checklist...');

      final tarefas = inspiracao.tarefasSugeridas.isNotEmpty
          ? inspiracao.tarefasSugeridas
          : [
              TarefaInspiracaoSugerida(
                titulo: 'Separar referência visual: ${inspiracao.titulo}',
                descricao:
                    'Usar esta inspiração como base para conversar com fornecedores e organizar os detalhes do evento.',
                categoria: inspiracao.categoria ?? 'Inspiração',
              ),
              TarefaInspiracaoSugerida(
                titulo:
                    'Solicitar orçamento para ${inspiracao.categoria ?? 'esta ideia'}',
                descricao:
                    'Enviar a referência visual para pelo menos um fornecedor e comparar valores.',
                categoria: inspiracao.categoria ?? 'Inspiração',
              ),
            ];

      await _inspiracoes.criarChecklistDaInspiracao(
        eventoId: _eventoIdAtual!,
        userId: _userIdAtual!,
        inspiracao: inspiracao,
        tarefas: tarefas,
      );

      await salvarInspiracaoNoEvento(inspiracao, showSuccessMessage: false);
      await _atualizarIndicadoresReferencia(
        inspiracao: inspiracao,
        checklistCriado: true,
      );

      EasyLoading.showSuccess('Checklist criado a partir da inspiração ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao criar checklist');
      if (kDebugMode) {
        print('❌ Erro ao criar checklist da inspiração: $e');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> gerarOrcamentoDaInspiracao(Inspiracao inspiracao) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de criar orçamento.');
      return;
    }

    try {
      final jaExisteLocal = orcamentoJaCriado(inspiracao.id);
      final jaExisteRemoto = jaExisteLocal
          ? true
          : await _inspiracoes.existeDocumentoAtivoDaInspiracao(
              eventoId: _eventoIdAtual!,
              subcolecao: GerenciarInspiracoes.subcolecaoOrcamento,
              inspiracaoId: inspiracao.id,
            );

      if (jaExisteRemoto) {
        EasyLoading.showInfo(
          'Essa inspiração já gerou orçamento para este evento.',
        );
        return;
      }

      EasyLoading.show(status: 'Criando orçamento...');

      final itens = inspiracao.itensOrcamentoSugeridos.isNotEmpty
          ? inspiracao.itensOrcamentoSugeridos
          : [
              ItemOrcamentoInspiracaoSugerido(
                categoria: inspiracao.categoria ?? 'Inspiração',
                item: inspiracao.titulo,
              ),
            ];

      await _inspiracoes.criarOrcamentoDaInspiracao(
        eventoId: _eventoIdAtual!,
        userId: _userIdAtual!,
        inspiracao: inspiracao,
        itens: itens,
      );

      await salvarInspiracaoNoEvento(inspiracao, showSuccessMessage: false);
      await _atualizarIndicadoresReferencia(
        inspiracao: inspiracao,
        orcamentoCriado: true,
      );

      EasyLoading.showSuccess('Orçamento criado a partir da inspiração ✨');
    } catch (e) {
      EasyLoading.showError('Erro ao criar orçamento');
      if (kDebugMode) {
        print('❌ Erro ao criar orçamento da inspiração: $e');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> atualizarReferenciaPlanejamento({
    required String referenciaId,
    String? status,
    String? prioridade,
    String? anotacao,
    bool? favorito,
  }) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de editar a referência.');
      return;
    }

    try {
      await _inspiracoes.atualizarReferenciaPlanejamento(
        eventoId: _eventoIdAtual!,
        referenciaId: referenciaId,
        status: status,
        prioridade: prioridade,
        anotacao: anotacao,
        favorito: favorito,
      );
      EasyLoading.showSuccess('Referência atualizada');
    } catch (e) {
      EasyLoading.showError('Erro ao atualizar referência');
      if (kDebugMode) {
        print('❌ Erro ao atualizar referência: $e');
      }
    }
  }

  Future<bool> removerReferenciaDoEvento(
    String referenciaId, {
    bool removerPlanejamentoVinculado = false,
    String motivo = '',
  }) async {
    if (!_temContextoEvento) {
      EasyLoading.showInfo('Carregue o evento antes de remover a referência.');
      return false;
    }

    final id = referenciaId.trim();

    if (id.isEmpty) {
      EasyLoading.showInfo('Referência não identificada.');
      return false;
    }

    try {
      EasyLoading.show(status: 'Removendo referência...');

      final inspiracaoId = await _inspiracoes.buscarInspiracaoIdDaReferencia(
        eventoId: _eventoIdAtual!,
        referenciaId: id,
      );

      if (inspiracaoId == null) {
        EasyLoading.showInfo('Referência não encontrada.');
        return false;
      }

      await _inspiracoes.removerReferenciaDoEvento(
        eventoId: _eventoIdAtual!,
        userId: _userIdAtual!,
        referenciaId: id,
        removerPlanejamentoVinculado: removerPlanejamentoVinculado,
        motivo: motivo,
      );

      referenciasEvento.removeWhere((ref) => ref.id == id);

      if (inspiracaoId.isNotEmpty) {
        final aindaExisteReferenciaAtiva = referenciasEvento.any((ref) {
          return ref.inspiracaoId == inspiracaoId && ref.ativo && !ref.deletado;
        });

        if (!aindaExisteReferenciaAtiva) {
          referenciasSalvasIds.remove(inspiracaoId);
          favoritasIds.remove(inspiracaoId);
        }
      }

      referenciasEvento.refresh();
      referenciasSalvasIds.refresh();
      favoritasIds.refresh();

      _atualizarFavoritosLocais();
      _aplicarFiltroAtual();

      if (removerPlanejamentoVinculado && inspiracaoId.isNotEmpty) {
        tarefasInspiracaoEvento.removeWhere(
          (t) => t.inspiracaoId == inspiracaoId,
        );
        orcamentosInspiracaoEvento.removeWhere(
          (o) => o.inspiracaoId == inspiracaoId,
        );
        tarefasInspiracaoEvento.refresh();
        orcamentosInspiracaoEvento.refresh();
      }

      EasyLoading.showSuccess('Referência removida');
      return true;
    } catch (e) {
      EasyLoading.showError('Erro ao remover referência');
      if (kDebugMode) {
        print('❌ Erro ao remover referência: $e');
      }
      return false;
    } finally {
      EasyLoading.dismiss();
    }
  }

  int totalTarefasPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0;
    return tarefasInspiracaoEvento
        .where((t) => t.inspiracaoId == inspiracaoId)
        .length;
  }

  int tarefasConcluidasPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0;
    return tarefasInspiracaoEvento
        .where((t) => t.inspiracaoId == inspiracaoId && t.concluida)
        .length;
  }

  int totalOrcamentosPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0;
    return orcamentosInspiracaoEvento
        .where((o) => o.inspiracaoId == inspiracaoId)
        .length;
  }

  double valorOrcadoPorInspiracao(String inspiracaoId) {
    if (inspiracaoId.isEmpty) return 0.0;

    return orcamentosInspiracaoEvento
        .where((o) => o.inspiracaoId == inspiracaoId)
        .fold<double>(0.0, (total, o) => total + o.valorOrcado);
  }
}
