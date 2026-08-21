import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriaIcones {
  static const Map<String, IconData> catalogo = {
    'category': Icons.category_rounded,
    'cake': Icons.cake_rounded,
    'bakery': Icons.bakery_dining_rounded,
    'restaurant': Icons.restaurant_rounded,
    'restaurant_menu': Icons.restaurant_menu_rounded,
    'local_bar': Icons.local_bar_rounded,
    'wine_bar': Icons.wine_bar_rounded,
    'liquor': Icons.liquor_rounded,
    'icecream': Icons.icecream_rounded,
    'coffee': Icons.coffee_rounded,
    'outdoor_grill': Icons.outdoor_grill_rounded,
    'music': Icons.music_note_rounded,
    'mic': Icons.mic_rounded,
    'speaker': Icons.speaker_rounded,
    'queue_music': Icons.queue_music_rounded,
    'photo': Icons.photo_camera_rounded,
    'videocam': Icons.videocam_rounded,
    'photo_album': Icons.photo_album_rounded,
    'flight': Icons.flight_rounded,
    'florist': Icons.local_florist_rounded,
    'celebration': Icons.celebration_rounded,
    'festival': Icons.festival_rounded,
    'checkroom': Icons.checkroom_rounded,
    'dry_cleaning': Icons.dry_cleaning_rounded,
    'diamond': Icons.diamond_rounded,
    'spa': Icons.spa_rounded,
    'content_cut': Icons.content_cut_rounded,
    'face': Icons.face_rounded,
    'brush': Icons.brush_rounded,
    'directions_car': Icons.directions_car_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'airport_shuttle': Icons.airport_shuttle_rounded,
    'local_taxi': Icons.local_taxi_rounded,
    'storefront': Icons.storefront_rounded,
    'business': Icons.business_center_rounded,
    'theater': Icons.theater_comedy_rounded,
    'sports': Icons.sports_esports_rounded,
    'toys': Icons.toys_rounded,
    'child_care': Icons.child_care_rounded,
    'attractions': Icons.attractions_rounded,
    'palette': Icons.palette_rounded,
    'chair': Icons.chair_rounded,
    'weekend': Icons.weekend_rounded,
    'villa': Icons.villa_rounded,
    'cottage': Icons.cottage_rounded,
    'apartment': Icons.apartment_rounded,
    'light': Icons.lightbulb_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'print': Icons.print_rounded,
    'mail': Icons.mail_rounded,
    'support_agent': Icons.support_agent_rounded,
    'groups': Icons.groups_rounded,
    'record_voice': Icons.record_voice_over_rounded,
    'security': Icons.security_rounded,
    'shield': Icons.health_and_safety_rounded,
    'room_service': Icons.room_service_rounded,
    'cleaning': Icons.cleaning_services_rounded,
    'local_parking': Icons.local_parking_rounded,
    'ac_unit': Icons.ac_unit_rounded,
    'kitchen': Icons.kitchen_rounded,
    'nightlife': Icons.nightlife_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
  };

  static IconData de(String? chave) => catalogo[chave] ?? Icons.category_rounded;
}

class CategoriaServicoModel {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int ordem;
  final String icone;
  final DateTime? dataCadastro;
  final DateTime? dataAtualizacao;

  CategoriaServicoModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.ordem = 0,
    this.icone = 'category',
    this.dataCadastro,
    this.dataAtualizacao,
  });

  IconData get iconData => CategoriaIcones.de(icone);

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
        'ordem': ordem,
        'icone': icone,
        'data_cadastro': dataCadastro != null
            ? Timestamp.fromDate(dataCadastro!)
            : FieldValue.serverTimestamp(),
        'data_atualizacao': FieldValue.serverTimestamp(),
      };

  factory CategoriaServicoModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CategoriaServicoModel(
      id: _texto(map, ['id'], fallback: documentId ?? ''),
      nome: _texto(map, ['nome', 'name']),
      descricao: _textoOpcional(map, ['descricao', 'description']),
      ativo: _bool(map, ['ativo', 'active'], fallback: true),
      ordem: _int(map, ['ordem', 'order']),
      icone: _texto(map, ['icone', 'icon'], fallback: 'category'),
      dataCadastro: _data(map, ['data_cadastro', 'dataCadastro']),
      dataAtualizacao: _data(map, ['data_atualizacao', 'dataAtualizacao']),
    );
  }

  CategoriaServicoModel copyWith({
    String? nome,
    String? descricao,
    bool? ativo,
    int? ordem,
    String? icone,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
  }) {
    return CategoriaServicoModel(
      id: id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      icone: icone ?? this.icone,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}

String _texto(Map<String, dynamic> map, List<String> keys, {String fallback = ''}) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

String? _textoOpcional(Map<String, dynamic> map, List<String> keys) {
  final value = _texto(map, keys);
  return value.isEmpty ? null : value;
}

bool _bool(Map<String, dynamic> map, List<String> keys, {bool fallback = false}) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final n = value.trim().toLowerCase();
      if (['true', '1', 's', 'sim'].contains(n)) return true;
      if (['false', '0', 'n', 'nao', 'não'].contains(n)) return false;
    }
  }
  return fallback;
}

int _int(Map<String, dynamic> map, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

DateTime? _data(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
  }
  return null;
}
