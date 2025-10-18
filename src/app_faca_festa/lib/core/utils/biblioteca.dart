import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Biblioteca {
  static final formatoDecimalValor = NumberFormat('#,##0.00', 'pt_BR');

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

  static String formatarValorDecimal(double? valor) {
    return formatoDecimalValor.format(valor ?? 0);
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

  /// define se a plataforma é desktop
  static bool isDesktop() {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// define se a plataforma é mobile
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
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

  static Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('t2ti.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
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
}
