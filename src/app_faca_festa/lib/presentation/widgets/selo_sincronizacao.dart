import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';

/// Selo "salvo no aparelho" para um item com escrita ainda sem confirmação.
///
/// Some sozinho quando o servidor confirma. Sem [EstadoSincronizacao]
/// registrado, não ocupa espaço.
class SeloSincronizacao extends StatelessWidget {
  const SeloSincronizacao({super.key, required this.chave, this.compacto = false});

  /// Id do documento passado para `escritaLocalPrimeiro`.
  final String chave;

  /// Só o ícone, para linhas estreitas.
  final bool compacto;

  static const texto = 'Salvo no aparelho, aguardando sincronização';

  @override
  Widget build(BuildContext context) {
    final estado = EstadoSincronizacao.instancia;
    if (estado == null || chave.trim().isEmpty) return const SizedBox.shrink();
    return Obx(() {
      if (!estado.chavesPendentes.contains(chave.trim())) {
        return const SizedBox.shrink();
      }
      const cor = Color(0xFF8D6E00);
      const icone = Icon(Icons.cloud_upload_outlined, size: 14, color: cor);
      if (compacto) {
        return Semantics(
          key: Key('selo_pendente_$chave'),
          label: texto,
          child: const Padding(padding: EdgeInsets.all(2), child: icone),
        );
      }
      return Container(
        key: Key('selo_pendente_$chave'),
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icone,
            SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: cor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
