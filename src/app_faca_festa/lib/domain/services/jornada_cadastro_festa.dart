/// Para onde ir depois de gravar a festa, e o que a estimativa pode mostrar.
///
/// A estimativa do cadastro usa só o número de pessoas. O cardápio ainda não
/// existe, então a calculadora não abre sozinha nem oferece enviá-lo.
class JornadaCadastroFesta {
  const JornadaCadastroFesta._();

  static DestinoCadastroEvento depoisDeSalvar({required bool criando}) {
    return criando
        ? DestinoCadastroEvento.home
        : DestinoCadastroEvento.permanecer;
  }

  /// No primeiro cadastro a pessoa só informa a festa. A calculadora fica
  /// na festa já salva, quando o cardápio pode existir.
  static bool mostraCalculadoraNoFormulario({required bool festaJaSalva}) {
    return festaJaSalva;
  }

  static bool mostraCardapioNaCalculadora({
    required bool estimativaSemEvento,
  }) {
    return !estimativaSemEvento;
  }

  static List<String> passosDaCalculadora({
    required bool estimativaSemEvento,
  }) {
    return estimativaSemEvento
        ? const ['Pessoas', 'A festa', 'Estimativa']
        : const ['Pessoas', 'A festa', 'Sugestões'];
  }
}

enum DestinoCadastroEvento { home, permanecer }
