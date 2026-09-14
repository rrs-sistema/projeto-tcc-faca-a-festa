part of '../pages/inspiracao_admin_form_page.dart';

extension _InspiracaoAdminFormMidia on _InspiracaoAdminFormPageState {
  Widget _buildImagePanel() {
    return Obx(() {
      final imagemUrl = controller.imagemPrincipalUrlAtual.value.trim();
      final hasCurrentImage = imagemUrl.isNotEmpty;
      final hasSelectedImage =
          controller.imagemPrincipalSelecionadaBytes.value != null;
      final missingImage = !hasCurrentImage && !hasSelectedImage;
      final uploading = controller.uploadImagemPrincipalLoading.value ||
          controller.selecionandoImagem.value;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: missingImage
              ? _warning.withValues(alpha: 0.08)
              : _info.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: missingImage
                ? _warning.withValues(alpha: 0.26)
                : _info.withValues(alpha: 0.16),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final preview = Stack(
              children: [
                _buildImagePreview(),
                if (uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.6, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );

            final actions = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Imagem principal',
                  style: GoogleFonts.poppins(
                    color: _dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A imagem selecionada aparece em preview antes do upload. Ao salvar, ela será enviada para Storage em inspiracoes/{id}/capa.jpg.',
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (hasSelectedImage) ...[
                  const SizedBox(height: 10),
                  _buildInlineWarning(
                    'Imagem pronta para upload. Ela substituirá a capa atual ao salvar.',
                    color: _info,
                    icon: Icons.cloud_upload_outlined,
                  ),
                ],
                if (missingImage) ...[
                  const SizedBox(height: 10),
                  _buildInlineWarning(
                    widget.imagemObrigatoria
                        ? 'Imagem principal obrigatória para salvar.'
                        : 'Imagem principal ainda não informada. Você pode salvar, mas o card ficará menos atrativo.',
                    color: widget.imagemObrigatoria ? _danger : _warning,
                    icon: widget.imagemObrigatoria
                        ? Icons.error_outline_rounded
                        : Icons.info_outline_rounded,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: uploading ? null : _selecionarImagemPrincipal,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: Text(hasCurrentImage || hasSelectedImage
                          ? 'Substituir imagem'
                          : 'Selecionar imagem'),
                    ),
                    if (hasSelectedImage || hasCurrentImage)
                      OutlinedButton.icon(
                        onPressed: uploading ? null : _limparImagemPrincipal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _danger,
                          side: BorderSide(
                              color: _danger.withValues(alpha: 0.28)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Remover'),
                      ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  preview,
                  const SizedBox(height: 12),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 220, child: preview),
                const SizedBox(width: 14),
                Expanded(child: actions),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildImagePreview() {
    final selectedBytes = controller.imagemPrincipalSelecionadaBytes.value;
    final imagemUrl = controller.imagemPrincipalUrlAtual.value.trim();

    Widget child;
    if (selectedBytes != null) {
      child = Image.memory(
        selectedBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imagemUrl.isNotEmpty) {
      child = Image.network(
        imagemUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(
          icon: Icons.broken_image_outlined,
          text: 'Não foi possível carregar a imagem',
        ),
      );
    } else {
      child = _buildImagePlaceholder(
        icon: Icons.image_outlined,
        text: 'Sem imagem',
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: Colors.white,
          child: child,
        ),
      ),
    );
  }

  Widget _buildGaleriaPanel() {
    return Obx(() {
      final urls = controller.galeriaUrlsFormulario.toList();
      final pendentes = controller.imagensGaleriaPendentes.toList();
      final uploading = controller.uploadGaleriaLoading.value ||
          controller.selecionandoImagem.value;
      final total = urls.length + pendentes.length;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _dark.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: _primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Galeria da inspiração',
                        style: GoogleFonts.poppins(
                          color: _dark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        total == 0
                            ? 'Adicione imagens extras para enriquecer a inspiração.'
                            : '$total imagem(ns) vinculada(s) ou pendente(s).',
                        style: GoogleFonts.poppins(
                          color: _muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: uploading ? null : _adicionarImagemGaleria,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined,
                          size: 18),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            if (total == 0) ...[
              const SizedBox(height: 12),
              _buildInlineWarning(
                'Nenhuma imagem extra adicionada. A galeria é opcional.',
                color: _muted,
                icon: Icons.info_outline_rounded,
              ),
            ],
            if (pendentes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pendentes de upload',
                style: GoogleFonts.poppins(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in pendentes) _buildGaleriaPendenteTile(item),
                ],
              ),
            ],
            if (urls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Imagens vinculadas',
                style: GoogleFonts.poppins(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final url in urls) _buildGaleriaUrlTile(url),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildGaleriaPendenteTile(ImagemGaleriaUploadPendente item) {
    return SizedBox(
      width: 128,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.memory(
                item.bytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _buildRemoveImageButton(
              onTap: () =>
                  controller.removerImagemGaleriaPendente(item.localId),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            right: 6,
            child: _buildSmallImageBadge('Pendente'),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriaUrlTile(String url) {
    return SizedBox(
      width: 128,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(
                  icon: Icons.broken_image_outlined,
                  text: 'Erro',
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _buildRemoveImageButton(
              onTap: () => _removerGaleriaUrl(url),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveImageButton({required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildSmallImageBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(
      {required IconData icon, required String text}) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _muted, size: 34),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarImagemPrincipal() async {
    final imagem = await controller.selecionarImagemPrincipal();
    if (imagem == null) return;

    if (mounted) {
      _atualizarTela();
    }
  }

  Future<void> _adicionarImagemGaleria() async {
    final imagem = await controller.adicionarImagemGaleria();
    if (imagem == null) return;

    _sincronizarGaleriaFormulario();
    if (mounted) {
      _atualizarTela();
    }
  }

  Future<void> _removerGaleriaUrl(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    if (_isEdicao) {
      final sucesso = await controller.removerImagemGaleria(
        inspiracaoId: _inspiracaoId,
        imagemUrl: cleanUrl,
        usuarioId: widget.usuarioId,
      );

      if (!sucesso) return;
    } else {
      controller.galeriaUrlsFormulario.remove(cleanUrl);
    }

    final atuais = _parseStringList(_galeriaUrlsController.text)
      ..removeWhere((item) => item.trim() == cleanUrl);
    _galeriaUrlsController.text = atuais.join('\n');
    _sincronizarGaleriaFormulario();

    if (mounted) {
      _atualizarTela();
    }
  }

  void _limparImagemPrincipal() {
    controller.limparImagemPrincipalSelecionada();
    controller.atualizarImagemPrincipalUrlFormulario('');
    _imagemUrlController.clear();

    if (mounted) {
      _atualizarTela();
    }
  }
}
