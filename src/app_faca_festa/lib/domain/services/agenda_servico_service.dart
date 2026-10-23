import '../entities/ocorrencia_servico.dart';

class AgendaServicoService {
  const AgendaServicoService();
  List<OcorrenciaServico> ler(dynamic valor, {String? evento}) {
    if (valor == null) return const [];
    if (valor is! List || valor.length > 20) {
      throw ArgumentError('Use até 20 ocorrências por evento.');
    }
    final ids = <String>{};
    return valor.map((v) {
      if (v is! Map) throw ArgumentError('Agenda inválida.');
      final o = OcorrenciaServico.fromMap(Map<String, dynamic>.from(v));
      if (!ids.add(o.id) || evento != null && o.evento != evento) {
        throw ArgumentError('Ocorrências repetidas ou de outro evento.');
      }
      return o;
    }).toList();
  }

  Map<String, dynamic>? porCardapio(Map<String, dynamic> op, String cardapio) {
    final itens = ler(op['agenda']);
    for (final o in itens) {
      if (o.cardapio == cardapio) return o.toMap();
    }
    return null;
  }

  Map<String, dynamic> atualizar(Map<String, dynamic> op, OcorrenciaServico o) {
    o.validar();
    final lista = ler(op['agenda'], evento: o.evento);
    final antigos = lista.where((a) => a.id == o.id).toList();
    if (antigos.isNotEmpty &&
        (antigos.single.modelo != o.modelo ||
            antigos.single.cardapio != o.cardapio)) {
      throw StateError(
          'O vínculo da ocorrência é estável. Crie outra ocorrência para trocar o modelo.');
    }
    final nova = [
      for (final a in lista)
        if (a.id != o.id) a.toMap(),
      o.toMap()
    ];
    ler(nova, evento: o.evento);
    return {...op, 'agenda': nova};
  }
}
