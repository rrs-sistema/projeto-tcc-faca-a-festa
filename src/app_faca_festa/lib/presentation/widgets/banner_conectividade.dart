import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';

/// Faixa no topo do app: sem internet, sincronizando ou alteração recusada.
///
/// Sem [ConectividadeService] registrado, só devolve [child].
class BannerConectividade extends StatefulWidget {
  const BannerConectividade({super.key, required this.child});

  final Widget child;

  @override
  State<BannerConectividade> createState() => _BannerConectividadeState();
}

class _BannerConectividadeState extends State<BannerConectividade> {
  final _conteudo = GlobalKey(debugLabel: 'conteudo_app');
  StreamSubscription<bool>? _transicoes;
  Timer? _ocultarReconexao;
  bool _mostrarReconexao = false;

  @override
  void initState() {
    super.initState();
    _transicoes = ConectividadeService.instancia?.transicoes.listen((online) {
      if (!mounted) return;
      _ocultarReconexao?.cancel();
      setState(() => _mostrarReconexao = online);
      if (online) {
        _ocultarReconexao = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _mostrarReconexao = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _ocultarReconexao?.cancel();
    unawaited(_transicoes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conectividade = ConectividadeService.instancia;
    if (conectividade == null) return widget.child;
    final estado = EstadoSincronizacao.instancia;

    return Obx(() {
      final offline = conectividade.offline;
      final pendentes = estado?.pendentes.value ?? 0;
      final anteriores = estado?.pendenciasAnteriores.value ?? false;
      final recusa = estado?.ultimaRecusa.value;

      final faixa = _faixa(
        offline: offline,
        pendentes: pendentes,
        anteriores: anteriores,
        recusa: recusa,
        estado: estado,
      );

      // Mesma árvore com ou sem faixa: trocar a estrutura recriaria o
      // Navigator e o usuário perderia a tela em que estava.
      final media = MediaQuery.of(context);
      return Column(
        children: [
          if (faixa != null)
            Material(
              color: faixa.cor,
              child: Padding(
                padding: EdgeInsets.only(top: media.padding.top),
                child: faixa,
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: faixa != null,
              child: KeyedSubtree(key: _conteudo, child: widget.child),
            ),
          ),
        ],
      );
    });
  }

  _Faixa? _faixa({
    required bool offline,
    required int pendentes,
    required bool anteriores,
    required String? recusa,
    required EstadoSincronizacao? estado,
  }) {
    if (recusa != null) {
      return _Faixa(
        key: const Key('banner_recusa'),
        cor: const Color(0xFFB71C1C),
        icone: Icons.error_outline_rounded,
        titulo: 'Uma alteração não foi aceita',
        texto: recusa,
        aoFechar: estado?.limparRecusa,
      );
    }
    final aguardando = pendentes > 0 || anteriores;
    if (offline) {
      return _Faixa(
        key: const Key('banner_offline'),
        cor: const Color(0xFF263238),
        corIcone: const Color(0xFFFFC107),
        icone: Icons.cloud_off_rounded,
        titulo: 'Você está offline',
        texto: 'Pode continuar usando. O que você fizer fica salvo neste '
            'aparelho e é enviado quando a internet voltar.',
        selo: pendentes > 0
            ? '$pendentes a enviar'
            : anteriores
                ? 'Envio pendente'
                : null,
      );
    }
    if (aguardando) {
      return _Faixa(
        key: const Key('banner_sincronizando'),
        cor: const Color(0xFF00695C),
        icone: Icons.sync_rounded,
        titulo: 'Internet de volta',
        texto: 'Enviando o que você fez sem internet...',
        selo: pendentes > 0 ? '$pendentes a enviar' : null,
        carregando: true,
      );
    }
    if (_mostrarReconexao) {
      return const _Faixa(
        key: Key('banner_reconectado'),
        cor: Color(0xFF2E7D32),
        icone: Icons.cloud_done_rounded,
        titulo: 'Você está online',
        texto: 'Tudo o que foi feito sem internet já foi enviado.',
      );
    }
    return null;
  }
}

class _Faixa extends StatelessWidget {
  const _Faixa({
    super.key,
    required this.cor,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.corIcone = Colors.white,
    this.selo,
    this.carregando = false,
    this.aoFechar,
  });

  final Color cor;
  final Color corIcone;
  final IconData icone;
  final String titulo;
  final String texto;
  final String? selo;
  final bool carregando;
  final VoidCallback? aoFechar;

  @override
  Widget build(BuildContext context) {
    final selo = this.selo;
    return Semantics(
      liveRegion: true,
      container: true,
      label: [titulo, texto, if (selo != null) selo].join('. '),
      excludeSemantics: aoFechar == null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, aoFechar == null ? 12 : 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: carregando
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icone, color: corIcone, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (selo != null)
                        Container(
                          key: const Key('banner_selo'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: corIcone == Colors.white
                                ? Colors.white.withValues(alpha: 0.2)
                                : corIcone,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            selo,
                            style: TextStyle(
                              color: corIcone == Colors.white
                                  ? Colors.white
                                  : const Color(0xFF263238),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    texto,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Sem tooltip: a faixa fica acima do Navigator, onde não há Overlay.
            if (aoFechar != null)
              Semantics(
                button: true,
                label: 'Fechar aviso',
                child: IconButton(
                  key: const Key('banner_fechar'),
                  visualDensity: VisualDensity.compact,
                  onPressed: aoFechar,
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
