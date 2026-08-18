import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/endereco/endereco_usuario.dart';
import '../../models/usuario/usuario_model.dart';

abstract interface class PerfilUsuarioRemoteDatasource {
  Future<UsuarioModel?> buscarUsuario(String idUsuario);

  Future<List<UsuarioModel>> listarUsuarios();

  Future<List<EnderecoUsuarioModel>> listarEnderecos(String idUsuario);

  Future<EnderecoUsuarioModel?> buscarEnderecoPrincipal(String idUsuario);

  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  });

  Future<void> atualizarFotoPerfil(String idUsuario, String fotoPerfilUrl);

  Future<void> atualizarTipo(String idUsuario, String tipo);

  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo);

  Future<void> salvarUsuario(UsuarioModel usuario);

  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  });

  String criarIdEndereco();

  Future<void> salvarEndereco(EnderecoUsuarioModel endereco);

  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  });
}

class FirebasePerfilUsuarioRemoteDatasource
    implements PerfilUsuarioRemoteDatasource {
  FirebasePerfilUsuarioRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<UsuarioModel?> buscarUsuario(String idUsuario) async {
    final documento =
        await firestore.collection('usuarios').doc(idUsuario).get();
    if (!documento.exists || documento.data() == null) return null;
    return UsuarioModel.fromMap(documento.data()!);
  }

  @override
  Future<List<UsuarioModel>> listarUsuarios() async {
    final snapshot = await firestore.collection('usuarios').get();
    return snapshot.docs
        .map((documento) => UsuarioModel.fromMap(documento.data()))
        .toList();
  }

  @override
  Future<List<EnderecoUsuarioModel>> listarEnderecos(String idUsuario) async {
    final snapshot = await firestore
        .collection('usuarios')
        .doc(idUsuario)
        .collection('enderecos')
        .get();
    return snapshot.docs
        .map((documento) => EnderecoUsuarioModel.fromMap(documento.data()))
        .toList();
  }

  @override
  Future<EnderecoUsuarioModel?> buscarEnderecoPrincipal(
    String idUsuario,
  ) async {
    final snapshot = await firestore
        .collection('usuarios')
        .doc(idUsuario)
        .collection('enderecos')
        .where('principal', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return EnderecoUsuarioModel.fromMap(snapshot.docs.first.data());
  }

  @override
  Future<void> atualizarDadosBasicos({
    required String idUsuario,
    required String nome,
    required String cpf,
  }) =>
      firestore.collection('usuarios').doc(idUsuario).update({
        'nome': nome,
        'cpf': cpf,
      });

  @override
  Future<void> atualizarFotoPerfil(
    String idUsuario,
    String fotoPerfilUrl,
  ) =>
      firestore.collection('usuarios').doc(idUsuario).update({
        'foto_perfil_url': fotoPerfilUrl,
      });

  @override
  Future<void> atualizarTipo(String idUsuario, String tipo) =>
      firestore.collection('usuarios').doc(idUsuario).update({'tipo': tipo});

  @override
  Future<void> atualizarStatusAtivo(String idUsuario, bool ativo) =>
      firestore.collection('usuarios').doc(idUsuario).update({'ativo': ativo});

  @override
  Future<void> salvarUsuario(UsuarioModel usuario) => firestore
      .collection('usuarios')
      .doc(usuario.idUsuario)
      .set(usuario.toMap());

  @override
  Future<void> criarUsuarioAutomatico({
    required String idUsuario,
    required String? email,
  }) =>
      firestore.collection('usuarios').doc(idUsuario).set({
        'id_usuario': idUsuario,
        'email': email,
        'nome': '',
        'tipo': 'O',
        'ativo': true,
        'criado_automaticamente': true,
        'data_cadastro': FieldValue.serverTimestamp(),
      });

  @override
  String criarIdEndereco() => firestore.collection('x').doc().id;

  @override
  Future<void> salvarEndereco(EnderecoUsuarioModel endereco) => firestore
      .collection('usuarios')
      .doc(endereco.idUsuario)
      .collection('enderecos')
      .doc(endereco.id)
      .set(endereco.toMap());

  @override
  Future<void> atualizarLocalizacaoUsuario({
    required String idUsuario,
    required String cidade,
    required String uf,
  }) =>
      firestore.collection('usuarios').doc(idUsuario).update({
        'cidade': cidade,
        'uf': uf,
      });
}
