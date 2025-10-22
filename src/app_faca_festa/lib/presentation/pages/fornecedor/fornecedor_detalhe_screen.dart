import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/model.dart';
import '../../../data/models/DTO/fornecedor_detalhado_model.dart';
import '../../../controllers/event_theme_controller.dart';
import '../../../controllers/fornecedor_controller.dart';
import './components/abrir_cotacao_bottom_sheet.dart';

class FornecedorDetalheScreen extends StatelessWidget {
  final FornecedorDetalhadoModel fornecedorDetalhado;
  const FornecedorDetalheScreen({super.key, required this.fornecedorDetalhado});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final fornecedorController = Get.find<FornecedorController>();

    fornecedorController.escutarServicosFornecedor(fornecedorDetalhado.fornecedor.idFornecedor);

    final fornecedor = fornecedorDetalhado.fornecedor;
    final territorio = fornecedorDetalhado.territorio;
    final distancia = fornecedorDetalhado.distanciaKm;
    final gradient = themeController.gradient.value;
    final primary = themeController.primaryColor.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(fornecedor.razaoSocial, gradient),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloCategoria(fornecedorDetalhado.categoriaNome, primary),
            const SizedBox(height: 22),
            _divider('Serviço selecionado'),
            const SizedBox(height: 16),
            _buildServicoPrincipal(
                fornecedorDetalhado, fornecedorController, primary, gradient, context),
            const SizedBox(height: 24),
            _divider('Outros serviços oferecidos'),
            const SizedBox(height: 16),
            _buildOutrosServicos(
                fornecedorDetalhado, fornecedorController, primary, gradient, context),
            const SizedBox(height: 28),
            _divider('Informações de contato'),
            const SizedBox(height: 10),
            _InfoTile(Icons.call_outlined, fornecedor.telefone),
            _InfoTile(Icons.email_outlined, fornecedor.email),
            if (territorio?.descricao?.isNotEmpty ?? false)
              _InfoTile(Icons.map_outlined, territorio!.descricao!),
            if (distancia != null)
              _InfoTile(
                  Icons.location_on_outlined, '${distancia.toStringAsFixed(1)} km de distância'),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(String title, Gradient gradient) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: Get.back,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          fontSize: 17,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
    );
  }

  Widget _tituloCategoria(String nome, Color primary) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary.withValues(alpha: 0.8), primary]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            nome,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );

  Widget _divider(String titulo) => Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              titulo,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        ],
      );

  Widget _textoVazio(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style:
              GoogleFonts.poppins(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
      );

  Widget _buildServicoPrincipal(
    FornecedorDetalhadoModel detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    return Obx(() {
      final categorias = controller.categorias;
      final subCategorias = controller.subCategorias;
      final servicosFornecedor = controller.allServicosFornecedor;
      final servicos = controller.catalogoServicos;
      final fotos = controller.fotosServico;

      final categoria = categorias.firstWhereOrNull(
        (c) => c.nome.toLowerCase().contains(detalhe.categoriaNome.toLowerCase()),
      );
      if (categoria == null) return _textoVazio('Nenhum serviço principal encontrado.');

      final subCategoria = subCategorias.firstWhereOrNull((s) => s.idCategoria == categoria.id);
      final servicoFornecedor = servicosFornecedor.firstWhereOrNull((sf) =>
          sf.idFornecedor == detalhe.fornecedor.idFornecedor &&
          sf.idSubcategoria == subCategoria?.id);

      if (servicoFornecedor == null) {
        return _textoVazio('Nenhum serviço vinculado ao fornecedor nesta categoria.');
      }

      final servico = servicos.firstWhereOrNull((s) => s.id == servicoFornecedor.idProdutoServico);
      final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == servico?.id);
      if (servico == null) return _textoVazio('Serviço não encontrado.');

      return ServicoCardPrincipal(
        servico: servico,
        fotoUrl: foto?.url,
        primary: primary,
        gradient: gradient,
        fornecedorId: detalhe.fornecedor.idFornecedor,
        context: context,
      );
    });
  }

  Widget _buildOutrosServicos(
    FornecedorDetalhadoModel detalhe,
    FornecedorController controller,
    Color primary,
    Gradient gradient,
    BuildContext context,
  ) {
    final fornecedor = detalhe.fornecedor;
    return Obx(() {
      final servicosFornecedorAtuais = controller.servicosFornecedor
          .where((sf) => sf.idFornecedor == fornecedor.idFornecedor)
          .toList();

      if (servicosFornecedorAtuais.isEmpty) {
        return _textoVazio('Este fornecedor ainda não cadastrou serviços.');
      }

      final categoriaPrincipal = controller.categorias.firstWhereOrNull(
        (c) => c.nome.toLowerCase().contains(detalhe.categoriaNome.toLowerCase()),
      );
      final subCategoriaPrincipal =
          controller.subCategorias.firstWhereOrNull((s) => s.idCategoria == categoriaPrincipal?.id);
      final vinculoPrincipal = controller.allServicosFornecedor.firstWhereOrNull(
        (sf) =>
            sf.idFornecedor == fornecedor.idFornecedor &&
            sf.idSubcategoria == subCategoriaPrincipal?.id,
      );
      final idServicoPrincipal = vinculoPrincipal?.idProdutoServico;

      final idsSelecionados = servicosFornecedorAtuais
          .map((sf) => sf.idProdutoServico)
          .whereType<String>()
          .where((id) => id != idServicoPrincipal)
          .toList();

      final servicos =
          controller.catalogoServicos.where((s) => idsSelecionados.contains(s.id)).toList();
      final fotos = controller.fotosServico;

      if (servicos.isEmpty) return _textoVazio('Nenhum outro serviço cadastrado.');

      return SizedBox(
        height: 240,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemCount: servicos.length,
          itemBuilder: (_, i) {
            final s = servicos[i];
            final foto = fotos.firstWhereOrNull((f) => f.idProdutoServico == s.id);
            return ServicoCardHorizontal(
              servico: s,
              fotoUrl: foto?.url,
              primary: primary,
              gradient: gradient,
              fornecedorId: fornecedor.idFornecedor,
              context: context,
            );
          },
        ),
      );
    });
  }
}

class ServicoCardPrincipal extends StatelessWidget {
  final ServicoProdutoModel servico;
  final String? fotoUrl;
  final Color primary;
  final Gradient gradient;
  final String fornecedorId;
  final BuildContext context;

  const ServicoCardPrincipal({
    super.key,
    required this.servico,
    required this.fotoUrl,
    required this.primary,
    required this.gradient,
    required this.fornecedorId,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagem(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servico.nome,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(servico.descricao ?? 'Sem descrição disponível.',
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, color: Colors.black87.withValues(alpha: 0.7), height: 1.5)),
                const SizedBox(height: 16),
                _botaoOrcamento('Solicitar orçamento'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagem() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: fotoUrl ?? '',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _botaoOrcamento(String label) => ElevatedButton.icon(
        icon: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 18),
        label: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: primary,
          shadowColor: primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CotacaoBottomSheet(
            fornecedoresSelecionados: [fornecedorId],
            idProdutoSelecionado: servico.id,
            nomeProdutoSelecionado: servico.nome,
            primary: primary,
          ),
        ),
      );
}

class ServicoCardHorizontal extends StatelessWidget {
  final ServicoProdutoModel servico;
  final String? fotoUrl;
  final Color primary;
  final Gradient gradient;
  final String fornecedorId;
  final BuildContext context;

  const ServicoCardHorizontal({
    super.key,
    required this.servico,
    required this.fotoUrl,
    required this.primary,
    required this.gradient,
    required this.fornecedorId,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagem(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servico.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(servico.descricao ?? 'Sem descrição',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: Colors.black87.withValues(alpha: 0.65), fontSize: 12.5)),
                const SizedBox(height: 10),
                _botaoOrcar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagem() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: CachedNetworkImage(
          imageUrl: fotoUrl ?? '',
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => Container(
            height: 100,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
          ),
        ),
      );

  Widget _botaoOrcar() => ElevatedButton.icon(
        icon: const Icon(Icons.request_quote_rounded, size: 16, color: Colors.white),
        label: Text('Orçar',
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CotacaoBottomSheet(
            fornecedoresSelecionados: [fornecedorId],
            idProdutoSelecionado: servico.id,
            nomeProdutoSelecionado: servico.nome,
            primary: primary,
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: Colors.black87.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
