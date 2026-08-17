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
  });
}
