import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/data/services/lgpd/lgpd_functions_client.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/widgets/admin/admin_kit.dart';

class SolicitacaoLgpd {
  const SolicitacaoLgpd({
    required this.id,
    required this.idUsuario,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.resumo,
    required this.status,
    required this.resultado,
    this.criadoEm,
    required this.arquivada,
  });

  final String id;
  final String idUsuario;
  final String nome;
  final String email;
  final String tipo;
  final String resumo;
  final String status;
  final String resultado;
  final DateTime? criadoEm;
  final bool arquivada;
}

class SolicitacoesLgpdAdminScreen extends StatefulWidget {
  const SolicitacoesLgpdAdminScreen({super.key});

  @override
  State<SolicitacoesLgpdAdminScreen> createState() =>
      _SolicitacoesLgpdAdminScreenState();
}

class _SolicitacoesLgpdAdminScreenState extends State<SolicitacoesLgpdAdminScreen> {
  final _busca = TextEditingController();
  var _carregando = true;
  var _atendendo = false;
  String? _erro;
  List<SolicitacaoLgpd> _itens = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final firestore = Get.find<FirebaseFirestore>();
      final abertas = await firestore.collectionGroup('solicitacoes_lgpd').limit(200).get();
      final arquivo = await firestore.collection('lgpd_protocolos').limit(200).get();
      final porId = <String, SolicitacaoLgpd>{};
      for (final doc in abertas.docs) {
        porId[doc.id] = _deDoc(doc, arquivada: false);
      }
      for (final doc in arquivo.docs) {
        porId[doc.id] = _deDoc(doc, arquivada: true);
      }
      final lista = porId.values.toList()
        ..sort((a, b) {
          final da = a.criadoEm ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.criadoEm ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os protocolos.';
        _carregando = false;
      });
    }
  }

  SolicitacaoLgpd _deDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool arquivada}) {
    final data = doc.data();
    final pai = doc.reference.parent.parent?.id ?? '';
    return SolicitacaoLgpd(
      id: doc.id,
      idUsuario: (data['id_usuario'] ?? pai).toString(),
      nome: (data['nome_titular'] ?? '').toString(),
      email: (data['email_titular'] ?? '').toString(),
      tipo: (data['tipo'] ?? '').toString(),
      resumo: (data['resumo'] ?? '').toString(),
      status: (data['status'] ?? 'registrada').toString(),
      resultado: (data['resultado'] ?? '').toString(),
      criadoEm: _data(data['criado_em']),
      arquivada: arquivada,
    );
  }

  DateTime? _data(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return null;
  }

  List<SolicitacaoLgpd> get _filtrados {
    final termo = _busca.text.trim().toLowerCase();
    if (termo.isEmpty) return _itens;
    return _itens.where((item) {
      return item.id.toLowerCase().contains(termo) ||
          item.nome.toLowerCase().contains(termo) ||
          item.email.toLowerCase().contains(termo) ||
          item.tipo.toLowerCase().contains(termo) ||
          item.status.toLowerCase().contains(termo);
    }).toList();
  }

  Future<void> _atender(SolicitacaoLgpd item, String acao) async {
    if (_atendendo) return;
    if (acao == 'executar_exclusao') {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Executar exclusão'),
          content: Text(
            'Isso apaga a conta de ${item.email.isEmpty ? item.idUsuario : item.email}, os eventos, convidados e a autenticação. O protocolo ${item.id} permanece no arquivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Apagar conta'),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _atendendo = true);
    EasyLoading.show(status: 'Atualizando protocolo...');
    try {
      final resultado = await LgpdFunctionsClient().atender(
        idUsuario: item.idUsuario,
        idSolicitacao: item.id,
        acao: acao,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado)));
      await _carregar();
    } on LgpdFunctionsException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro.message)));
    } finally {
      await EasyLoading.dismiss();
      if (mounted) setState(() => _atendendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm');
    final lista = _filtrados;

    return Scaffold(
      backgroundColor: AdminPalette.surface,
      appBar: const AdminBackAppBar(
        title: 'Protocolos LGPD',
        subtitle: 'Pedidos do titular',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: AdminSearchField(
              controller: _busca,
              hint: 'Protocolo, nome, e-mail ou tipo',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? AdminEmptyState(
                        icon: Icons.error_outline,
                        title: 'Falha ao carregar',
                        message: _erro!,
                      )
                    : lista.isEmpty
                        ? const AdminEmptyState(
                            icon: Icons.folder_open_rounded,
                            title: 'Nenhum protocolo',
                            message: 'Os pedidos feitos em Dados protegidos aparecem aqui.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            itemCount: lista.length,
                            itemBuilder: (context, index) {
                              final item = lista[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_rotuloTipo(item.tipo)} · ${_rotuloStatus(item.status)}',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.nome.isEmpty ? item.email : '${item.nome} · ${item.email}',
                                        style: GoogleFonts.poppins(fontSize: 13),
                                      ),
                                      Text(
                                        'Protocolo ${item.id}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                                      ),
                                      if (item.criadoEm != null)
                                        Text(
                                          dataFmt.format(item.criadoEm!.toLocal()),
                                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                                        ),
                                      if (item.resumo.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(item.resumo, style: GoogleFonts.poppins(fontSize: 13, height: 1.35)),
                                      ],
                                      if (item.resultado.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(item.resultado, style: GoogleFonts.poppins(fontSize: 12.5, height: 1.35)),
                                      ],
                                      if (!item.arquivada && item.status != 'concluida' && item.status != 'recusada')
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            TextButton(
                                              onPressed: _atendendo ? null : () => _atender(item, 'em_atendimento'),
                                              child: const Text('Em atendimento'),
                                            ),
                                            if (item.tipo == 'exclusao')
                                              TextButton(
                                                onPressed: _atendendo ? null : () => _atender(item, 'executar_exclusao'),
                                                child: const Text('Executar exclusão'),
                                              )
                                            else
                                              TextButton(
                                                onPressed: _atendendo ? null : () => _atender(item, 'concluir'),
                                                child: const Text('Concluir'),
                                              ),
                                            TextButton(
                                              onPressed: _atendendo ? null : () => _atender(item, 'recusar'),
                                              child: const Text('Recusar'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _rotuloTipo(String tipo) {
    switch (tipo) {
      case 'acesso':
        return 'Acesso';
      case 'correcao':
        return 'Correção';
      case 'exclusao':
        return 'Exclusão';
      case 'anonimizacao':
        return 'Anonimização';
      case 'oposicao':
        return 'Oposição';
      case 'revogacao':
        return 'Revogação';
      default:
        return tipo.isEmpty ? 'Pedido' : tipo;
    }
  }

  String _rotuloStatus(String status) {
    switch (status) {
      case 'registrada':
        return 'Registrada';
      case 'em_atendimento':
        return 'Em atendimento';
      case 'concluida':
        return 'Concluída';
      case 'recusada':
        return 'Recusada';
      default:
        return status;
    }
  }
}
