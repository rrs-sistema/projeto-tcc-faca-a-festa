import 'package:get_storage/get_storage.dart';

class PreferenciasNotificacao {
  const PreferenciasNotificacao({
    this.convites = true,
    this.cotacoes = true,
    this.chat = true,
    this.avaliacoes = true,
  });

  final bool convites;
  final bool cotacoes;
  final bool chat;
  final bool avaliacoes;

  PreferenciasNotificacao copyWith({
    bool? convites,
    bool? cotacoes,
    bool? chat,
    bool? avaliacoes,
  }) {
    return PreferenciasNotificacao(
      convites: convites ?? this.convites,
      cotacoes: cotacoes ?? this.cotacoes,
      chat: chat ?? this.chat,
      avaliacoes: avaliacoes ?? this.avaliacoes,
    );
  }

  Map<String, bool> toMap() => {
        'convites': convites,
        'cotacoes': cotacoes,
        'chat': chat,
        'avaliacoes': avaliacoes,
      };

  factory PreferenciasNotificacao.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const PreferenciasNotificacao();
    return PreferenciasNotificacao(
      convites: map['convites'] != false,
      cotacoes: map['cotacoes'] != false,
      chat: map['chat'] != false,
      avaliacoes: map['avaliacoes'] != false,
    );
  }
}

class PreferenciasNotificacaoStore {
  PreferenciasNotificacaoStore([GetStorage? storage])
      : _storage = storage ?? GetStorage();

  final GetStorage _storage;

  String _chave(String idUsuario) {
    final id = idUsuario.trim().isEmpty ? 'anon' : idUsuario.trim();
    return 'lgpd_notif_$id';
  }

  PreferenciasNotificacao ler(String idUsuario) {
    final bruto = _storage.read(_chave(idUsuario));
    if (bruto is Map) return PreferenciasNotificacao.fromMap(bruto);
    return const PreferenciasNotificacao();
  }

  void salvar(String idUsuario, PreferenciasNotificacao preferencias) {
    _storage.write(_chave(idUsuario), preferencias.toMap());
  }
}
