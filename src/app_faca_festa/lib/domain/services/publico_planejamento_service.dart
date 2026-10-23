import '../entities/evento.dart';
import '../entities/convidado.dart';
import '../entities/calculadora_festa.dart';
import '../entities/convidados_equivalentes.dart';

enum CompletudeLista { desconhecida, emPreenchimento, concluida }

extension CompletudeListaTexto on CompletudeLista {
  String get valor => switch (this) {
        CompletudeLista.desconhecida => 'desconhecida',
        CompletudeLista.emPreenchimento => 'em_preenchimento',
        CompletudeLista.concluida => 'concluida',
      };
  String get label => switch (this) {
        CompletudeLista.desconhecida => 'completude não declarada',
        CompletudeLista.emPreenchimento => 'em preenchimento',
        CompletudeLista.concluida => 'concluída',
      };
}

CompletudeLista completudeDaLista(dynamic valor) => switch (valor) {
      'em_preenchimento' => CompletudeLista.emPreenchimento,
      'concluida' => CompletudeLista.concluida,
      _ => CompletudeLista.desconhecida,
    };
String valorBasePublico(BaseCalculoFesta base) => switch (base) {
      BaseCalculoFesta.manual => 'manual',
      BaseCalculoFesta.previstos => 'previstos',
      BaseCalculoFesta.todosConvidados => 'todos',
      BaseCalculoFesta.naoRecusados => 'nao_recusados',
      BaseCalculoFesta.apenasConfirmados => 'confirmados',
    };
BaseCalculoFesta? basePublicoDoValor(dynamic valor) => switch (valor) {
      'manual' => BaseCalculoFesta.manual,
      'previstos' => BaseCalculoFesta.previstos,
      'todos' => BaseCalculoFesta.todosConvidados,
      'nao_recusados' => BaseCalculoFesta.naoRecusados,
      'confirmados' => BaseCalculoFesta.apenasConfirmados,
      _ => null,
    };

class PrevisaoPublico {
  final int? total;
  final ConvidadosEquivalentes? idades;
  const PrevisaoPublico(this.total, this.idades);
  factory PrevisaoPublico.doEvento(Evento e) {
    final temIdades = e.totalAdultos != null ||
        e.totalCriancas != null ||
        e.totalBebes != null;
    final soma = e.totalConvidadosPorTipo;
    final total = e.totalConvidados ?? (temIdades ? soma : null);
    return PrevisaoPublico(
        total,
        temIdades && soma == total
            ? ConvidadosEquivalentes(
                adultos: e.totalAdultosCalculado,
                criancas: e.totalCriancasCalculado,
                bebes: e.totalBebesCalculado)
            : null);
  }
}

class PublicoPlanejado {
  final BaseCalculoFesta base;
  final PrevisaoPublico previsao;
  final CompletudeLista completude;
  final int? cadastrados, confirmados, naoRecusados, total;
  final ConvidadosEquivalentes? idades;
  const PublicoPlanejado(
      {required this.base,
      required this.previsao,
      required this.completude,
      required this.cadastrados,
      required this.confirmados,
      required this.naoRecusados,
      required this.total,
      required this.idades});
  bool get semDistribuicao => total != null && idades == null;
  String get resumo =>
      '${previsao.total == null ? 'Previsão não informada' : '${previsao.total} previstos'} · '
      '${cadastrados == null ? 'lista ainda indisponível' : 'lista ${completude.label}: $cadastrados ${cadastrados == 1 ? 'cadastrado' : 'cadastrados'}'} · '
      'cálculo usando ${base.label.toLowerCase()}${total == null ? ' (fonte indisponível)' : ': $total pessoas'}';
  String? get pendencia => total == null
      ? 'Informe a previsão ou confirme uma fonte disponível.'
      : semDistribuicao
          ? '$total pessoas previstas, com idades não informadas. Distribua adultos, crianças e bebês antes de calcular porções.'
          : null;
}

class PublicoPlanejamentoService {
  const PublicoPlanejamentoService();
  PublicoPlanejado resolver(
      {required String evento,
      required PrevisaoPublico previsao,
      required Iterable<Convidado> convidados,
      BaseCalculoFesta? base,
      CompletudeLista completude = CompletudeLista.desconhecida,
      bool listaDisponivel = true,
      ConvidadosEquivalentes? manual}) {
    final escolhida = base ?? BaseCalculoFesta.previstos;
    final lista = convidados.where((c) => c.idEvento == evento).toList();
    final confirmados =
        lista.where((c) => c.status == StatusConvidado.confirmado).toList();
    final naoRecusados =
        lista.where((c) => c.status != StatusConvidado.recusado).toList();
    final conjunto = switch (escolhida) {
      BaseCalculoFesta.apenasConfirmados => confirmados,
      BaseCalculoFesta.naoRecusados => naoRecusados,
      _ => lista,
    };
    final ConvidadosEquivalentes? idades = switch (escolhida) {
      BaseCalculoFesta.manual => manual,
      BaseCalculoFesta.previstos => previsao.idades,
      _ => !listaDisponivel
          ? null
          : ConvidadosEquivalentes(
              adultos: conjunto
                  .where((c) => c.tipoConvidado == TipoConvidado.adulto)
                  .length,
              criancas: conjunto
                  .where((c) => c.tipoConvidado == TipoConvidado.crianca)
                  .length,
              bebes: conjunto
                  .where((c) => c.tipoConvidado == TipoConvidado.bebe)
                  .length),
    };
    return PublicoPlanejado(
        base: escolhida,
        previsao: previsao,
        completude: completude,
        cadastrados: listaDisponivel ? lista.length : null,
        confirmados: listaDisponivel ? confirmados.length : null,
        naoRecusados: listaDisponivel ? naoRecusados.length : null,
        total: escolhida == BaseCalculoFesta.previstos
            ? previsao.total
            : idades?.totalInformado,
        idades: idades);
  }
}
