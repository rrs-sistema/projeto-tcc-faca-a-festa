import 'package:app_faca_festa/data/models/convidado/convidado_model.dart'
    hide Convidado, StatusConvidado, TipoConvidado;
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromEntity preserves every guest domain value', () {
    final cadastrado = DateTime(2026, 8, 14, 10);
    final atualizado = DateTime(2026, 8, 14, 11);
    final entity = Convidado(
      idConvidado: 'convidado-1',
      idEvento: 'evento-1',
      nome: 'Ana',
      contato: '44999999999',
      email: 'ana@example.com',
      status: StatusConvidado.confirmado,
      tipoConvidado: TipoConvidado.crianca,
      idGrupo: 'grupo-1',
      nomeGrupo: 'Família',
      idMesa: 'mesa-1',
      numeroMesa: 2,
      ocupaAssento: true,
      cuidadoEspecial: true,
      dataCadastro: cadastrado,
      dataAtualizacao: atualizado,
    );

    final model = ConvidadoModel.fromEntity(entity);

    expect(model.idConvidado, entity.idConvidado);
    expect(model.idEvento, entity.idEvento);
    expect(model.nome, entity.nome);
    expect(model.status, entity.status);
    expect(model.tipoConvidado, entity.tipoConvidado);
    expect(model.dataCadastro, same(cadastrado));
    expect(model.dataAtualizacao, same(atualizado));
  });

  test('toMap preserves the current Firestore field contract', () {
    final cadastrado = DateTime(2026, 8, 14, 10);
    final atualizado = DateTime(2026, 8, 14, 11);
    final model = ConvidadoModel(
      idConvidado: 'convidado-1',
      idEvento: 'evento-1',
      nome: 'Ana',
      contato: '44999999999',
      status: StatusConvidado.confirmado,
      tipoConvidado: TipoConvidado.adulto,
      dataCadastro: cadastrado,
      dataAtualizacao: atualizado,
    );

    final map = model.toMap();

    expect(map['id_convidado'], 'convidado-1');
    expect(map['id_evento'], 'evento-1');
    expect(map['status'], 'confirmado');
    expect(map['tipo_convidado'], 'adulto');
    expect(map['adulto'], isTrue);
    expect((map['data_cadastro'] as Timestamp).toDate(), cadastrado);
    expect((map['data_atualizacao'] as Timestamp).toDate(), atualizado);
    expect(map['convite_token'], 'convidado-1');
    expect(map['convite_status'], 'link_gerado');
  });

  test('fromMap reads invite token and linked account without claiming delivery',
      () {
    final model = ConvidadoModel.fromMap({
      'id_convidado': 'convidado-2',
      'id_evento': 'evento-1',
      'nome': 'Bia',
      'contato': '44988887777',
      'status': 'pendente',
      'convite_token': 'token-abc',
      'convite_status': 'vinculado',
      'id_usuario': 'uid-9',
    });

    expect(model.tokenParaLink, 'token-abc');
    expect(model.contaVinculada, isTrue);
    expect(model.conviteStatus, 'vinculado');
    expect(model.idUsuario, 'uid-9');
    expect(model.toMap()['convite_enviado'], isNull);
  });

  test('fromMap marks linked Google account as eligible for tasks', () {
    final model = ConvidadoModel.fromMap({
      'id_convidado': 'e61e207f-41ca-45cc-9119-9377c8917cf9',
      'id_evento': '6a1f20be-f104-4066-9dcc-5144dac0d8e9',
      'nome': 'Rosineide A.',
      'contato': '41993653844',
      'email': 'rosineideneide.neide@gmail.com',
      'email_usuario': 'rosineideneide.neide@gmail.com',
      'email_normalizado': 'rosineideneide.neide@gmail.com',
      'convite_status': 'vinculado',
      'id_usuario': 'O8aWKGl1r2HZiZ2fpBITzzq8ribWU2',
    });

    expect(model.podeSerResponsavelTarefa, isTrue);
    expect(model.emailDaConta, 'rosineideneide.neide@gmail.com');
  });

  test('invite email alone does not make a guest eligible for tasks', () {
    final model = ConvidadoModel.fromMap({
      'id_convidado': 'convidado-3',
      'id_evento': 'evento-1',
      'nome': 'Carlos',
      'contato': '44911112222',
      'email': 'carlos@example.com',
      'convite_status': 'link_gerado',
    });

    expect(model.temEmail, isTrue);
    expect(model.podeSerResponsavelTarefa, isFalse);
  });

  test('linked status without uid still allows the guest to own a task', () {
    final model = ConvidadoModel.fromMap({
      'id_convidado': 'convidado-4',
      'id_evento': 'evento-1',
      'nome': 'Dora',
      'contato': '44900001111',
      'email': 'dora@example.com',
      'email_usuario': 'Dora@Example.com',
      'email_normalizado': 'dora@example.com',
      'convite_status': 'vinculado',
    });

    expect(model.podeSerResponsavelTarefa, isTrue);
    expect(
      model.mesmoIdentificador(
        Convidado(
          idConvidado: 'outro-id',
          idEvento: 'evento-1',
          nome: 'Dora',
          contato: '',
          email: 'dora@example.com',
          dataCadastro: DateTime(2026, 8, 18),
          dataAtualizacao: DateTime(2026, 8, 18),
        ),
      ),
      isTrue,
    );
  });
}
