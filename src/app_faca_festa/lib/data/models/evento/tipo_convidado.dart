enum TipoConvidado {
  adulto,
  crianca,
  bebe;

  String get label {
    switch (this) {
      case TipoConvidado.adulto:
        return 'Adulto';
      case TipoConvidado.crianca:
        return 'Criança';
      case TipoConvidado.bebe:
        return 'Bebê';
    }
  }

  String get firestoreValue {
    switch (this) {
      case TipoConvidado.adulto:
        return 'adulto';
      case TipoConvidado.crianca:
        return 'crianca';
      case TipoConvidado.bebe:
        return 'bebe';
    }
  }

  static TipoConvidado fromString(String? value) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'adulto':
        return TipoConvidado.adulto;
      case 'crianca':
      case 'criança':
        return TipoConvidado.crianca;
      case 'bebe':
      case 'bebê':
        return TipoConvidado.bebe;
      default:
        return TipoConvidado.adulto;
    }
  }

  static TipoConvidado fromLegacyAdulto(bool? adulto) {
    if (adulto == false) return TipoConvidado.crianca;
    return TipoConvidado.adulto;
  }
}
