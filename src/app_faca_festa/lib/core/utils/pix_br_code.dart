import 'dart:convert';

/// Gera payload PIX estático (BR Code / EMV) conforme Manual do BCB.
///
/// Sem [valor] (ou valor <= 0): QR de **valor livre** — o app do banco
/// pede o montante ao pagador (tag 54 omitida).
/// Com [valor] > 0: inclui a tag 54 com o valor fixo.
class PixBrCode {
  PixBrCode._();

  static const String _guiPix = 'br.gov.bcb.pix';

  /// Monta o copia-e-cola / conteúdo do QR Code estático.
  static String gerar({
    required String chave,
    String? nomeRecebedor,
    String? cidade,
    double? valor,
    String? identificador,
    String? descricao,
  }) {
    final chaveLimpa = _normalizarChave(chave);
    if (chaveLimpa.isEmpty) {
      throw ArgumentError('Chave PIX obrigatória.');
    }

    final nome = _sanitizarCampo(nomeRecebedor ?? 'Presente', max: 25);
    final city = _sanitizarCampo(cidade ?? 'BRASIL', max: 15);
    final txid = _sanitizarTxid(identificador);
    final info = _sanitizarCampo(descricao ?? '', max: 72);

    final merchantAccount = StringBuffer()
      ..write(_tlv('00', _guiPix))
      ..write(_tlv('01', chaveLimpa));
    if (info.isNotEmpty) {
      merchantAccount.write(_tlv('02', info));
    }

    final payload = StringBuffer()
      ..write(_tlv('00', '01')) // Payload Format Indicator
      ..write(_tlv('26', merchantAccount.toString()))
      ..write(_tlv('52', '0000')) // MCC
      ..write(_tlv('53', '986')); // BRL

    if (valor != null && valor > 0) {
      payload.write(_tlv('54', valor.toStringAsFixed(2)));
    }

    payload
      ..write(_tlv('58', 'BR'))
      ..write(_tlv('59', nome))
      ..write(_tlv('60', city))
      ..write(_tlv('62', _tlv('05', txid)))
      ..write('6304');

    final crc = _crc16(payload.toString());
    return '${payload.toString()}$crc';
  }

  /// True quando o payload não carrega valor fixo (tag 54).
  static bool isValorLivre(String payload) {
    return !_contemTag(payload, '54');
  }

  static String _tlv(String id, String value) {
    final len = value.length.toString().padLeft(2, '0');
    return '$id$len$value';
  }

  static String _normalizarChave(String raw) {
    final chave = raw.trim();
    if (chave.isEmpty) return '';
    if (chave.contains('@')) {
      return chave.replaceAll(RegExp(r'\s+'), '');
    }

    final soDigitos = chave.replaceAll(RegExp(r'\D'), '');

    // Telefone explícito (+55…, (11) 9…, etc.) → E.164
    if (_pareceTelefone(chave, soDigitos)) {
      var digitos = soDigitos;
      if (digitos.startsWith('55') && digitos.length >= 12) {
        return '+$digitos';
      }
      if (digitos.length == 10 || digitos.length == 11) {
        return '+55$digitos';
      }
    }

    // 11 dígitos sem formatação de telefone → CPF
    if (RegExp(r'^\d{11}$').hasMatch(soDigitos)) {
      return soDigitos;
    }

    // 14 dígitos → CNPJ
    if (RegExp(r'^\d{14}$').hasMatch(soDigitos)) {
      return soDigitos;
    }

    // Chave aleatória / outros: sem espaços.
    return chave.replaceAll(RegExp(r'\s+'), '');
  }

  static bool _pareceTelefone(String chave, String digitos) {
    final t = chave.trim();
    if (RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(t)) return false;
    if (t.startsWith('+')) return digitos.length >= 10;
    // Formatação típica de telefone BR — evita confundir com CPF (11 dígitos).
    if (t.contains('(') || t.contains(')')) return digitos.length >= 10;
    if (RegExp(r'^\s*0?\d{2}\s*9?\d{4}[-\s]?\d{4}\s*$').hasMatch(t)) {
      return true;
    }
    if (digitos.startsWith('55') &&
        (digitos.length == 12 || digitos.length == 13) &&
        RegExp(r'^[\d\s\-()]+$').hasMatch(t)) {
      return true;
    }
    return false;
  }

  static String _sanitizarCampo(String value, {required int max}) {
    final semAcento = _removerAcentos(value.trim().toUpperCase());
    final limpo = semAcento.replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ');
    final compacto = limpo.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compacto.isEmpty) return max >= 7 ? 'BRASIL' : 'X';
    return compacto.length <= max ? compacto : compacto.substring(0, max);
  }

  static String _sanitizarTxid(String? value) {
    final raw = (value ?? '***').trim();
    if (raw.isEmpty || raw == '***') return '***';
    final limpo =
        raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (limpo.isEmpty) return '***';
    return limpo.length <= 25 ? limpo : limpo.substring(0, 25);
  }

  static String _removerAcentos(String input) {
    const mapa = {
      'Á': 'A',
      'À': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C',
      'Ñ': 'N',
      'á': 'A',
      'à': 'A',
      'â': 'A',
      'ã': 'A',
      'ä': 'A',
      'é': 'E',
      'è': 'E',
      'ê': 'E',
      'ë': 'E',
      'í': 'I',
      'ì': 'I',
      'î': 'I',
      'ï': 'I',
      'ó': 'O',
      'ò': 'O',
      'ô': 'O',
      'õ': 'O',
      'ö': 'O',
      'ú': 'U',
      'ù': 'U',
      'û': 'U',
      'ü': 'U',
      'ç': 'C',
      'ñ': 'N',
    };
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(mapa[ch] ?? ch);
    }
    return buffer.toString();
  }

  static bool _contemTag(String payload, String tag) {
    var i = 0;
    while (i + 4 <= payload.length) {
      final id = payload.substring(i, i + 2);
      final len = int.tryParse(payload.substring(i + 2, i + 4)) ?? -1;
      if (len < 0 || i + 4 + len > payload.length) return false;
      if (id == tag) return true;
      if (id == '63') return false;
      i += 4 + len;
    }
    return false;
  }

  /// CRC16-CCITT (poly 0x1021, init 0xFFFF) exigido pelo BR Code.
  static String _crc16(String data) {
    final bytes = utf8.encode(data);
    var crc = 0xFFFF;
    for (final b in bytes) {
      crc ^= (b << 8);
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
