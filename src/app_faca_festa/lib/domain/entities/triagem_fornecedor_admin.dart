import 'fornecedor.dart';

class TriagemFornecedorAdmin {
  const TriagemFornecedorAdmin({
    required this.casosAbertos,
    required this.casosCriticos,
    required this.semResponsavel,
    required this.cotacoesVencidas,
    this.eventoProximoEm,
    this.responsavel,
    this.casoPrioritarioAtribuido = false,
    this.casosParciais = false,
    this.cotacoesParciais = false,
    this.medida,
    this.servicoAfetado,
    this.restricaoAte,
  });

  factory TriagemFornecedorAdmin.fromMap(Map<String, dynamic> dados) {
    final restricao = dados['restricao'];
    return TriagemFornecedorAdmin(
      casosAbertos: (dados['casosAbertos'] as num).toInt(),
      casosCriticos: (dados['casosCriticos'] as num).toInt(),
      semResponsavel: (dados['semResponsavel'] as num).toInt(),
      cotacoesVencidas: (dados['cotacoesVencidas'] as num).toInt(),
      eventoProximoEm:
          DateTime.tryParse(dados['eventoProximoEm']?.toString() ?? ''),
      responsavel: dados['responsavel'] as String?,
      casoPrioritarioAtribuido: dados['casoPrioritarioAtribuido'] == true,
      casosParciais: dados['casosParciais'] == true,
      cotacoesParciais: dados['cotacoesParciais'] == true,
      medida: restricao is Map ? restricao['acao'] as String? : null,
      servicoAfetado: restricao is Map ? restricao['servico'] as String? : null,
      restricaoAte: restricao is Map
          ? DateTime.tryParse(restricao['ate']?.toString() ?? '')
          : null,
    );
  }

  final int casosAbertos, casosCriticos, semResponsavel, cotacoesVencidas;
  final DateTime? eventoProximoEm, restricaoAte;
  final String? responsavel, medida, servicoAfetado;
  final bool casoPrioritarioAtribuido, casosParciais, cotacoesParciais;

  bool get comRestricao => medida != null;
  bool get precisaAtencao =>
      casosAbertos > 0 || cotacoesVencidas > 0 || comRestricao;

  int get nivelUrgencia {
    if (casosCriticos > 0) return 5;
    if (eventoProximoEm != null) return 4;
    if (comRestricao) return 3;
    if (semResponsavel > 0) return 2;
    return precisaAtencao ? 1 : 0;
  }

  static String idDe(Fornecedor fornecedor) =>
      fornecedor.idFornecedor.trim().isEmpty
          ? fornecedor.idUsuario.trim()
          : fornecedor.idFornecedor.trim();

  static List<String> pendenciasDe(Fornecedor fornecedor, int servicosAtivos) =>
      [
        if (fornecedor.razaoSocial.trim().isEmpty) 'Nome ausente',
        if (fornecedor.email.trim().isEmpty) 'E-mail ausente',
        if (fornecedor.telefone.trim().isEmpty) 'Telefone ausente',
        if (servicosAtivos == 0) 'Sem serviços ativos',
      ];
}
