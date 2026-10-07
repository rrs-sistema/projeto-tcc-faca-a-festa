import 'package:app_faca_festa/core/legal/politica_privacidade.dart';
import 'package:app_faca_festa/core/legal/preferencias_notificacao.dart';
import 'package:app_faca_festa/core/legal/registro_tratamento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';

/// Texto de acesso e portabilidade (art. 18, II e V) com o que a conta guarda
/// e o registro completo de tratamentos.
String montarDossieTitular({
  required Usuario? usuario,
  required PreferenciasNotificacao preferencias,
  DateTime? geradoEm,
}) {
  final quando = geradoEm ?? DateTime.now();
  final buffer = StringBuffer()
    ..writeln('Faça a Festa — dossiê do titular')
    ..writeln('Gerado em ${_data(quando)}')
    ..writeln('Política versão ${PoliticaPrivacidade.versao}')
    ..writeln()
    ..writeln('1. Dados da conta');

  if (usuario == null) {
    buffer.writeln('Nenhuma conta autenticada neste aparelho.');
  } else {
    buffer
      ..writeln('Nome: ${usuario.nome}')
      ..writeln('E-mail: ${usuario.email}')
      ..writeln('CPF: ${_texto(usuario.cpf)}')
      ..writeln('Papel: ${_papel(usuario.tipo)}')
      ..writeln('Cidade: ${_texto(usuario.cidade)}')
      ..writeln('UF: ${_texto(usuario.uf)}')
      ..writeln('Conta ativa: ${usuario.ativo ? 'sim' : 'não'}')
      ..writeln(
        'Cadastro: ${usuario.dataCadastro == null ? '-' : _data(usuario.dataCadastro!)}',
      )
      ..writeln(
        'Verificação em duas etapas: ${usuario.mfaTotpAtivo || usuario.mfaEmailAtivo ? 'ativa' : 'inativa'}',
      )
      ..writeln(
        'Aceite da política: ${usuario.aceitePrivacidadeEm == null ? 'não registrado nesta sessão' : _data(usuario.aceitePrivacidadeEm!)}',
      )
      ..writeln(
        'Versão aceita: ${_texto(usuario.versaoPoliticaPrivacidade)}',
      );
  }

  buffer
    ..writeln()
    ..writeln('2. Preferências de aviso neste aparelho')
    ..writeln('Convites: ${_simNao(preferencias.convites)}')
    ..writeln('Cotações: ${_simNao(preferencias.cotacoes)}')
    ..writeln('Chat: ${_simNao(preferencias.chat)}')
    ..writeln()
    ..writeln('3. Telas, campos e proteções');

  for (final item in RegistroTratamento.itens) {
    buffer
      ..writeln()
      ..writeln('${item.modulo} — ${item.tela}')
      ..writeln('Campos: ${item.campos.join(', ')}')
      ..writeln('Titulares: ${item.titulares}')
      ..writeln('Finalidade: ${item.finalidade}')
      ..writeln('Base legal: ${item.baseLegal}')
      ..writeln('Proteção: ${item.protecao}')
      ..writeln('Retenção: ${item.retencao}')
      ..writeln('Compartilhamento: ${item.compartilhamento}');
  }

  buffer
    ..writeln()
    ..writeln('4. Limites deste dossiê')
    ..writeln(
      'Este arquivo traz a conta autenticada e o registro de tratamentos. Não inclui a lista de convidados, o orçamento nem as mensagens; esses dados continuam nas telas do evento e podem ser exportados ou excluídos por lá.',
    )
    ..writeln(
      'A cópia local em SQLite/Drift ainda não é criptografada em disco.',
    )
    ..writeln(
      'Os logs de auditoria são apagados depois de 365 dias.',
    )
    ..writeln(
      'O desligamento de avisos fica na conta. Convite por e-mail e avaliação por push consultam essa preferência.',
    )
    ..writeln(
      'Exclusão, anonimização e oposição geram protocolo. A conta só é apagada quando o administrador executa o pedido.',
    );

  return buffer.toString();
}

String _papel(String? tipo) {
  switch (tipo) {
    case 'O':
      return 'Organizador';
    case 'F':
      return 'Fornecedor';
    case 'C':
      return 'Convidado';
    case 'A':
      return 'Administrador';
    default:
      return tipo?.trim().isNotEmpty == true ? tipo!.trim() : '-';
  }
}

String _texto(String? valor) {
  final limpo = valor?.trim() ?? '';
  return limpo.isEmpty ? '-' : limpo;
}

String _simNao(bool valor) => valor ? 'ligado' : 'desligado';

String _data(DateTime data) {
  final local = data.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(local.day)}/${dois(local.month)}/${local.year} ${dois(local.hour)}:${dois(local.minute)}';
}
