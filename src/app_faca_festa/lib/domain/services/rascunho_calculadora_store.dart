import '../entities/cadastro_evento_rascunho.dart';
import '../entities/rascunho_calculadora.dart';

abstract interface class RascunhoCalculadoraStore {
  RascunhoCalculadora? ler(String usuario, String evento);
  Future<void> salvar(
      String usuario, String evento, RascunhoCalculadora rascunho);
  Future<void> remover(String usuario, String evento);
}

/// A mesma store também guarda cadastros anteriores à criação remota.
abstract interface class CadastroEventoRascunhoStore {
  Future<LeituraCadastrosLocais> listarCadastros(String usuario);
  Future<void> salvarCadastro(CadastroEventoRascunho cadastro);
  Future<void> removerCadastro(String usuario, String id);
}
