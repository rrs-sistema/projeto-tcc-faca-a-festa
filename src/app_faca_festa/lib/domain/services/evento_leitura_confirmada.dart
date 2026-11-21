/// Evento ainda na fila local do Firestore, antes do commit no servidor.
class EventoEmTransito<T> {
  const EventoEmTransito({
    required this.valor,
    required this.escritaPendente,
  });

  final T valor;
  final bool escritaPendente;
}

/// Resultado de uma consulta de eventos para abrir a sessão do organizador.
///
/// [eventos] nulo significa que a consulta foi omitida: a escuta anterior
/// permanece. Uma lista vazia é uma consulta confirmada sem eventos.
class PublicacaoListaEventos<T> {
  const PublicacaoListaEventos.omitida() : eventos = null;

  const PublicacaoListaEventos.lista(this.eventos);

  final List<T>? eventos;

  bool get omitida => eventos == null;
}

/// Consulta bruta, com a marca de escrita pendente do snapshot e de cada doc.
class ConsultaEventos<T> {
  const ConsultaEventos({
    required this.escritaPendente,
    required this.documentos,
  });

  final bool escritaPendente;
  final List<EventoEmTransito<T>> documentos;
}

/// Decide quais eventos já podem abrir orçamento, convidados e tarefas.
///
/// Essas listas passam por `eventoDono`, que lê `evento/{id}` no servidor.
/// Publicar um documento que existe só no cache faz a consulta voltar
/// `permission-denied` e a escuta não se recupera.
class EventoLeituraConfirmada {
  const EventoLeituraConfirmada._();

  static bool podePublicar({required bool escritaPendente}) => !escritaPendente;

  static PublicacaoListaEventos<T> daConsulta<T>({
    required bool escritaPendente,
    required List<EventoEmTransito<T>> documentos,
  }) {
    final pendente =
        escritaPendente || documentos.any((item) => item.escritaPendente);
    if (!podePublicar(escritaPendente: pendente)) {
      return PublicacaoListaEventos<T>.omitida();
    }
    return PublicacaoListaEventos<T>.lista(
      [for (final item in documentos) item.valor],
    );
  }

  static PublicacaoListaEventos<T> daConsultaEventos<T>(
    ConsultaEventos<T> consulta,
  ) {
    return daConsulta(
      escritaPendente: consulta.escritaPendente,
      documentos: consulta.documentos,
    );
  }

  /// Omite o snapshot inteiro enquanto houver escrita pendente.
  static Stream<List<T>> listasConfirmadas<T>(
    Stream<ConsultaEventos<T>> consultas,
  ) {
    return consultas.expand((consulta) {
      final publicacao = daConsultaEventos(consulta);
      final eventos = publicacao.eventos;
      if (eventos == null) return Iterable<List<T>>.empty();
      return [eventos];
    });
  }

  /// Último evento confirmado.
  ///
  /// Snapshot pendente não emite. Consulta confirmada sem documentos emite
  /// nulo, para a sessão poder ficar vazia.
  static Stream<T?> ultimosConfirmados<T>(
    Stream<ConsultaEventos<T>> consultas,
  ) {
    return consultas.expand((consulta) {
      final publicacao = daConsultaEventos(consulta);
      final eventos = publicacao.eventos;
      if (eventos == null) return Iterable<T?>.empty();
      return <T?>[eventos.isEmpty ? null : eventos.first];
    });
  }
}
