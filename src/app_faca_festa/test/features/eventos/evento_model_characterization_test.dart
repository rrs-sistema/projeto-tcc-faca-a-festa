import 'package:app_faca_festa/data/models/evento/evento_model.dart';
import 'package:app_faca_festa/data/models/evento/tipo_evento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventoModel characterization', () {
    test('toMap preserves the complete Firestore document contract', () {
      final data = DateTime(2026, 12, 20, 19, 30);
      final cadastro = DateTime(2026, 8, 14, 10);
      final nascimento = DateTime(2027, 2, 1);
      final evento = EventoModel(
        idEvento: 'evento-1',
        idTipoEvento: 'tipo-1',
        idUsuario: 'usuario-1',
        idCidade: '10',
        nomeCidade: 'Maringá',
        uf: 'PR',
        nomePessoalPrincipal: 'Maria',
        nomeEvento: 'Celebração',
        localEvento: 'Salão',
        data: data,
        hora: '19:30',
        custoEstimado: 15000.5,
        totalConvidados: 100,
        totalAdultos: 70,
        totalCriancas: 20,
        totalBebes: 10,
        status: StatusEvento.confirmado,
        descricao: 'Descrição',
        cep: '87000-000',
        logradouro: 'Rua A',
        numero: '123',
        complemento: 'Fundos',
        bairro: 'Centro',
        ativo: true,
        dataCadastro: cadastro,
        nomeNoiva: 'Ana',
        nomeNoivo: 'João',
        tipoCerimonia: 'Civil',
        estiloCasamento: 'Clássico',
        padrinhos: const ['A', 'B'],
        nomeAniversariante: 'Clara',
        idade: 30,
        idTema: 'safari',
        tema: 'Flores',
        nomeResponsavel: 'Responsável',
        nomeGestante: 'Gestante',
        nomeBebe: 'Bebê',
        tipoCha: 'Revelação',
        dataPrevistaNascimento: nascimento,
        hashtagEvento: '#festa',
        siteEvento: 'https://example.com',
        dressCode: 'Social',
      );

      final map = evento.toMap();

      expect(map.keys.toSet(), _firestoreKeys);
      expect(map['id_evento'], 'evento-1');
      expect(map['status'], 'confirmado');
      expect(map['total_convidados'], 100);
      expect((map['data'] as Timestamp).toDate(), data);
      expect((map['data_cadastro'] as Timestamp).toDate(), cadastro);
      expect(
        (map['data_prevista_nascimento'] as Timestamp).toDate(),
        nascimento,
      );
      expect(map['padrinhos'], ['A', 'B']);
      expect(map['id_tema'], 'safari');
    });

    test('fromMap preserves fallbacks and numeric parsing', () {
      final evento = EventoModel.fromMap({
        'id_evento': 'evento-2',
        'id_tipo_evento': 'tipo-2',
        'id_usuario': 'usuario-2',
        'id_cidade': 15,
        'nome_evento': 'Evento',
        'logradouro': 'Local alternativo',
        'data': '2026-12-21T20:00:00.000',
        'total_convidados': 0,
        'total_adultos': '40',
        'total_criancas': 8.9,
        'total_bebes': null,
        'status': 'valor_desconhecido',
      });

      expect(evento.idCidade, '15');
      expect(evento.localEvento, 'Local alternativo');
      expect(evento.data, DateTime(2026, 12, 21, 20));
      expect(evento.totalAdultos, 40);
      expect(evento.totalCriancas, 8);
      expect(evento.totalBebes, isNull);
      expect(evento.totalConvidados, 48);
      expect(evento.totalConvidadosCalculado, 48);
      expect(evento.status, StatusEvento.planejamento);
      expect(evento.ativo, isTrue);
    });

    test('calculated total prefers a positive explicit total', () {
      final evento = EventoModel(
        idEvento: 'evento-3',
        idTipoEvento: 'tipo-3',
        idUsuario: 'usuario-3',
        nomeEvento: 'Evento',
        localEvento: 'Local',
        data: DateTime(2026),
        totalConvidados: 90,
        totalAdultos: 40,
        totalCriancas: 10,
        totalBebes: 5,
      );

      expect(evento.totalConvidadosPorTipo, 55);
      expect(evento.totalConvidadosCalculado, 90);
      expect(evento.possuiQuantidadePorTipo, isTrue);
    });

    test('fromMap reads legacy guest-facing name and message fields', () {
      final evento = EventoModel.fromMap({
        'id_evento': 'evento-legado',
        'id_tipo_evento': 'tipo-1',
        'id_usuario': 'usuario-1',
        'nome': 'Nome legado',
        'mensagem': 'Mensagem aos convidados',
        'data': '2026-12-21T20:00:00.000',
      });

      expect(evento.nomeEvento, 'Nome legado');
      expect(evento.mensagemConvidado, 'Mensagem aos convidados');
      expect(evento.toMap().containsKey('mensagem'), isFalse);
    });

    test('fromEntity preserves domain values without casting', () {
      final entity = Evento(
        idEvento: 'evento-4',
        idTipoEvento: 'tipo-4',
        idUsuario: 'usuario-4',
        nomeEvento: 'Evento de domínio',
        localEvento: 'Local',
        data: DateTime(2026, 12, 22),
        custoEstimado: 2000,
        totalAdultos: 20,
        status: StatusEvento.rascunho,
      );

      final model = EventoModel.fromEntity(entity);

      expect(model, isA<Evento>());
      expect(model.idEvento, entity.idEvento);
      expect(model.nomeEvento, entity.nomeEvento);
      expect(model.custoEstimado, entity.custoEstimado);
      expect(model.totalAdultos, entity.totalAdultos);
      expect(model.status, entity.status);
      expect(model.dataCadastro, entity.dataCadastro);
    });

    test('event type model preserves the pure domain entity', () {
      const entity = TipoEvento(
        idTipoEvento: 'tipo-1',
        nome: 'Casamento',
        ativo: false,
      );

      final model = TipoEventoModel.fromEntity(entity);

      expect(model, isA<TipoEvento>());
      expect(model.idTipoEvento, entity.idTipoEvento);
      expect(model.nome, entity.nome);
      expect(model.ativo, entity.ativo);
    });
  });
}

const _firestoreKeys = {
  'id_evento',
  'id_tipo_evento',
  'id_usuario',
  'id_cidade',
  'nome_cidade',
  'uf',
  'nome_pessoa_principal',
  'nome_evento',
  'local_evento',
  'data',
  'hora',
  'custo_estimado',
  'total_convidados',
  'total_adultos',
  'total_criancas',
  'total_bebes',
  'status',
  'descricao',
  'cep',
  'logradouro',
  'numero',
  'complemento',
  'bairro',
  'ativo',
  'data_cadastro',
  'nome_noiva',
  'nome_noivo',
  'tipo_cerimonia',
  'estilo_casamento',
  'padrinhos',
  'nome_aniversariante',
  'idade',
  'id_tema',
  'tema',
  'nome_responsavel',
  'nome_gestante',
  'nome_bebe',
  'tipo_cha',
  'data_prevista_nascimento',
  'hashtag_evento',
  'site_evento',
  'dress_code',
};
