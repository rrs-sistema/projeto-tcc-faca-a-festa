#include <windows.h>
#include <shellapi.h>
#include "update_file.h"

#ifdef FACA_FESTA_HELPER_TEST
constexpr DWORD kParentDeadline = 2500;
constexpr DWORD kInstallerDeadline = 1500;
#else
constexpr DWORD kParentDeadline = 60000;
constexpr DWORD kInstallerDeadline = 600000;
#endif
void ReportUpdateFailure(const wchar_t* message) {
#ifndef FACA_FESTA_HELPER_TEST
  MessageBoxW(nullptr, message, L"Atualização do Faça a Festa", MB_OK | MB_ICONWARNING | MB_TOPMOST);
#else
  (void)message;
#endif
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
  int count = 0;
  auto args = CommandLineToArgvW(GetCommandLineW(), &count);
  // Verificação isolada para diagnóstico/testes, sem abrir instaladores.
  if (args && count == 4 && std::wstring(args[1]) == L"--verify") {
    HANDLE file = CreateFileW(args[2], GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    const bool valid = file != INVALID_HANDLE_VALUE && UpdateHash(file) == args[3];
    if (file != INVALID_HANDLE_VALUE) CloseHandle(file);
    LocalFree(args);
    return valid ? 0 : 1;
  }
  if (!args || count != 5) { if (args) LocalFree(args); return 1; }
  const std::wstring installer = args[1], app = args[3], expected = args[4];
  const auto directory = app.substr(0, app.find_last_of(L"\\"));
  const DWORD pid = wcstoul(args[2], nullptr, 10);
  LocalFree(args);
  if (!pid || expected.size() != 64) return 2;
  HANDLE parent = OpenProcess(SYNCHRONIZE, FALSE, pid);
  if (parent) {
    auto wait = WaitForSingleObject(parent, kParentDeadline);
    CloseHandle(parent);
    if (wait != WAIT_OBJECT_0) {
      ReportUpdateFailure(L"O Faça a Festa não encerrou no prazo. A instalação não foi iniciada. Feche e reabra o aplicativo antes de tentar novamente.");
      return 3;
    }
  } else if (GetLastError() != ERROR_INVALID_PARAMETER) return 3;
  HANDLE file = CreateFileW(installer.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  bool verified = file != INVALID_HANDLE_VALUE && UpdateHash(file) == expected;
  DWORD exit_code = 1;
  if (verified) {
    SHELLEXECUTEINFOW execute{}; execute.cbSize = sizeof(execute);
    execute.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC;
    execute.lpVerb = L"open"; execute.lpFile = installer.c_str();
    const auto parameters = L"/SILENT /NORESTART /NOCLOSEAPPLICATIONS /NOFORCECLOSEAPPLICATIONS /SUPPRESSMSGBOXES /DIR=" + QuoteUpdatePath(directory);
    execute.lpParameters = parameters.c_str();
    execute.nShow = SW_SHOWNORMAL;
    if (ShellExecuteExW(&execute) && execute.hProcess) {
      CloseHandle(file); file = INVALID_HANDLE_VALUE;
      if (WaitForSingleObject(execute.hProcess, kInstallerDeadline) != WAIT_OBJECT_0) {
        CloseHandle(execute.hProcess);
        ReportUpdateFailure(L"O instalador não terminou em 10 minutos. Conclua ou cancele a instalação antes de reabrir o Faça a Festa.");
        return 4;
      }
      GetExitCodeProcess(execute.hProcess, &exit_code);
      CloseHandle(execute.hProcess);
    }
  }
  if (file != INVALID_HANDLE_VALUE) CloseHandle(file);
  if (!verified) ReportUpdateFailure(L"O pacote mudou após o download. A instalação foi rejeitada. Baixe novamente pelo aplicativo.");
  else if (exit_code != 0) ReportUpdateFailure(L"O instalador falhou ou foi cancelado. O aplicativo será reaberto; verifique a versão instalada antes de tentar novamente.");
  // Reabre inclusive quando a elevação é cancelada ou a instalação falha.
  SHELLEXECUTEINFOW restart{}; restart.cbSize = sizeof(restart);
  restart.lpFile = app.c_str(); restart.nShow = SW_SHOWNORMAL;
  restart.lpDirectory = directory.c_str();
  if (!ShellExecuteExW(&restart)) {
    ReportUpdateFailure(L"Não foi possível reabrir o Faça a Festa. Abra pelo atalho após concluir a instalação.");
    return 5;
  }
  if (exit_code == 0) DeleteFileW(installer.c_str());
  return static_cast<int>(exit_code);
}

