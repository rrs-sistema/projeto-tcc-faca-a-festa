import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class Biblioteca {
  static final _formatoDecimalValor = NumberFormat('#,##0.00', 'pt_BR');
  static final _formatoValorSemDecimal = NumberFormat('#,##0', 'pt_BR');

  /// singleton
  factory Biblioteca() {
    _this ??= Biblioteca._();
    return _this!;
  }
  static Biblioteca? _this;
  Biblioteca._() : super();

  /// remove a máscara de uma string
  /// útil para campos do tipo: CPF, CNPJ, CEP, etc
  static String? removerMascara(dynamic value) {
    if (value != null) {
      return value.replaceAll(RegExp(r'[^\w\s]+'), '');
    } else {
      return null;
    }
  }

  static String formatarHora(DateTime hora) {
    var formatter = DateFormat('Hms');
    String horaFormatada = formatter.format(hora);
    return horaFormatada;
  }

  static String formatarDataAmericano(DateTime? data) {
    if (data == null) {
      return '';
    } else {
      var formatter = DateFormat('yyyy-MM-dd');
      String dataFormatada = formatter.format(data);
      return "'$dataFormatada'";
    }
  }

  static String formatarData(DateTime? data) {
    if (data == null) {
      return '';
    } else {
      var formatter = DateFormat('dd/MM/yyyy');
      String dataFormatada = formatter.format(data);
      return dataFormatada;
    }
  }

  static String formatarDataHora(DateTime? data) {
    if (data == null) {
      return '';
    } else {
      var formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
      String dataHoraFormatada = formatter.format(data);
      return dataHoraFormatada;
    }
  }

  static String formatarDataAAAAMM(DateTime? data) {
    if (data == null) {
      return '';
    } else {
      var formatter = DateFormat('yyyyMM');
      String dataHoraFormatada = formatter.format(data);
      return dataHoraFormatada;
    }
  }

  static String formatarDataAAMM(DateTime? data) {
    if (data == null) {
      return '';
    } else {
      var formatter = DateFormat('yyMM');
      String dataHoraFormatada = formatter.format(data);
      return dataHoraFormatada;
    }
  }

  static String formatarMes(DateTime data) {
    var formatter = DateFormat('MM');
    String mesFormatado = formatter.format(data);
    return mesFormatado;
  }

  static String formatarMesAno(DateTime data) {
    var formatter = DateFormat('MM/yyyy');
    String mesFormatado = formatter.format(data);
    return mesFormatado;
  }

  static double toDouble(String value) {
    return double.tryParse(
          value.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim(),
        ) ??
        0.0;
  }

  static String formatarPrecoGrid(double preco, double? promocao) {
    final valor = (promocao != null && promocao > 0.0) ? promocao : preco;
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String formatarValorDecimal(double? valor) {
    return _formatoDecimalValor.format(valor ?? 0);
  }

  static String formatoValorSemDecimal(double? valor) {
    return _formatoValorSemDecimal.format(valor ?? 0);
  }

  static DateTime converteDataInicioParaFiltro(DateTime data) {
    return DateTime(data.year, data.month, data.day, 0, 0, 0, 0, 0); // zera o tempo
  }

  static DateTime converteDataFimParaFiltro(DateTime data) {
    return DateTime(data.year, data.month, data.day, 23, 59, 59, 0, 0); // adiciona o tempo
  }

  static DateTime? removerTempoDaData(DateTime? data) {
    if (data != null) {
      return DateTime(data.year, data.month, data.day, 0, 0, 0, 0, 0); // zera o tempo
    } else {
      return data;
    }
  }

  static bool isDesktop() {
    if (kIsWeb) return false;
    return [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ].contains(defaultTargetPlatform);
  }

  static bool isMobile() {
    if (kIsWeb) return false;
    return [
      TargetPlatform.iOS,
      TargetPlatform.android,
    ].contains(defaultTargetPlatform);
  }

  /// Verifica se é um celular
  static bool isCelular(BuildContext context) {
    if (isDesktop()) return false; // 💻 nunca será celular
    if (isTablet(context)) return false; // já coberto
    return true; // caso contrário, é celular
  }

  /// Verifica se é um tablet combinando dp e polegadas
  static bool isTablet(BuildContext context) {
    if (isDesktop()) return false; // 💻 nunca será tablet

    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;

    // Critério principal (Material Design)
    if (shortestSide >= 600) return true;

    // Critério secundário para casos limítrofes
    if (shortestSide >= 550 && shortestSide < 650) {
      final diagonalInInches = _calculateScreenDiagonalInInches(
        mediaQuery.size.width,
        mediaQuery.size.height,
        mediaQuery.devicePixelRatio,
      );
      return diagonalInInches >= 7.0;
    }

    return false;
  }

  static String formatarCelular(String? celular) {
    if (celular == null || celular.isEmpty) return '';
    final digits = celular.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return celular;
  }

  static String formatarCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '';

    // Remove tudo que não for número
    final digits = cpf.replaceAll(RegExp(r'\D'), '');

    // CPF deve ter 11 dígitos
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.'
          '${digits.substring(3, 6)}.'
          '${digits.substring(6, 9)}-'
          '${digits.substring(9, 11)}';
    }

    // Se não tiver 11 dígitos, retorna original (útil para debug ou valores incompletos)
    return cpf;
  }

  static String formatarCnpj(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) return '';

    // remove tudo que não for número
    final digits = cnpj.replaceAll(RegExp(r'\D'), '');

    // CNPJ válido → 14 dígitos
    if (digits.length == 14) {
      return '${digits.substring(0, 2)}.'
          '${digits.substring(2, 5)}.'
          '${digits.substring(5, 8)}/'
          '${digits.substring(8, 12)}-'
          '${digits.substring(12, 14)}';
    }

    // CPF válido → 11 dígitos (opcional, se quiser reaproveitar a função)
    else if (digits.length == 11) {
      return '${digits.substring(0, 3)}.'
          '${digits.substring(3, 6)}.'
          '${digits.substring(6, 9)}-'
          '${digits.substring(9, 11)}';
    }

    // Caso não tenha formato reconhecido, retorna o original
    return cnpj;
  }

  /// Calcula a diagonal em polegadas
  static double _calculateScreenDiagonalInInches(
    double widthPx,
    double heightPx,
    double pixelRatio,
  ) {
    final widthDp = widthPx / pixelRatio;
    final heightDp = heightPx / pixelRatio;
    final widthInches = widthDp / 160;
    final heightInches = heightDp / 160;
    return sqrt(pow(widthInches, 2) + pow(heightInches, 2));
  }

  static Color gerarCorPorChaves(List<String> chaves) {
    // Junta tudo em uma única string
    final combinado = chaves.join('-').toLowerCase();

    int hash = combinado.codeUnits.fold(0, (prev, elem) => (prev * 37 + elem) % 360);

    final hslColor = HSLColor.fromAHSL(
      1.0,
      hash.toDouble(),
      0.55,
      0.55,
    );

    return hslColor.toColor();
  }

  static IconData iconePorCategoria(String? nome) {
    final lower = nome?.toLowerCase() ?? '';

    if (lower.contains('buffet') || lower.contains('gastronomia') || lower.contains('culinária')) {
      return FontAwesomeIcons.utensils;
    } else if (lower.contains('decoração') ||
        lower.contains('flores') ||
        lower.contains('ambientação')) {
      return FontAwesomeIcons.palette;
    } else if (lower.contains('música') ||
        lower.contains('dj') ||
        lower.contains('som') ||
        lower.contains('banda')) {
      return FontAwesomeIcons.music;
    } else if (lower.contains('fotografia') ||
        lower.contains('foto') ||
        lower.contains('vídeo') ||
        lower.contains('filmagem')) {
      return FontAwesomeIcons.cameraRetro;
    } else if (lower.contains('espaço') ||
        lower.contains('local') ||
        lower.contains('salão') ||
        lower.contains('chácara')) {
      return FontAwesomeIcons.building;
    } else if (lower.contains('convite') ||
        lower.contains('papelaria') ||
        lower.contains('lembrança')) {
      return FontAwesomeIcons.envelopeOpenText;
    } else if (lower.contains('transporte') ||
        lower.contains('carro') ||
        lower.contains('limousine')) {
      return FontAwesomeIcons.carSide;
    } else if (lower.contains('bebida') || lower.contains('bar') || lower.contains('coquetel')) {
      return FontAwesomeIcons.champagneGlasses;
    } else if (lower.contains('bolo') || lower.contains('doce') || lower.contains('confeitaria')) {
      return FontAwesomeIcons.cakeCandles;
    } else if (lower.contains('segurança') ||
        lower.contains('porteiro') ||
        lower.contains('vigia')) {
      return FontAwesomeIcons.shieldHalved;
    } else if (lower.contains('cabelo') ||
        lower.contains('maquiagem') ||
        lower.contains('beleza') ||
        lower.contains('salão')) {
      return FontAwesomeIcons.spa; // salão de beleza
    } else if (lower.contains('cerimonial') ||
        lower.contains('assessoria') ||
        lower.contains('organização')) {
      return FontAwesomeIcons.calendarCheck;
    } else if (lower.contains('iluminação') ||
        lower.contains('efeito') ||
        lower.contains('painel')) {
      return FontAwesomeIcons.lightbulb;
    } else if (lower.contains('terno') ||
        lower.contains('vestido') ||
        lower.contains('roupa') ||
        lower.contains('moda')) {
      return FontAwesomeIcons.personDress;
    } else if (lower.contains('igreja') ||
        lower.contains('cerimônia') ||
        lower.contains('pastor')) {
      return FontAwesomeIcons.church;
    } else if (lower.contains('infantil') ||
        lower.contains('brinquedo') ||
        lower.contains('animação')) {
      return FontAwesomeIcons.children;
    } else if (lower.contains('foto cabine') || lower.contains('cabine')) {
      return FontAwesomeIcons.camera;
    } else if (lower.contains('viagem') ||
        lower.contains('lua de mel') ||
        lower.contains('turismo')) {
      return FontAwesomeIcons.planeDeparture;
    } else if (lower.contains('joia') || lower.contains('aliança') || lower.contains('bijuteria')) {
      return FontAwesomeIcons.ring;
    } else if (lower.contains('pet') || lower.contains('animal') || lower.contains('mascote')) {
      return FontAwesomeIcons.paw;
    }
    return FontAwesomeIcons.clipboardList; // padrão genérico
  }

  static Color corPorCategoria(String? nome) {
    final lower = nome?.toLowerCase() ?? '';

    if (lower.contains('buffet')) return Colors.deepOrange;
    if (lower.contains('decoração')) return Colors.pinkAccent;
    if (lower.contains('música')) return Colors.purple;
    if (lower.contains('fotografia')) return Colors.indigo;
    if (lower.contains('espaço')) return Colors.teal;
    if (lower.contains('convite')) return Colors.blueGrey;
    if (lower.contains('transporte')) return Colors.blue;
    if (lower.contains('bebida')) return Colors.brown;
    if (lower.contains('bolo')) return Colors.amber.shade800;
    if (lower.contains('segurança')) return Colors.green.shade700;
    if (lower.contains('cabelo') || lower.contains('maquiagem') || lower.contains('beleza')) {
      return Colors.pink.shade400;
    }
    if (lower.contains('cerimonial')) return Colors.deepPurpleAccent;
    if (lower.contains('iluminação')) return Colors.yellow.shade700;
    if (lower.contains('terno') || lower.contains('vestido')) return Colors.cyan.shade600;
    if (lower.contains('igreja') || lower.contains('cerimônia')) return Colors.redAccent;
    if (lower.contains('infantil')) return Colors.lightBlueAccent;
    if (lower.contains('viagem') || lower.contains('lua de mel')) return Colors.orangeAccent;
    if (lower.contains('joia')) return Colors.amber;
    if (lower.contains('pet')) return Colors.lightGreen;

    return Colors.grey.shade700;
  }
}
