import 'admin_dashboard_bootstrap.dart';
import 'admin_territorio_bootstrap.dart';
import 'app_controller_bootstrap.dart';
import 'auditoria_bootstrap.dart';
import 'autenticacao_bootstrap.dart';
import 'avaliacao_servico_bootstrap.dart';
import 'calculadora_bootstrap.dart';
import 'catalogo_servico_bootstrap.dart';
import 'comunidade_bootstrap.dart';
import 'convidado_bootstrap.dart';
import 'cotacao_bootstrap.dart';
import 'documento_bootstrap.dart';
import 'evento_bootstrap.dart';
import 'eventos_admin_bootstrap.dart';
import 'fornecedor_bootstrap.dart';
import 'fornecedor_recomendacao_bootstrap.dart';
import 'inspiracao_bootstrap.dart';
import 'orcamento_bootstrap.dart';
import 'orcamento_gasto_bootstrap.dart';
import 'orcamentos_admin_bootstrap.dart';
import 'perfil_usuario_bootstrap.dart';
import 'ranking_bootstrap.dart';
import 'servico_foto_bootstrap.dart';
import 'servico_produto_bootstrap.dart';
import 'solicitacoes_bootstrap.dart';
import 'tema_festa_bootstrap.dart';
import 'uf_cidade_bootstrap.dart';

abstract final class AppBootstrap {
  static void registerControllers() {
    AutenticacaoBootstrap.register();
    DocumentoBootstrap.register();
    ConvidadoBootstrap.register();
    PerfilUsuarioBootstrap.register();
    FornecedorBootstrap.register();
    ComunidadeBootstrap.register();
    AvaliacaoServicoBootstrap.register();
    RankingBootstrap.register();
    UfCidadeBootstrap.register();
    FornecedorRecomendacaoBootstrap.register();
    ServicoFotoBootstrap.register();
    ServicoProdutoBootstrap.register();
    CatalogoServicoBootstrap.register();
    EventoBootstrap.register();
    TemaFestaBootstrap.register();
    SolicitacoesBootstrap.register();
    CotacaoBootstrap.register();
    CalculadoraBootstrap.register();
    AdminDashboardBootstrap.register();
    AuditoriaBootstrap.register();
    EventosAdminBootstrap.register();
    OrcamentosAdminBootstrap.register();
    OrcamentoBootstrap.register();
    OrcamentoGastoBootstrap.register();
    AdminTerritorioBootstrap.register();
    InspiracaoBootstrap.register();
    AppControllerBootstrap.register();
  }
}
