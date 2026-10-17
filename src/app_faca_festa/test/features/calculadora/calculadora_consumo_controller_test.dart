import 'package:app_faca_festa/domain/services/referencia_porcao_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_composicao_test.dart'
    show AuthQA, RepositoryQA, BaseQA, AiQA;
import 'calculadora_calibracao_test.dart' show arrozObservado;

class ConsumoRepoQA extends RepositoryQA {
  final chamadas = <String>[];
  bool falhar = false;
  final persistido = <String, dynamic>{
    'consumo_observado': <String, dynamic>{}
  };
  @override
  Future<void> salvarSimulacao(
      {required CalculadoraFesta calculo,
      required List<CalculadoraFestaItem> itens}) async {
    chamadas.add('simulacao');
    persistido.addAll(CalculadoraFestaModel.fromEntity(calculo).toMap());
  }

  @override
  Future<void> registrarConsumo(String id, RegistroConsumoCalculadora r) async {
    chamadas.add('consumo');
    if (falhar) throw StateError('indisponível');
    (persistido['consumo_observado'] as Map)[r.regra.id] = r.toMap();
  }

  @override
  Future<List<CalculadoraFesta>> listarSimulacoesPorEvento(String id) async {
    chamadas.add('listar');
    return [];
  }
}

void main() {
  late CalculadoraFestaController c;
  late ConsumoRepoQA repo;
  setUp(() {
    Get.put<FirebaseAuth>(AuthQA());
    repo = ConsumoRepoQA();
    c = CalculadoraFestaController(
        aiService: AiQA(), repository: repo, itensBaseRepository: BaseQA());
    c.idEventoAtual.value = 'evento';
    c.totalAdultos.value = 10;
    c.itensEstimativa.assignAll([arrozObservado()]);
    c.calcular();
  });
  tearDown(() {
    c.onClose();
    Get.reset();
  });
  RegistroConsumoCalculadora registro() {
    final r = c.regraDoResultado(c.itensCalculados.single)!;
    return RegistroConsumoCalculadora(
        idEvento: 'evento',
        contexto: c.contextoConsumo(r),
        dataRegistro: DateTime.utc(2026, 10, 15),
        regra: r,
        adultos: 10,
        criancas: 0,
        bebes: 0,
        duracaoHoras: 4,
        disponibilizado: 2,
        sobra: .4,
        desperdicio: .1,
        faltou: false);
  }

  test(
      'salva simulação antes do consumo e salvamento comum preserva a observação',
      () async {
    await c.registrarConsumo(registro());
    expect(repo.chamadas, ['simulacao', 'consumo', 'listar']);
    expect(c.salvandoConsumo.value, isFalse);
    final observacoes = Map.from(repo.persistido['consumo_observado'] as Map);
    await repo.salvarSimulacao(
        calculo: c.calculoAtual.value!, itens: c.itensCalculados);
    expect(repo.persistido['consumo_observado'], observacoes);
    expect(c.itensCalculados.single.quantidade, 1.65);
  });
  test(
      'falha ao registrar é propagada, libera estado e não inventa consumo salvo',
      () async {
    repo.falhar = true;
    await expectLater(c.registrarConsumo(registro()), throwsStateError);
    expect(c.salvandoConsumo.value, isFalse);
    expect(repo.persistido['consumo_observado'], isEmpty);
    expect(repo.chamadas, ['simulacao', 'consumo']);
  });
  test('resultado contextual apresenta faixa de compra com a reserva atual',
      () {
    const service = ReferenciaPorcaoService();
    final ref = service.buscar('Arroz', 'acompanhamento').single;
    c.adicionarItemManual(service.aplicar(
        item: arrozObservado(),
        referencia: ref,
        porcao: .05,
        estadoDestino: 'cru'));
    expect(
        c.faixaDoResultado(c.itensCalculados.single), contains('0,55–0,66 kg'));
  });
}
