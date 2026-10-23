abstract class FinanceiroEventoRepository {
  Stream<List<Map<String, dynamic>>> observarFinanceiroEvento(String evento);
}
