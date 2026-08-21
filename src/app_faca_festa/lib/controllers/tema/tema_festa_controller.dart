import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/evento/tema_festa_model.dart';
import '../../data/seeds/tema_festa_seed.dart';
import '../../data/services/functions/callable_https_client.dart';
import '../../domain/usecases/gerenciar_temas_festa.dart';
import 'event_theme_controller.dart';

class TemaFestaController extends GetxController {
  TemaFestaController({
    required GerenciarTemasFesta temasFesta,
  }) : _temasFesta = temasFesta;

  final GerenciarTemasFesta _temasFesta;

  final temas = <TemaFestaModel>[].obs;
  final carregando = false.obs;
  final salvando = false.obs;
  final erro = ''.obs;
  final busca = ''.obs;
  final filtroCategoria = 'todos'.obs;

  List<TemaFestaModel> get temasAtivos {
    final lista = temas.where((tema) => tema.ativo).toList();
    lista.sort((a, b) => a.ordem.compareTo(b.ordem));
    return lista;
  }

  List<TemaFestaModel> get temasFiltrados {
    final termo = busca.value.trim().toLowerCase();
    final categoria = filtroCategoria.value;
    return temas.where((tema) {
      if (categoria != 'todos' && tema.categoria != categoria) return false;
      if (termo.isEmpty) return true;
      final tipos =
          tema.tiposEvento.map(TemaFestaTipos.rotulo).join(' ').toLowerCase();
      return tema.nome.toLowerCase().contains(termo) ||
          (tema.descricao ?? '').toLowerCase().contains(termo) ||
          tipos.contains(termo);
    }).toList();
  }

  List<TemaFestaModel> temasParaTipo(String? nomeTipoEvento) {
    return temasAtivos.where((tema) {
      if (tema.compativelComTipo(nomeTipoEvento)) return true;
      final seed = temasFestaIniciais
          .firstWhereOrNull((item) => item.idTema == tema.idTema);
      return seed?.compativelComTipo(nomeTipoEvento) == true;
    }).toList();
  }

  Future<void> carregar({bool popularSeVazio = false}) async {
    try {
      carregando.value = true;
      erro.value = '';
      final lista = await _temasFesta.carregar();
      temas.assignAll(lista);

      if (popularSeVazio && lista.isEmpty) {
        await popularTemasIniciais();
      }
    } catch (e, s) {
      erro.value = e.toString();
      debugPrint('[TemaFestaController] Erro ao carregar: $e\n$s');
    } finally {
      carregando.value = false;
    }
  }

  Future<TemaFestaModel?> buscarPorId(String idTema) async {
    final id = idTema.trim();
    if (id.isEmpty) return null;
    final local = temas.firstWhereOrNull((tema) => tema.idTema == id);
    if (local != null) return local;
    try {
      return _temasFesta.buscarPorId(id);
    } catch (e, s) {
      debugPrint('[TemaFestaController] Erro ao buscar $id: $e\n$s');
      return null;
    }
  }

  Future<void> salvar(TemaFestaModel tema) async {
    salvando.value = true;
    try {
      await _temasFesta.salvar(tema);
      final index = temas.indexWhere((item) => item.idTema == tema.idTema);
      if (index >= 0) {
        temas[index] = tema;
      } else {
        temas.add(tema);
      }
      temas.sort((a, b) => a.ordem.compareTo(b.ordem));
      temas.refresh();
      if (Get.isRegistered<EventThemeController>()) {
        Get.find<EventThemeController>().atualizarCacheTema(tema);
      }
    } finally {
      salvando.value = false;
    }
  }

  Future<void> excluir(String idTema) async {
    final atual = temas.firstWhereOrNull((tema) => tema.idTema == idTema);
    if ((atual?.imagemCapaUrl ?? '').trim().isNotEmpty) {
      await removerCapaStorage(idTema: idTema);
    }
    await _temasFesta.excluir(idTema);
    temas.removeWhere((tema) => tema.idTema == idTema);
  }

  Future<XFile?> escolherCapa() async {
    try {
      final picker = ImagePicker();
      return picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );
    } catch (e, s) {
      debugPrint('[TemaFestaController] Erro ao escolher capa: $e\n$s');
      EasyLoading.showError('Não foi possível selecionar a imagem.');
      return null;
    }
  }

  Future<String?> enviarCapa({
    required String idTema,
    required Uint8List bytes,
  }) async {
    final id = idTema.trim();
    if (id.isEmpty || bytes.isEmpty) return null;
    try {
      EasyLoading.show(status: 'Enviando capa...');
      final url = await _temasFesta.enviarCapa(idTema: id, bytes: bytes);
      if ((url ?? '').isEmpty) {
        EasyLoading.showError('Não foi possível enviar a capa.');
        return null;
      }
      return url;
    } on CallableHttpsException catch (e, s) {
      debugPrint('[TemaFestaController] Erro ao enviar capa: $e\n$s');
      EasyLoading.showError(
        e.code == 'permission-denied'
            ? 'Apenas o administrador pode alterar a capa.'
            : 'Não foi possível enviar a capa.',
      );
      return null;
    } catch (e, s) {
      debugPrint('[TemaFestaController] Erro ao enviar capa: $e\n$s');
      EasyLoading.showError('Não foi possível enviar a capa.');
      return null;
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> removerCapaStorage({String? idTema}) async {
    final id = (idTema ?? '').trim();
    if (id.isEmpty) return;
    try {
      await _temasFesta.removerCapaStorage(idTema: id);
    } catch (e, s) {
      debugPrint('[TemaFestaController] Capa já ausente no Storage: $e\n$s');
    }
  }

  Future<void> popularTemasIniciais() async {
    await _temasFesta.popularTemasIniciais(
      temasIniciais: temasFestaIniciais,
      temasExistentes: temas,
    );
    await carregar();
  }
}
