/// Valores monetários novos usam centavos inteiros em BRL.
/// Campos legados em double (reais) continuam legíveis sem migração silenciosa.
class ValorMonetario {
  const ValorMonetario._(this.centavos);

  final int centavos;

  static const int limiteCentavos = 100000000; // R$ 1.000.000,00
  static const ValorMonetario zero = ValorMonetario._(0);

  factory ValorMonetario.centavos(int centavos) {
    if (centavos < 0 || centavos > limiteCentavos) {
      throw ArgumentError('Valor monetário fora dos limites permitidos.');
    }
    return ValorMonetario._(centavos);
  }

  /// Adapta legado em reais sem arredondar silenciosamente valores ambíguos.
  /// Retorna null se o double não representar centavos exatos (ex.: 10.001).
  static ValorMonetario? deReaisLegado(num? reais) {
    if (reais == null) return null;
    if (!reais.isFinite || reais < 0) return null;
    final centavos = (reais.toDouble() * 100).round();
    final reconstruido = centavos / 100.0;
    if ((reconstruido - reais.toDouble()).abs() > 1e-9) return null;
    if (centavos > limiteCentavos) return null;
    return ValorMonetario._(centavos);
  }

  /// Converte reais para centavos com arredondamento bancário explícito
  /// (apenas para comandos novos que já validam entrada).
  static ValorMonetario deReaisArredondado(num reais) {
    if (!reais.isFinite || reais < 0) {
      throw ArgumentError('Informe um valor em reais válido.');
    }
    final centavos = (reais.toDouble() * 100).round();
    return ValorMonetario.centavos(centavos);
  }

  double get emReais => centavos / 100.0;

  Map<String, dynamic> toMap() => {
        'centavos': centavos,
        'moeda': 'BRL',
      };

  static ValorMonetario? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final c = map['centavos'];
    if (c is int) return ValorMonetario.centavos(c);
    if (c is num && c == c.roundToDouble()) {
      return ValorMonetario.centavos(c.toInt());
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ValorMonetario && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => 'R\$ ${emReais.toStringAsFixed(2)}';
}
