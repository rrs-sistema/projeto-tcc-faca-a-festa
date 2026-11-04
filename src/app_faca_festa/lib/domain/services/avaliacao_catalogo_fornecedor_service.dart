import '../entities/fornecedor.dart';
import '../entities/fornecedor_servico_detalhado.dart';

class CriterioCatalogo {
  const CriterioCatalogo(
      {required this.id,
      required this.titulo,
      required this.acao,
      required this.campo,
      required this.peso,
      required this.pontos,
      required this.detalhe});
  final String id, titulo, acao, campo, detalhe;
  final double peso, pontos;
  bool get concluido => pontos == peso;
}

class AvaliacaoCatalogo {
  const AvaliacaoCatalogo(this.criterios, this.servicos);
  final List<CriterioCatalogo> criterios;
  final List<FornecedorServicoDetalhado> servicos;
  double get pesoTotal => criterios.fold(0, (s, c) => s + c.peso);
  double get score =>
      criterios.fold<double>(0, (s, c) => s + c.pontos) / pesoTotal * 100;
  List<CriterioCatalogo> get pendentes =>
      criterios.where((c) => !c.concluido).toList();
  int get concluidos => criterios.length - pendentes.length;
  int get semFoto => servicos.where((s) => !temTexto(s.imagemUrl)).length;
  int get semDescricao =>
      servicos.where((s) => !temTexto(s.descricaoServico)).length;
  int get semPreco =>
      servicos.where((s) => !precoValido(s.precoEfetivo)).length;
  double impacto(CriterioCatalogo c) => (c.peso - c.pontos) / pesoTotal * 100;
  static bool temTexto(String? s) => s?.trim().isNotEmpty == true;
  static bool precoValido(double? n) => n != null && n.isFinite && n > 0;
}

/// Regra única para o indicador, suas pendências e as sugestões do catálogo.
/// Mantém os pesos comerciais anteriores e normaliza pela soma real (110).
class AvaliacaoCatalogoFornecedorService {
  const AvaliacaoCatalogoFornecedorService();
  AvaliacaoCatalogo avaliar(
      {required Fornecedor fornecedor,
      List<FornecedorServicoDetalhado> servicos = const []}) {
    final ativos = servicos
        .where((s) => s.ativo && s.idFornecedor == fornecedor.idFornecedor)
        .toList();
    final quantidade = ativos.length;
    final criterios = <CriterioCatalogo>[];
    void criterio(String id, String titulo, String acao, String campo, bool ok,
        String detalhe,
        {double peso = 10, double parcial = 0}) {
      criterios.add(CriterioCatalogo(
          id: id,
          titulo: titulo,
          acao: acao,
          campo: campo,
          peso: peso,
          pontos: ok ? peso : parcial,
          detalhe: detalhe));
    }

    criterio(
        'banner',
        'Imagem do fornecedor',
        'Cadastrar banner do fornecedor',
        'banner_url',
        AvaliacaoCatalogo.temTexto(fornecedor.bannerUrl),
        'No perfil do fornecedor, adicione uma imagem de apresentação.');
    final tamanho = fornecedor.descricao?.trim().length ?? 0;
    criterio(
        'descricao',
        'Descrição comercial com pelo menos 80 caracteres',
        'Completar descrição comercial',
        'descricao',
        tamanho >= 80,
        'No perfil do fornecedor: $tamanho de 80 caracteres mínimos.');
    criterio(
        'categorias',
        'Categorias de atendimento',
        'Adicionar categorias',
        'categorias',
        fornecedor.categorias.isNotEmpty,
        'No perfil do fornecedor, selecione pelo menos uma categoria.');
    criterio(
        'eventos',
        'Tipos de evento atendidos',
        'Selecionar tipos de evento atendidos',
        'tipo_evento_ids',
        [
          ...fornecedor.tipoEventoIds,
          ...fornecedor.tipoEventoSlugs,
          ...fornecedor.tipoEventoNomes
        ].any((s) => s.trim().isNotEmpty),
        'No perfil do fornecedor, selecione pelo menos um tipo de evento.');
    criterio(
        'faixa',
        'Faixa de preço do fornecedor',
        'Informar faixa de preço',
        'preco_minimo/preco_maximo/preco_medio',
        [fornecedor.precoMinimo, fornecedor.precoMaximo, fornecedor.precoMedio]
            .any(AvaliacaoCatalogo.precoValido),
        'No perfil do fornecedor, informe um preço mínimo, médio ou máximo maior que zero.');
    criterio(
        'ofertas',
        'Variedade de ofertas: pelo menos 3 ativas',
        quantidade == 0
            ? 'Criar serviços/produtos'
            : 'Adicionar mais serviços ativos',
        'servicos_ativos',
        quantidade >= 3,
        'No Catálogo de venda: $quantidade de 3 ofertas ativas para atingir este critério.',
        peso: 15,
        parcial: quantidade > 0 ? 8 : 0);
    void ofertas(String id, String titulo, String acao, String campo,
        bool Function(FornecedorServicoDetalhado) falta,
        {double peso = 10}) {
      final faltantes = ativos.where(falta).toList();
      final nomes = faltantes
          .map((s) => s.nomeServico?.trim().isNotEmpty == true
              ? s.nomeServico!.trim()
              : 'Serviço sem nome')
          .join(', ');
      criterio(
          id,
          titulo,
          acao,
          campo,
          quantidade > 0 && faltantes.isEmpty,
          quantidade == 0
              ? 'Cadastre ofertas ativas no Catálogo de venda para atender este critério.'
              : faltantes.isEmpty
                  ? 'Todas as ofertas ativas atendem este critério.'
                  : 'No Catálogo de venda: $nomes (${faltantes.length} de $quantidade ofertas).',
          peso: peso);
    }

    ofertas(
        'fotos',
        'Todas as ofertas ativas com foto',
        'Adicionar imagens aos serviços',
        'imagem_url',
        (s) => !AvaliacaoCatalogo.temTexto(s.imagemUrl));
    ofertas(
        'descricoes',
        'Todas as ofertas ativas com descrição',
        'Completar descrição dos serviços',
        'descricao_servico',
        (s) => !AvaliacaoCatalogo.temTexto(s.descricaoServico));
    ofertas(
        'precos',
        'Todas as ofertas ativas com preço válido',
        'Informar preço dos serviços',
        'preco',
        (s) => !AvaliacaoCatalogo.precoValido(s.precoEfetivo),
        peso: 15);
    ofertas(
        'medidas',
        'Todas as ofertas ativas com unidade de medida',
        'Informar tipo de medida dos serviços',
        'tipo_medida',
        (s) => !AvaliacaoCatalogo.temTexto(s.tipoMedida));
    return AvaliacaoCatalogo(
        List.unmodifiable(criterios), List.unmodifiable(ativos));
  }
}
