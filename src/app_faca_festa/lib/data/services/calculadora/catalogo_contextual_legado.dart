import '../../../domain/entities/referencia_contextual.dart';
import '../../../domain/services/referencia_porcao_service.dart';
import '../../../domain/services/rendimento_referencia_service.dart';
import '../../../domain/services/proposta_refeicao_service.dart';

/// Propostas de migração, nunca publicações automáticas. Valores/fonte originais.
class CatalogoContextualLegado {
  static List<ReferenciaContextual> propostas() {
    Map<String, dynamic> base(String id, String nome, String fonte) => {
          'schema': 1,
          'motor_minimo': 1,
          'id': id,
          'versao': 1,
          'tipo': 'porcao',
          'nome': nome,
          'aliases': [nome],
          'alimento_receita': nome,
          'servicos': ['refeicao'],
          'formatos': ['buffet'],
          'periodos': ['qualquer'],
          'publicos': ['adultos'],
          'obtencoes': ['servir'],
          'papel': 'outro',
          'unidade': 'quilo',
          'estado_consumo': 'pronto',
          'estado_compra': 'pronto',
          'contexto': 'Contexto legado a revisar antes de publicar.',
          'limitacoes':
              'Serviço, formato, público e obtenção são proposta de enquadramento; exigem revisão editorial. Não é adequação universal.',
          'fonte': fonte,
          'verificado_em': null,
          'revisao_editorial':
              'Migração para revisão; fonte não consultada nesta entrega.',
          'origem_legado': 'referencias_locais_v1',
          'aprovado_por': null,
          'aprovado_em': null,
        };
    return [
      for (final r in ReferenciaPorcaoService.referencias)
        ReferenciaContextual({
          ...base(r.id, r.nome, r.fonte),
          'aliases': r.aliases,
          'papel': r.papel,
          'estado_consumo': r.estado,
          'estado_compra': r.estado,
          'unidade': r.unidade.name,
          'minimo': r.minimo,
          'maximo': r.maximo,
          'padrao': r.minimo,
          if (r.id == 'brasileira_salgados_festa_v1') ...{
            'duracao_minima': 180,
            'duracao_maxima': 240,
            'servicos': ['lanche']
          },
          if (r.id == 'brasileira_salgados_empresarial_v1') ...{
            'duracao_minima': 30,
            'duracao_maxima': 40,
            'servicos': ['lanche']
          },
          'contexto': r.contexto,
          'verificado_em': r.verificadoEm,
          'origem_legado':
              'ReferenciaPorcaoService/${r.id} — data declarada pelo código anterior',
        }),
      for (final r in RendimentoReferenciaService.referencias)
        ReferenciaContextual({
          ...base(r.id, r.titulo, RendimentoReferenciaService.fonte),
          'tipo': 'rendimento',
          'aliases': ['churrasco', 'carnes do churrasco'],
          'estado_compra': 'cru',
          'minimo': r.fator,
          'maximo': r.fator,
          'padrao': r.fator,
          'contexto': r.titulo,
          'origem_legado': 'RendimentoReferenciaService/${r.id}',
        }),
      for (final sobremesa in [false, true])
        ReferenciaContextual({
          ...base(
              'legado_frutas_${sobremesa ? 'sobremesa' : 'complemento'}_v1',
              'Frutas ${sobremesa ? 'sobremesa' : 'complemento'}',
              PropostaRefeicaoService.fonteFrutas),
          'aliases': ['frutas', 'frutas cortadas', 'salada de frutas'],
          'minimo': sobremesa ? .20 : .10,
          'maximo': sobremesa ? .25 : .15,
          'padrao': sobremesa ? .225 : .125,
          'contexto':
              'Parte comestível descascada/cortada como ${sobremesa ? 'sobremesa principal' : 'complemento'}. Não equivale à fruta inteira.'
        }),
      for (final uso in ['principal', 'grande', 'complemento'])
        ReferenciaContextual({
          ...base('legado_dog_${uso}_v1', 'Cachorro-quente $uso',
              PropostaRefeicaoService.fonteDog),
          'aliases': ['cachorro-quente', 'hot dog'],
          'unidade': 'unidade',
          'minimo': uso == 'principal' ? 2 : 1,
          'maximo': uso == 'principal'
              ? 3
              : uso == 'grande'
                  ? 2
                  : 1,
          'padrao': uso == 'principal'
              ? 2
              : uso == 'grande'
                  ? 1.5
                  : 1,
          'contexto':
              'Unidades montadas ${uso == 'grande' ? 'de tamanho grande como lanche principal' : uso == 'principal' ? 'tradicionais como lanche principal' : 'como complemento de outros lanches'}. Pão e recheio dependem da receita.'
        }),
      for (final m in <String, List<String>>{
        'churrasco': ['Churrasco', 'Arroz', 'Macarrão'],
        'coquetel': ['Salgadinhos', 'Bolo', 'Docinhos'],
        'refeicao': ['Arroz', 'Feijão', 'Macarrão'],
        'lanche': ['Cachorro-quente', 'Frutas'],
      }.entries)
        ReferenciaContextual({
          ...base('modelo_legado_${m.key}_v1', 'Modelo ${m.key}',
              'codigo:lib/domain/services/plano_evento_service.dart#legado-v1'),
          'tipo': 'modelo',
          'servicos': [
            m.key == 'lanche' || m.key == 'coquetel' ? 'lanche' : 'refeicao'
          ],
          'contexto':
              'Hipótese de composição do produto existente; não é recomendação nutricional nem universal.',
          'itens': [
            for (final nome in m.value)
              {
                'nome': nome,
                'tipo': nome == 'Bolo'
                    ? 'bolo'
                    : nome == 'Docinhos'
                        ? 'sobremesa'
                        : 'comida'
              }
          ],
        }),
    ];
  }
}
