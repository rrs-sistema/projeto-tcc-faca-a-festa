/// Explicit durability order; hooks allow tests without customer data.
class UpdatePreparation {
  const UpdatePreparation(
      {required this.stopSynchronization,
      required this.persistSettings,
      required this.flushPendingWrites,
      required this.closeDatabase});
  final Future<void> Function() stopSynchronization;
  final Future<void> Function() persistSettings;
  final Future<void> Function() flushPendingWrites;
  final Future<void> Function() closeDatabase;

  Future<void> run() async {
    await stopSynchronization();
    await persistSettings();
    await flushPendingWrites();
    await closeDatabase();
  }
}
