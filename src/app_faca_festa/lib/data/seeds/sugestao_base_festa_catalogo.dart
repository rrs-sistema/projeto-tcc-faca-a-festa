import 'package:app_faca_festa/data/models/evento/sugestao_base_festa_model.dart';
import 'package:app_faca_festa/data/seeds/sugestao_base_festa_seed.dart';
import 'package:app_faca_festa/domain/entities/sugestao_base_festa.dart';

/// Catálogo ativo importado pelo admin. `sugestoesBaseFestaSeed001` e
/// `sugestoesBaseFestaSeed002` são rascunhos com IDs diferentes e ficam de fora.
List<SugestaoBaseFesta> catalogoSugestoesBaseFesta() {
  return sugestoesBaseFestaSeed
      .map(
        (item) => SugestaoBaseFestaModel.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
      .where((item) => item.id.trim().isNotEmpty)
      .toList(growable: false);
}
