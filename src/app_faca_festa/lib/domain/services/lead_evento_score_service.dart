import 'package:app_faca_festa/domain/entities/evento_admin.dart';

/// Score comercial 0–100 com base em sinais do cadastro (sem depender de cotação).
class LeadEventoScoreService {
  const LeadEventoScoreService();

  int calcular(EventoAdmin evento, {DateTime? agora}) {
    final now = agora ?? DateTime.now();
    var score = 0;

    final data = evento.data;
    if (data != null) {
      score += 20;
      final dias = data.difference(now).inDays;
      if (dias >= 0 && dias <= 30) {
        score += 15;
      } else if (dias >= 0 && dias <= 90) {
        score += 10;
      } else if (dias > 540) {
        score -= 10;
      }
    }

    if (evento.totalConvidados > 0) {
      score += 15;
      if (evento.totalConvidados >= 50) {
        score += 10;
      } else if (evento.totalConvidados >= 30) {
        score += 5;
      }
    }

    if ((evento.cidade ?? '').trim().isNotEmpty) score += 15;
    if (evento.tipoNome.trim().isNotEmpty &&
        evento.tipoNome != 'Tipo não informado') {
      score += 10;
    }
    if (evento.custoEstimado != null && evento.custoEstimado! > 0) score += 10;
    if (evento.semCotacao && evento.emCurso) score += 15;
    if (evento.eventosDoOrganizador >= 2) score += 10;

    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  String faixaPrioridade(int score) {
    if (score >= 70) return 'Alta';
    if (score >= 45) return 'Média';
    return 'Baixa';
  }
}
