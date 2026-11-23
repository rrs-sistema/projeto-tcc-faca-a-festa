import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/data/services/co_organizador/co_organizador_service.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/co_organizador_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Gestão de co-organizadores — equipe clara + convite pela lista do evento.
class CoOrganizadoresPage extends StatefulWidget {
  const CoOrganizadoresPage({super.key, required this.idEvento});

  final String idEvento;

  @override
  State<CoOrganizadoresPage> createState() => _CoOrganizadoresPageState();
}

class _CoOrganizadoresPageState extends State<CoOrganizadoresPage> {
  late final CoOrganizadorController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(
      CoOrganizadorController(idEvento: widget.idEvento),
      tag: widget.idEvento,
    );
  }

  @override
  void dispose() {
    Get.delete<CoOrganizadorController>(tag: widget.idEvento);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final evento = Get.isRegistered<EventoController>()
        ? Get.find<EventoController>().eventoAtual.value
        : null;
    final nomeEvento = (evento?.nomeEvento.trim().isNotEmpty ?? false)
        ? evento!.nomeEvento
        : 'seu evento';

    return Obx(() {
      final primary = theme.primaryColor.value;
      // Garante rebuild quando a lista de convidados ou a busca mudam.
      c.buscaConvidado.value;
      c.mostrarFormularioEmail.value;
      c.convidadosDisponiveis.length;
      c.carregandoConvidados;

      return Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: FestaAppBar(
          titulo: 'Organizar juntos',
          themeController: theme,
        ),
        body: RefreshIndicator(
          color: primary,
          onRefresh: c.carregar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (c.carregando.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (c.erro.value != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EstadoErro(
                    mensagem: c.erro.value!,
                    onRetry: c.carregar,
                    primary: primary,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _IntroCompacta(
                      primary: primary,
                      nomeEvento: nomeEvento,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SecaoTitulo(
                      titulo: 'Equipe',
                      detalhe:
                          '${c.resumo.value?.membros.length ?? 0} ${(c.resumo.value?.membros.length ?? 0) == 1 ? 'pessoa' : 'pessoas'}',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final membro = c.resumo.value!.membros[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MembroTile(
                            membro: membro,
                            primary: primary,
                            podeRemover:
                                c.resumo.value!.souDono && !membro.ehDono,
                            removendo: c.enviando.value,
                            onRemover: () => c.remover(membro),
                          ),
                        );
                      },
                      childCount: c.resumo.value?.membros.length ?? 0,
                    ),
                  ),
                ),
                if ((c.resumo.value?.convitesPendentes.isNotEmpty ?? false))
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ConvitesPendentes(
                        convites: c.resumo.value!.convitesPendentes,
                        primary: primary,
                      ),
                    ),
                  ),
                if (c.resumo.value?.souDono == true) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SecaoTitulo(
                        titulo: 'Convidar',
                        detalhe: c.resumo.value != null
                            ? '${c.resumo.value!.totalCoOrganizadores}/${c.resumo.value!.maxCoOrganizadores} vagas'
                            : null,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: _PainelConvite(
                        controller: c,
                        primary: primary,
                      ),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _IntroCompacta extends StatelessWidget {
  const _IntroCompacta({
    required this.primary,
    required this.nomeEvento,
  });

  final Color primary;
  final String nomeEvento;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.groups_2_rounded, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planejem $nomeEvento juntos',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Co-organizadores cotam, contratam e liberam pagamentos. '
                  'Só o criador remove alguém ou exclui o evento.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.45,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  const _SecaoTitulo({
    required this.titulo,
    this.detalhe,
  });

  final String titulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
        ),
        if ((detalhe ?? '').isNotEmpty)
          Text(
            detalhe!,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF78716C),
            ),
          ),
      ],
    );
  }
}

class _MembroTile extends StatelessWidget {
  const _MembroTile({
    required this.membro,
    required this.primary,
    required this.podeRemover,
    required this.removendo,
    required this.onRemover,
  });

  final MembroOrganizacao membro;
  final Color primary;
  final bool podeRemover;
  final bool removendo;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    final nome = membro.nome.trim();
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: primary.withValues(alpha: 0.14),
            child: Text(
              inicial,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: primary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membro.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF1C1917),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  membro.email.isEmpty ? 'Sem e-mail' : membro.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: membro.ehDono
                  ? primary.withValues(alpha: 0.14)
                  : const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              membro.ehDono ? 'Dono' : 'Equipe',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: membro.ehDono ? primary : const Color(0xFF57534E),
              ),
            ),
          ),
          if (podeRemover)
            IconButton(
              tooltip: 'Remover',
              onPressed: removendo ? null : onRemover,
              icon: Icon(
                Icons.person_remove_outlined,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConvitesPendentes extends StatelessWidget {
  const _ConvitesPendentes({
    required this.convites,
    required this.primary,
  });

  final List<ConviteCoOrganizadorPendente> convites;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(
            'Aguardando aceite',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF57534E),
            ),
          ),
        ),
        for (final convite in convites)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convite.nome.trim().isNotEmpty
                            ? convite.nome
                            : convite.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: const Color(0xFF1C1917),
                        ),
                      ),
                      Text(
                        convite.nome.trim().isNotEmpty
                            ? convite.email
                            : 'Convite enviado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF78716C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PainelConvite extends StatelessWidget {
  const _PainelConvite({
    required this.controller,
    required this.primary,
  });

  final CoOrganizadorController controller;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final resumo = controller.resumo.value;
    final lotado = resumo != null &&
        resumo.totalCoOrganizadores >= resumo.maxCoOrganizadores;
    final disponiveis = controller.convidadosDisponiveis;
    final semEmail = controller.convidadosSemEmail;
    final buscando = controller.buscaConvidado.value.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Da lista do evento',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lotado
                ? 'Limite de ${resumo.maxCoOrganizadores} co-organizadores atingido.'
                : 'Busque alguém já cadastrado e envie o convite em um toque.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.4,
              color: const Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller.buscaCtrl,
            enabled: !lotado && !controller.enviando.value,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou e-mail',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFFA8A29E),
              ),
              prefixIcon: Icon(Icons.search_rounded, color: primary),
              suffixIcon: buscando
                  ? IconButton(
                      tooltip: 'Limpar',
                      onPressed: () {
                        controller.buscaCtrl.clear();
                        controller.buscaConvidado.value = '';
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFAFAF9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (lotado)
            const SizedBox.shrink()
          else if (controller.carregandoConvidados)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (disponiveis.isEmpty && semEmail.isEmpty)
            _ListaVaziaConvite(
              primary: primary,
              buscando: buscando,
              temConvidadosComEmail: controller.totalConvidadosComEmail > 0,
            )
          else ...[
            for (final convidado in disponiveis.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ConvidadoConviteTile(
                  convidado: convidado,
                  primary: primary,
                  bloqueado: controller.enviando.value,
                  processando: controller.enviando.value &&
                      controller.emailEmEnvio.value ==
                          convidado.emailNormalizadoEfetivo,
                  onConvidar: () => controller.convidarDaLista(convidado),
                ),
              ),
            if (disponiveis.length > 8)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Mostrando 8 de ${disponiveis.length}. Refine a busca.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF78716C),
                  ),
                ),
              ),
            if (buscando && semEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final convidado in semEmail.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ConvidadoSemEmailTile(convidado: convidado),
                ),
            ],
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE7E5E4)),
          const SizedBox(height: 8),
          if (!controller.mostrarFormularioEmail.value)
            TextButton(
              onPressed: lotado
                  ? null
                  : () => controller.mostrarFormularioEmail.value = true,
              child: Text(
                'Não está na lista? Convidar por e-mail',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            )
          else
            _FormEmailManual(
              controller: controller,
              primary: primary,
              lotado: lotado,
            ),
        ],
      ),
    );
  }
}

class _ListaVaziaConvite extends StatelessWidget {
  const _ListaVaziaConvite({
    required this.primary,
    required this.buscando,
    required this.temConvidadosComEmail,
  });

  final Color primary;
  final bool buscando;
  final bool temConvidadosComEmail;

  @override
  Widget build(BuildContext context) {
    final titulo = buscando
        ? 'Ninguém encontrado'
        : temConvidadosComEmail
            ? 'Todos os convidados com e-mail já estão na equipe'
            : 'Nenhum convidado com e-mail ainda';
    final detalhe = buscando
        ? 'Tente outro nome ou use o convite por e-mail.'
        : temConvidadosComEmail
            ? 'Você ainda pode convidar alguém de fora por e-mail.'
            : 'Cadastre o e-mail na lista de convidados ou convide abaixo.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded,
              color: primary.withValues(alpha: 0.7), size: 28),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: const Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detalhe,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.4,
              color: const Color(0xFF78716C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvidadoConviteTile extends StatelessWidget {
  const _ConvidadoConviteTile({
    required this.convidado,
    required this.primary,
    required this.bloqueado,
    required this.processando,
    required this.onConvidar,
  });

  final Convidado convidado;
  final Color primary;
  final bool bloqueado;
  final bool processando;
  final VoidCallback onConvidar;

  @override
  Widget build(BuildContext context) {
    final nome = convidado.nome.trim();
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    final email = convidado.emailNormalizadoEfetivo;

    return Material(
      color: processando
          ? primary.withValues(alpha: 0.06)
          : const Color(0xFFFAFAF9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: bloqueado ? null : onConvidar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: processando
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    : Text(
                        inicial,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: primary,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome.isEmpty ? 'Convidado' : nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: const Color(0xFF1C1917),
                      ),
                    ),
                    Text(
                      processando ? 'Enviando convite...' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: processando
                            ? primary
                            : const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: bloqueado ? null : onConvidar,
                child: Text(
                  processando ? 'Enviando' : 'Convidar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: bloqueado && !processando
                        ? const Color(0xFFA8A29E)
                        : primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConvidadoSemEmailTile extends StatelessWidget {
  const _ConvidadoSemEmailTile({required this.convidado});

  final Convidado convidado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded,
              size: 18, color: Color(0xFFA8A29E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${convidado.nome} — sem e-mail cadastrado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF78716C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormEmailManual extends StatelessWidget {
  const _FormEmailManual({
    required this.controller,
    required this.primary,
    required this.lotado,
  });

  final CoOrganizadorController controller;
  final Color primary;
  final bool lotado;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Convidar por e-mail',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1917),
                ),
              ),
            ),
            TextButton(
              onPressed: () => controller.mostrarFormularioEmail.value = false,
              child: const Text('Fechar'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'A pessoa precisa ter (ou criar) uma conta de organizador com este e-mail.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            height: 1.4,
            color: const Color(0xFF78716C),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.nomeCtrl,
          enabled: !lotado && !controller.enviando.value,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nome (opcional)',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller.emailCtrl,
          enabled: !lotado && !controller.enviando.value,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!lotado) controller.convidar();
          },
          decoration: InputDecoration(
            labelText: 'E-mail',
            hintText: 'ex.: parceiro@email.com',
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: lotado || controller.enviando.value
              ? null
              : () => controller.convidar(),
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.enviando.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Enviar convite',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({
    required this.mensagem,
    required this.onRetry,
    required this.primary,
  });

  final String mensagem;
  final VoidCallback onRetry;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 42, color: primary),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
