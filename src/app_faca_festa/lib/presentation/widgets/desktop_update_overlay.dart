import 'package:flutter/material.dart';
import '../../core/services/desktop_update_service.dart';
import '../../app/bootstrap/desktop_update_bootstrap.dart';
import '../../core/services/update_operations.dart';

/// Outside the navigator/EasyLoading: notices remain above menus and dialogs.
class DesktopUpdateOverlay extends StatefulWidget {
  const DesktopUpdateOverlay({super.key, required this.child});
  final Widget child;
  @override
  State<DesktopUpdateOverlay> createState() => _DesktopUpdateOverlayState();
}

class _DesktopUpdateOverlayState extends State<DesktopUpdateOverlay> {
  bool panel = false;
  bool confirm = false;
  @override
  void initState() {
    super.initState();
    DesktopUpdateMenuButton.requests.addListener(openPanel);
  }

  void openPanel() {
    setState(() {
      panel = true;
      message = '';
    });
  }

  @override
  void dispose() {
    DesktopUpdateMenuButton.requests.removeListener(openPanel);
    super.dispose();
  }

  String message = '';
  Future<void> install() async {
    setState(() {
      confirm = false;
      message = '';
    });
    try {
      DesktopUpdateBootstrap.assertIdle();
      await DesktopUpdateService.instance
          .startInstall(prepare: DesktopUpdateBootstrap.prepare);
    } catch (e) {
      if (mounted) {
        setState(() {
          message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopUpdateService.supported) return widget.child;
    final service = DesktopUpdateService.instance;
    return ValueListenableBuilder<DesktopUpdateState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        final installing = state.status == DesktopUpdateStatus.installing;
        final aviso = message.isNotEmpty ? message : state.message;
        return Stack(children: [
          Positioned.fill(
              child: AbsorbPointer(
                  absorbing: installing || UpdateOperations.sealed,
                  child: widget.child)),
          if (confirm || installing) ...[
            const Positioned.fill(
                child: ModalBarrier(dismissible: false, color: Colors.black54)),
            Center(
                child: Material(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 440,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: installing
                            ? const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                        'Salvando dados e preparando atualização…')
                                  ])
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('Atualizar e reiniciar?',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(height: 16),
                                const Text(
                                    'Salve os formulários abertos. O aplicativo será fechado para instalar o pacote validado e será reaberto.'),
                                const SizedBox(height: 16),
                                Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    children: [
                                      TextButton(
                                          onPressed: () => setState(() {
                                                confirm = false;
                                              }),
                                          child: const Text('Cancelar')),
                                      FilledButton(
                                          onPressed: install,
                                          child: const Text(
                                              'Atualizar e reiniciar')),
                                    ])
                              ]),
                      ),
                    ))),
          ],
          if (panel && !confirm && !installing) ...[
            Positioned.fill(
                child: ModalBarrier(
                    color: Colors.black54,
                    dismissible: true,
                    onDismiss: () => setState(() => panel = false))),
            Center(
                child: Material(
                    elevation: 8,
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Text('Atualizações do aplicativo',
                                  style: TextStyle(fontSize: 18)),
                              IconButton(
                                  onPressed: () =>
                                      setState(() => panel = false),
                                  icon: const Icon(Icons.close)),
                            ]),
                            if (aviso.isNotEmpty)
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                  child: Text(
                                    aviso,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                      color: Colors.brown.shade800,
                                    ),
                                  ),
                                ),
                              ),
                            Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ValueListenableBuilder<String>(
                                      valueListenable: service.installedVersion,
                                      builder: (_, value, __) => Text(value,
                                          style:
                                              const TextStyle(fontSize: 11))),
                                  TextButton(
                                      onPressed: installing
                                          ? null
                                          : state.status ==
                                                  DesktopUpdateStatus.ready
                                              ? () {
                                                  try {
                                                    DesktopUpdateBootstrap
                                                        .assertIdle();
                                                    setState(() {
                                                      confirm = true;
                                                      message = '';
                                                    });
                                                  } catch (e) {
                                                    setState(() {
                                                      message = e.toString();
                                                    });
                                                  }
                                                }
                                              : () {
                                                  setState(() {
                                                    message = '';
                                                  });
                                                  service.check();
                                                },
                                      child: Text(state.status ==
                                              DesktopUpdateStatus.ready
                                          ? 'Atualizar para ${state.version} e reiniciar'
                                          : state.status ==
                                                  DesktopUpdateStatus.checking
                                              ? 'Verificando…'
                                              : state.status ==
                                                      DesktopUpdateStatus
                                                          .downloading
                                                  ? 'Baixando e validando…'
                                                  : 'Verificar atualizações')),
                                ]),
                          ]),
                    ))),
          ],
        ]);
      },
    );
  }
}

/// Contextual Windows entry point; background checks are independent of login.
class DesktopUpdateMenuButton extends StatelessWidget {
  const DesktopUpdateMenuButton({super.key, this.color});
  final Color? color;
  static final requests = ValueNotifier<int>(0);
  @override
  Widget build(BuildContext context) {
    if (!DesktopUpdateService.supported) return const SizedBox.shrink();
    return ValueListenableBuilder<DesktopUpdateState>(
      valueListenable: DesktopUpdateService.instance.state,
      builder: (_, state, __) => IconButton(
        tooltip: state.status == DesktopUpdateStatus.ready
            ? 'Nova versão disponível — Atualizações do aplicativo'
            : 'Versão e atualizações do aplicativo',
        icon: Icon(
            state.status == DesktopUpdateStatus.ready
                ? Icons.system_update_alt
                : Icons.info_outline,
            color: color),
        onPressed: () => requests.value++,
      ),
    );
  }
}
