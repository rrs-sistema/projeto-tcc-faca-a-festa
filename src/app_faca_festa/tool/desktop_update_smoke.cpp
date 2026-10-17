// Exercita o WinSparkle real sem executar instaladores nem encerrar aplicativos.
#include <winsparkle.h>
#include <windows.h>
#include <atomic>
#include <iostream>
#include "../windows/runner/updater_public_key.h"
#include "../windows/runner/update_file.h"

namespace {
HANDLE done;
std::wstring expected;
std::atomic<int> outcome{9};
std::atomic<bool> captured{false};
int __cdecl Capture(const wchar_t* path) {
  captured = true;
  HANDLE file = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  const bool valid = file != INVALID_HANDLE_VALUE && UpdateHash(file) == expected;
  if (file != INVALID_HANDLE_VALUE) CloseHandle(file);
  outcome = valid ? 0 : 4;
  return valid ? 1 : -1;
}
void __cdecl Ready() { SetEvent(done); }
void __cdecl Error() { outcome = 1; SetEvent(done); }
void __cdecl NoUpdate() { outcome = 3; SetEvent(done); }
}
int wmain(int count, wchar_t* args[]) {
  if (count != 4) return 5;
  const std::wstring wide_url = args[1];
  std::string url;
  for (auto ch : wide_url) { if (ch > 127) return 5; url += static_cast<char>(ch); }
  expected = args[3];
  done = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  win_sparkle_set_registry_path("Software\\RRS System Technology\\FacaFestaUpdaterSmoke");
  win_sparkle_set_app_details(L"RRS System Technology", L"Teste do atualizador Faça a Festa", L"0.0.0");
  win_sparkle_set_app_build_version(args[2]);
  win_sparkle_set_appcast_url(url.c_str());
  if (!win_sparkle_set_eddsa_public_key(kUpdaterPublicKey)) return 6;
  win_sparkle_set_automatic_check_for_updates(0);
  win_sparkle_set_user_run_installer_callback(Capture);
  win_sparkle_set_shutdown_request_callback(Ready);
  win_sparkle_set_error_callback(Error);
  win_sparkle_set_did_not_find_update_callback(NoUpdate);
  win_sparkle_init();
  win_sparkle_check_update_with_ui_and_install();
  if (WaitForSingleObject(done, 90000) != WAIT_OBJECT_0) outcome = 8;
  win_sparkle_cleanup();
  CloseHandle(done);
  std::cout << "{\"outcome\":" << outcome.load() << ",\"installerCallback\":" << (captured.load() ? "true" : "false") << "}" << std::endl;
  return outcome;
}

