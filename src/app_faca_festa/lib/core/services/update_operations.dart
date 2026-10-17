/// Process-wide barrier. UI and background writers share the same gate.
abstract final class UpdateOperations {
  static int active = 0;
  static bool sealed = false;

  static Future<T> run<T>(Future<T> Function() operation) async {
    if (sealed) {
      throw StateError('Atualização em preparação. Reabra o aplicativo.');
    }
    active++;
    try {
      return await operation();
    } finally {
      active--;
    }
  }

  static void seal() {
    if (sealed || active != 0) {
      throw StateError('Aguarde as operações e gravações em andamento.');
    }
    sealed = true;
  }
}
