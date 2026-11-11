import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/core/utils/no_sqflite_cache_manager.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/triagem_fornecedor_admin.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_foto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';
import './../../servico/servico_produto_list_screen.dart';
import './territorio_atendimento_screen.dart';
import './editar_fornecedor_cadastro_page.dart';

enum _AcaoFornecedor {
  editar,
  whatsapp,
  servicos,
  territorio,
  aprovar,
  reprovar,
  ativar,
  desativar
}

class FornecedorListTile extends StatelessWidget {
  final Fornecedor fornecedor;
  final FornecedorController controller;
  final FornecedorLocalizacaoController localizacaoController;
  final AdminTerritorioController adminTerritorioController;
  final EventThemeController themeController;
  final AppController appController;
  final CategoriaServicoController categoriaController;
  final SubcategoriaServicoController subcategoriaController;
  final AvaliacaoServicoController avaliacaoController;
  final ServicoProdutoController servicoProdutoController;
  final ServicoFotoController servicoFotoController;
  final bool isCelular;
  final Color primary;
  final TriagemFornecedorAdmin? triagem;
  final bool carregandoTriagem;
  final VoidCallback? aoVoltarDaFicha;

  const FornecedorListTile({
    super.key,
    required this.fornecedor,
    required this.controller,
    required this.localizacaoController,
    required this.adminTerritorioController,
    required this.themeController,
    required this.appController,
    required this.categoriaController,
    required this.subcategoriaController,
    required this.avaliacaoController,
    required this.servicoProdutoController,
    required this.servicoFotoController,
    required this.isCelular,
    required this.primary,
    this.triagem,
    this.carregandoTriagem = false,
    this.aoVoltarDaFicha,
  });

  @override
  Widget build(BuildContext context) {
    final pendencias = TriagemFornecedorAdmin.pendenciasDe(
        fornecedor, controller.servicosDoFornecedor(fornecedor));
    final identidade =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildBanner(),
      const SizedBox(width: 14),
      Expanded(child: _buildInfo()),
    ]);
    final sinais = _buildSinais(pendencias);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 790 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.35) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [identidade, sinais]);
            }
            return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(flex: 6, child: identidade),
                  Expanded(flex: 5, child: sinais),
                ]);
          }),
          const SizedBox(height: 10),
          const Divider(color: AdminPalette.border),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: primary, minimumSize: const Size(44, 44)),
                onPressed: _idDocumento.isEmpty
                    ? null
                    : () async {
                        await Get.toNamed('/admin/fornecedor-desempenho',
                            arguments: _idDocumento);
                        if (context.mounted) aoVoltarDaFicha?.call();
                      },
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Ver desempenho e histórico'),
              ),
              _menuAcoes(context),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildBanner() {
    final url = fornecedor.bannerUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isCelular ? 70 : 100,
        height: isCelular ? 70 : 100,
        color: Colors.grey.shade200, // fundo base
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                cacheManager: AdaptiveCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                errorWidget: (_, __, ___) {
                  debugPrint('❌ Erro ao carregar imagem: $url');
                  return _bannerPlaceholder();
                },
                fadeInDuration: const Duration(milliseconds: 250),
              )
            : _bannerPlaceholder(),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_rounded, color: Colors.white54, size: 32),
      );

  String get _nome => fornecedor.razaoSocial.trim().isEmpty
      ? 'Fornecedor sem nome'
      : fornecedor.razaoSocial.trim();

  Widget _buildInfo() {
    final ativo = fornecedor.ativo;
    final aprovado = fornecedor.aptoParaOperar;
    final cidade = controller.cidadeDoFornecedor(fornecedor);
    final categorias = controller.nomesCategoriasDoFornecedor(fornecedor);
    final descricao = fornecedor.descricao?.trim() ?? '';
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(_nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.ink)),
          _statusChip(
            label: !ativo
                ? 'Desativado'
                : aprovado
                    ? 'Apto para operar'
                    : 'Aguardando aprovação',
            color: !ativo
                ? AdminPalette.danger
                : aprovado
                    ? AdminPalette.success
                    : AdminPalette.warning,
            icon: !ativo
                ? Icons.block_rounded
                : aprovado
                    ? Icons.verified_outlined
                    : Icons.pending_actions_outlined,
          ),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (cidade.isNotEmpty)
              _miniChip(Icons.location_on_outlined, cidade),
            _miniChip(Icons.design_services_outlined,
                '${controller.servicosDoFornecedor(fornecedor)} serviços ativos'),
            _miniChip(Icons.calendar_today_outlined,
                DateFormat('dd/MM/yyyy').format(fornecedor.dataCadastro)),
            for (final categoria in categorias.take(3))
              _miniChip(Icons.category_outlined, categoria),
          ]),
          if (descricao.isNotEmpty)
            Text(descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, color: AdminPalette.muted)),
          if (fornecedor.email.trim().isNotEmpty)
            _infoLine(Icons.email_outlined, fornecedor.email),
          if (fornecedor.telefone.trim().isNotEmpty)
            _infoLine(Icons.phone_outlined, fornecedor.telefone),
        ]);
  }

  Widget _buildSinais(List<String> pendencias) {
    final sinais = triagem;
    final nota =
        fornecedor.mediaAvaliacoes.toStringAsFixed(1).replaceAll('.', ',');
    final total = fornecedor.totalAvaliacoes;
    final casos = sinais?.casosAbertos ?? 0;
    final vencidas = sinais?.cotacoesVencidas ?? 0;
    final data = sinais?.eventoProximoEm;
    final ate = sinais?.restricaoAte;
    final medida = switch (sinais?.medida) {
      'suspender' => 'Suspensão comercial',
      'descredenciar' => 'Descredenciamento comercial',
      _ => 'Restrição comercial',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 7,
            children: [
              const Text('Sinais para análise',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AdminPalette.ink)),
              if (sinais?.comRestricao == true)
                _sinal(
                    Icons.shield_outlined,
                    [
                      medida,
                      sinais?.servicoAfetado ?? 'Fornecedor inteiro',
                      if (ate != null)
                        'até ${DateFormat('dd/MM/yyyy HH:mm').format(ate.toLocal())}'
                      else
                        'prazo indeterminado',
                    ].join(' · '),
                    cor: AdminPalette.danger),
              if (sinais != null) ...[
                if (!sinais.comRestricao)
                  _sinal(
                      Icons.shield_outlined, 'Sem restrição comercial vigente'),
                _sinal(
                    Icons.fact_check_outlined,
                    casos == 0 && !sinais.casosParciais
                        ? 'Nenhum caso aberto'
                        : [
                            casos == 1
                                ? '1 caso aberto'
                                : '$casos casos abertos',
                            if (sinais.casosCriticos > 0)
                              '${sinais.casosCriticos} ${sinais.casosCriticos == 1 ? 'crítico' : 'críticos'}',
                            if (sinais.semResponsavel > 0)
                              '${sinais.semResponsavel} sem responsável',
                            if (sinais.casosParciais) 'cobertura parcial',
                          ].join(' · '),
                    cor: sinais.casosCriticos > 0
                        ? AdminPalette.danger
                        : casos > 0
                            ? AdminPalette.warning
                            : AdminPalette.muted),
                if (sinais.casoPrioritarioAtribuido)
                  _sinal(
                      Icons.person_outline,
                      sinais.responsavel == null
                          ? 'Responsável do caso prioritário atribuído'
                          : 'Caso prioritário com ${sinais.responsavel}'),
                if (data != null)
                  _sinal(Icons.event_outlined,
                      'Evento afetado em ${DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal())}',
                      cor: AdminPalette.warning),
                _sinal(
                    Icons.schedule_outlined,
                    vencidas == 0 && !sinais.cotacoesParciais
                        ? 'Nenhuma cotação vencida'
                        : [
                            vencidas == 1
                                ? '1 cotação vencida aguardando fornecedor'
                                : '$vencidas cotações vencidas aguardando fornecedor',
                            if (sinais.cotacoesParciais) 'cobertura parcial',
                          ].join(' · '),
                    cor: vencidas > 0
                        ? AdminPalette.warning
                        : AdminPalette.muted),
              ] else
                _sinal(
                    Icons.sync_rounded,
                    carregandoTriagem
                        ? 'Carregando casos, restrições e cotações…'
                        : 'Dados operacionais indisponíveis'),
              _sinal(
                  Icons.star_outline_rounded,
                  total > 0
                      ? '$nota/5 · $total ${total == 1 ? 'avaliação verificada' : 'avaliações verificadas'}'
                      : 'Sem avaliações verificadas'),
              if (pendencias.isNotEmpty)
                _sinal(Icons.info_outline, pendencias.join(' · '),
                    cor: AdminPalette.warning),
            ]),
      ),
    );
  }

  Widget _sinal(IconData icone, String texto,
          {Color cor = AdminPalette.muted}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
        Icon(icone, size: 16, color: cor),
        Expanded(
            child: Text(texto,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: cor,
                  fontWeight: cor == AdminPalette.muted
                      ? FontWeight.w500
                      : FontWeight.w600,
                ))),
      ]);

  Widget _menuAcoes(BuildContext context) => Obx(() {
        final podeEditar = controller.podeEditarDadosFornecedor;
        return PopupMenuButton<_AcaoFornecedor>(
          tooltip: 'Mais ações',
          onSelected: (acao) => _executarAcao(context, acao),
          itemBuilder: (_) => [
            if (podeEditar)
              _itemMenu(
                  _AcaoFornecedor.editar, 'Editar dados', Icons.edit_outlined),
            if (fornecedor.telefone
                .replaceAll(RegExp(r'[^0-9]'), '')
                .isNotEmpty)
              _itemMenu(_AcaoFornecedor.whatsapp, 'WhatsApp',
                  FontAwesomeIcons.whatsapp),
            _itemMenu(_AcaoFornecedor.servicos, 'Serviços',
                Icons.design_services_outlined),
            _itemMenu(
                _AcaoFornecedor.territorio, 'Território', Icons.map_outlined),
            const PopupMenuDivider(),
            if (fornecedor.ativo && !fornecedor.aptoParaOperar)
              _itemMenu(_AcaoFornecedor.aprovar, 'Aprovar para operar',
                  Icons.verified_outlined),
            if (fornecedor.aptoParaOperar)
              _itemMenu(
                  _AcaoFornecedor.reprovar, 'Reprovar', Icons.cancel_outlined),
            _itemMenu(
                fornecedor.ativo
                    ? _AcaoFornecedor.desativar
                    : _AcaoFornecedor.ativar,
                fornecedor.ativo ? 'Desativar' : 'Ativar',
                fornecedor.ativo
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
              Icon(Icons.more_horiz_rounded,
                  size: 20, color: AdminPalette.primary),
              Text('Mais ações',
                  style: TextStyle(
                      color: AdminPalette.primary,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      });

  PopupMenuItem<_AcaoFornecedor> _itemMenu(
          _AcaoFornecedor acao, String texto, IconData icone) =>
      PopupMenuItem(
          value: acao,
          child: Row(spacing: 10, children: [
            Icon(icone, size: 18, color: primary),
            Expanded(child: Text(texto)),
          ]));

  Future<void> _executarAcao(BuildContext context, _AcaoFornecedor acao) async {
    switch (acao) {
      case _AcaoFornecedor.editar:
        if (!controller.podeEditarDadosFornecedor) return;
        final salvo = await mostrarEditarFornecedorAdmin(
          context: context,
          idFornecedor: _idDocumento,
          controller: controller,
          categorias: categoriaController,
          subcategorias: subcategoriaController,
          servicos: servicoProdutoController,
        );
        if (salvo == true &&
            context.mounted &&
            controller.podeEditarDadosFornecedor) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados do fornecedor atualizados.')),
          );
        }
      case _AcaoFornecedor.whatsapp:
        final telefone = fornecedor.telefone.replaceAll(RegExp(r'[^0-9]'), '');
        final uri = Uri.https('wa.me', '/55$telefone', {
          'text':
              'Olá, $_nome! Sou administrador do Faça a Festa e gostaria de conversar sobre seus serviços.',
        });
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar(
              'WhatsApp indisponível', 'Não foi possível abrir o WhatsApp.');
        }
      case _AcaoFornecedor.servicos:
        await servicoProdutoController.toggleListenerFornecedor(
            idFornecedor: _idDocumento);
        if (!context.mounted) return;
        await Get.to(() => ServicoProdutoListScreen(
              fornecedorId: _idDocumento,
              servicoController: servicoProdutoController,
              fotoController: servicoFotoController,
              fornecedorController: controller,
              appController: appController,
              categoriaController: categoriaController,
              subcategoriaController: subcategoriaController,
              avaliacaoController: avaliacaoController,
              theme: themeController,
            ));
      case _AcaoFornecedor.territorio:
        final territorio = localizacaoController.territoriosFornecedores
            .firstWhereOrNull((t) => t.idFornecedor == _idDocumento);
        await showAddTerritorioBottomSheet(context, _idDocumento,
            theme: themeController,
            controller: adminTerritorioController,
            existente: territorio);
      case _AcaoFornecedor.aprovar:
        await _confirmarAprovar(context);
      case _AcaoFornecedor.reprovar:
        await _confirmarReprovar(context);
      case _AcaoFornecedor.desativar:
        await _confirmarAtividade(context, false);
      case _AcaoFornecedor.ativar:
        await _confirmarAtividade(context, true);
    }
  }

  Future<void> _confirmarAtividade(BuildContext context, bool ativar) {
    final acao = ativar ? 'Ativar' : 'Desativar';
    return Biblioteca.showConfirmDialog(
      context,
      title: '$acao fornecedor',
      message: 'Deseja ${acao.toLowerCase()} $_nome?',
      confirmLabel: acao,
      color: ativar ? AdminPalette.success : AdminPalette.danger,
      onConfirm: () async {
        if (ativar) {
          await controller.ativarFornecedor(_idDocumento);
        } else {
          await controller.desativarFornecedor(_idDocumento);
        }
        Get.snackbar('Fornecedor ${ativar ? 'ativado' : 'desativado'}',
            'Situação cadastral atualizada.',
            backgroundColor:
                ativar ? AdminPalette.success : AdminPalette.danger,
            colorText: Colors.white);
        return true;
      },
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: primary),
          const SizedBox(width: 4),
          Flexible(
              child: Text(
            text,
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          )),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Flexible(
              child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _confirmarAprovar(BuildContext context) {
    return Biblioteca.showConfirmDialog(
      context,
      title: 'Aprovar fornecedor',
      message:
          'Deseja aprovar ${fornecedor.razaoSocial} para operar? O próximo acesso do fornecedor abrirá a home operacional.',
      confirmLabel: 'Aprovar',
      color: Colors.green.shade700,
      onConfirm: () async {
        final ok = await controller.aprovarFornecedor(_idDocumento);
        if (ok) {
          Get.snackbar(
            'Fornecedor aprovado',
            '${fornecedor.razaoSocial} já pode operar no próximo login.',
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Não foi possível aprovar',
            'Tente novamente em instantes.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
        return ok;
      },
    );
  }

  Future<void> _confirmarReprovar(BuildContext context) {
    return Biblioteca.showConfirmDialog(
      context,
      title: 'Reprovar fornecedor',
      message:
          'Remover a aprovação de ${fornecedor.razaoSocial}? O fornecedor deixará de acessar a home operacional.',
      confirmLabel: 'Reprovar',
      color: Colors.deepOrange,
      onConfirm: () async {
        final ok = await controller.reprovarFornecedor(_idDocumento);
        if (ok) {
          Get.snackbar(
            'Aprovação removida',
            '${fornecedor.razaoSocial} ficou em análise e não opera até nova aprovação.',
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Não foi possível reprovar',
            'Tente novamente em instantes.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
        return ok;
      },
    );
  }

  String get _idDocumento => TriagemFornecedorAdmin.idDe(fornecedor);
}
