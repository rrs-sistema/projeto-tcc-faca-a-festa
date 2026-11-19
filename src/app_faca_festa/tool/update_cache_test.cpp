// Usa somente uma cópia deste executável de teste; não executa instaladores.
#include "../windows/runner/update_cache.h"
#include <iostream>

int wmain() {
  wchar_t executable[MAX_PATH], temporary[MAX_PATH], name[MAX_PATH];
  if (!GetModuleFileNameW(nullptr, executable, MAX_PATH) ||
      !GetTempPathW(MAX_PATH, temporary) ||
      !GetTempFileNameW(temporary, L"ffc", 0, name)) return 1;
  const std::wstring path = name;
  if (!CopyFileW(executable, path.c_str(), FALSE)) return 2;
  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) return 3;
  const auto hash = UpdateHash(file);
  CloseHandle(file);
  bool valid = ReadCachedUpdate(path, 42, hash).version == "1.2.3";
  // Outra abertura representa uma nova sessão, sem estado em memória.
  valid = valid && ReadCachedUpdate(path, 42, hash).build == 42;
  valid = valid && ReadCachedUpdate(path, 43, hash).build == 0;
  valid = valid && ReadCachedUpdate(path, 42, L"invalid").build == 0;
  valid = valid && ReadCachedUpdate(path, 42, std::wstring(64, L'0')).build == 0;
  file = CreateFileW(path.c_str(), FILE_APPEND_DATA, 0, nullptr, OPEN_EXISTING,
                     FILE_ATTRIBUTE_NORMAL, nullptr);
  DWORD written = 0;
  if (file == INVALID_HANDLE_VALUE) valid = false;
  else {
    valid = valid && WriteFile(file, "changed", 7, &written, nullptr) && written == 7;
    CloseHandle(file);
  }
  valid = valid && ReadCachedUpdate(path, 42, hash).build == 0;
  DeleteFileW(path.c_str());
  valid = valid && ReadCachedUpdate(path, 42, hash).build == 0;
  std::cout << (valid ? "OK: cache restored; wrong build, hash, tampering and missing file rejected.\n"
                      : "Cache regression failed.\n");
  return valid ? 0 : 4;
}
