import 'dart:convert';
import 'dart:io';

/// Arquivo local do observador, com revisão e substituição atômica.
class PilotoAutonomiaStore {
  PilotoAutonomiaStore(String caminho) : arquivo = File(caminho).absolute;
  final File arquivo;
  Map<String, dynamic> ler() =>
      Map<String, dynamic>.from(jsonDecode(arquivo.readAsStringSync()) as Map);
  void salvar(Map<String, dynamic> novo, {required int? revisaoAnterior}) {
    if (novo['revisao'] !=
        (revisaoAnterior == null ? 0 : revisaoAnterior + 1)) {
      throw StateError('Revisão nova incompatível com o arquivo anterior.');
    }
    arquivo.parent.createSync(recursive: true);
    final lock = File('${arquivo.path}.lock').openSync(mode: FileMode.append);
    try {
      lock.lockSync(FileLock.exclusive);
      if (arquivo.existsSync()) {
        if (revisaoAnterior == null || ler()['revisao'] != revisaoAnterior) {
          throw StateError(
              'O arquivo mudou em outro acesso. Reabra o estudo antes de continuar.');
        }
      } else if (revisaoAnterior != null) {
        throw StateError(
            'O estudo foi removido. Nenhuma observação foi substituída.');
      }
      final temporario = File('${arquivo.path}.$pid.tmp');
      temporario.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(novo),
          flush: true);
      temporario.renameSync(arquivo.path);
    } finally {
      lock.closeSync();
    }
  }
}
