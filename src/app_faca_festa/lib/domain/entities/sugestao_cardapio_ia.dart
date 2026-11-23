import 'cardapio.dart';
import 'cardapio_item.dart';

class SugestaoCardapioIaItem {
  const SugestaoCardapioIaItem({
    required this.idLocal,
    required this.nome,
    required this.tipo,
    required this.quantidade,
    required this.unidade,
    this.observacao,
    this.publicoAlvo = PublicoAlvoCardapio.todos,
    this.nomeCategoria = '',
  });

  final String idLocal;
  final String nome;
  final TipoItemCardapio tipo;
  final double quantidade;
  final String unidade;
  final String? observacao;
  final PublicoAlvoCardapio publicoAlvo;
  final String nomeCategoria;

  SugestaoCardapioIaItem copyWith({
    String? idLocal,
    String? nome,
    TipoItemCardapio? tipo,
    double? quantidade,
    String? unidade,
    String? observacao,
    bool limparObservacao = false,
    PublicoAlvoCardapio? publicoAlvo,
    String? nomeCategoria,
  }) {
    return SugestaoCardapioIaItem(
      idLocal: idLocal ?? this.idLocal,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      observacao:
          limparObservacao ? null : (observacao ?? this.observacao),
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
    );
  }
}

class SugestaoCardapioIaCategoria {
  const SugestaoCardapioIaCategoria({
    required this.nome,
    required this.itens,
  });

  final String nome;
  final List<SugestaoCardapioIaItem> itens;

  SugestaoCardapioIaCategoria copyWith({
    String? nome,
    List<SugestaoCardapioIaItem>? itens,
  }) {
    return SugestaoCardapioIaCategoria(
      nome: nome ?? this.nome,
      itens: itens ?? this.itens,
    );
  }
}

class SugestaoCardapioIa {
  const SugestaoCardapioIa({
    required this.nomeCardapio,
    required this.resumoPublico,
    required this.justificativa,
    required this.premissas,
    required this.categorias,
    required this.avisoEstimativa,
    this.bebesConsiderados = false,
    this.avisoBebes,
    this.fonte = 'ia_generativa',
  });

  final String nomeCardapio;
  final String resumoPublico;
  final String justificativa;
  final List<String> premissas;
  final List<SugestaoCardapioIaCategoria> categorias;
  final String avisoEstimativa;
  final bool bebesConsiderados;
  final String? avisoBebes;
  final String fonte;

  List<SugestaoCardapioIaItem> get todosItens => [
        for (final c in categorias) ...c.itens,
      ];

  SugestaoCardapioIa copyWith({
    String? nomeCardapio,
    String? resumoPublico,
    String? justificativa,
    List<String>? premissas,
    List<SugestaoCardapioIaCategoria>? categorias,
    String? avisoEstimativa,
    bool? bebesConsiderados,
    String? avisoBebes,
    bool limparAvisoBebes = false,
    String? fonte,
  }) {
    return SugestaoCardapioIa(
      nomeCardapio: nomeCardapio ?? this.nomeCardapio,
      resumoPublico: resumoPublico ?? this.resumoPublico,
      justificativa: justificativa ?? this.justificativa,
      premissas: premissas ?? this.premissas,
      categorias: categorias ?? this.categorias,
      avisoEstimativa: avisoEstimativa ?? this.avisoEstimativa,
      bebesConsiderados: bebesConsiderados ?? this.bebesConsiderados,
      avisoBebes: limparAvisoBebes ? null : (avisoBebes ?? this.avisoBebes),
      fonte: fonte ?? this.fonte,
    );
  }

  factory SugestaoCardapioIa.fromMap(Map<String, dynamic> map) {
    final categoriasRaw = map['categorias'];
    final categorias = <SugestaoCardapioIaCategoria>[];
    var seq = 0;

    if (categoriasRaw is List) {
      for (final catRaw in categoriasRaw) {
        if (catRaw is! Map) continue;
        final cat = Map<String, dynamic>.from(catRaw);
        final nomeCat = (cat['nome'] ?? '').toString().trim();
        final itensRaw = cat['itens'];
        if (nomeCat.isEmpty || itensRaw is! List) continue;

        final itens = <SugestaoCardapioIaItem>[];
        for (final itemRaw in itensRaw) {
          if (itemRaw is! Map) continue;
          final item = Map<String, dynamic>.from(itemRaw);
          final nome = (item['nome'] ?? '').toString().trim();
          final q = _toDouble(item['quantidade']);
          final unidade = _normalizarUnidade(
            (item['unidade'] ?? 'un').toString(),
          );
          if (nome.isEmpty || q == null || q <= 0 || unidade == null) continue;

          seq++;
          itens.add(
            SugestaoCardapioIaItem(
              idLocal: 'ia_$seq',
              nome: nome,
              tipo: TipoItemCardapio.fromString(item['tipo']?.toString()),
              quantidade: q,
              unidade: unidade,
              observacao: () {
                final o = item['observacao']?.toString().trim();
                return (o == null || o.isEmpty) ? null : o;
              }(),
              publicoAlvo: PublicoAlvoCardapio.fromString(
                item['publico_alvo']?.toString(),
              ),
              nomeCategoria: nomeCat,
            ),
          );
        }

        if (itens.isNotEmpty) {
          categorias.add(
            SugestaoCardapioIaCategoria(nome: nomeCat, itens: itens),
          );
        }
      }
    }

    if (categorias.isEmpty) {
      throw const FormatException('Sugestão de cardápio sem categorias válidas.');
    }

    final premissasRaw = map['premissas'];
    final premissas = premissasRaw is List
        ? premissasRaw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final nome = (map['nome_cardapio'] ?? '').toString().trim();
    return SugestaoCardapioIa(
      nomeCardapio:
          (nome.isEmpty ? 'Cardápio sugerido' : nome).substringSafe(80),
      resumoPublico:
          (map['resumo_publico'] ?? '').toString().trim().substringSafe(160),
      justificativa:
          (map['justificativa'] ?? '').toString().trim().substringSafe(400),
      premissas: premissas,
      categorias: categorias,
      avisoEstimativa: (map['aviso_estimativa'] ??
              'As quantidades são estimativas e podem variar conforme a duração da festa e o perfil dos convidados.')
          .toString(),
      bebesConsiderados: map['bebes_considerados'] == true,
      avisoBebes: () {
        final a = map['aviso_bebes']?.toString().trim();
        return (a == null || a.isEmpty) ? null : a;
      }(),
      fonte: (map['fonte'] ?? 'ia_generativa').toString(),
    );
  }
}

class EntradaGeracaoCardapioIa {
  const EntradaGeracaoCardapioIa({
    required this.idEvento,
    required this.tipoFesta,
    required this.totalPessoas,
    required this.momentoRefeicao,
    this.adultos,
    this.criancas,
    this.bebes,
    this.estilo,
    this.restricoes,
    this.observacoes,
    this.duracaoHoras,
  });

  final String idEvento;
  final String tipoFesta;
  final int totalPessoas;
  final String momentoRefeicao;
  final int? adultos;
  final int? criancas;
  final int? bebes;
  final String? estilo;
  final String? restricoes;
  final String? observacoes;
  final double? duracaoHoras;

  Map<String, dynamic> toPayload() => {
        'id_evento': idEvento,
        'tipo_festa': tipoFesta,
        'total_pessoas': totalPessoas,
        'momento_refeicao': momentoRefeicao,
        if (adultos != null) 'adultos': adultos,
        if (criancas != null) 'criancas': criancas,
        if (bebes != null) 'bebes': bebes,
        if (estilo != null && estilo!.trim().isNotEmpty) 'estilo': estilo,
        if (restricoes != null && restricoes!.trim().isNotEmpty)
          'restricoes': restricoes,
        if (observacoes != null && observacoes!.trim().isNotEmpty)
          'observacoes': observacoes,
        if (duracaoHoras != null) 'duracao_horas': duracaoHoras,
      };
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.'));
  }
  return null;
}

String? _normalizarUnidade(String raw) {
  final u = raw.trim().toLowerCase();
  if (u == 'l' || u == 'litro' || u == 'litros' || u == 'lt') return 'l';
  if (u == 'un' || u == 'unidade' || u == 'unidades' || u == 'und') return 'un';
  if (u == 'kg' || u == 'quilo' || u == 'quilos') return 'kg';
  if (u == 'g' || u == 'grama' || u == 'gramas') return 'g';
  return null;
}

extension on String {
  String substringSafe(int max) =>
      length <= max ? this : substring(0, max);
}
