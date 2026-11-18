/// Heurística editorial: tipo de festa → categorias tipicamente cotadas.
class KitServicosPorTipo {
  const KitServicosPorTipo();

  List<String> sugerir(String tipoNome) {
    final t = tipoNome.toLowerCase().trim();
    if (t.contains('corporativ') ||
        t.contains('confratern') ||
        t.contains('empresa') ||
        t.contains('reunião') ||
        t.contains('reuniao')) {
      return const [
        'Buffet / coffee break',
        'Bebidas',
        'Espaço / salão',
        'Som e iluminação',
        'Decoração institucional',
      ];
    }
    if (t.contains('formatura') || t.contains('colação') || t.contains('colacao')) {
      return const [
        'Fotografia e vídeo',
        'Buffet',
        'Decoração de formatura',
        'Lembranças',
        'Espaço / salão',
      ];
    }
    if (t.contains('15') || t.contains('quinze') || t.contains('debutante')) {
      return const [
        'Decoração temática',
        'Bolo e doces',
        'Fotografia',
        'Som / DJ',
        'Animação',
      ];
    }
    if (t.contains('anivers') || t.contains('festa')) {
      return const [
        'Decoração',
        'Bolo e doces',
        'Fotografia',
        'Som',
        'Buffet / lanches',
      ];
    }
    if (t.contains('casamento') || t.contains('noivado')) {
      return const [
        'Buffet / catering',
        'Decoração floral',
        'Fotografia e vídeo',
        'Som e DJ',
        'Cerimonial',
      ];
    }
    if (t.contains('chá') || t.contains('cha') || t.contains('baby')) {
      return const [
        'Decoração',
        'Doces e salgados',
        'Fotografia',
        'Lembrancinhas',
      ];
    }
    return const [
      'Buffet',
      'Decoração',
      'Fotografia',
      'Som',
      'Espaço',
    ];
  }
}
