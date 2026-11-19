#ifndef FACA_FESTA_UPDATE_CACHE_H_
#define FACA_FESTA_UPDATE_CACHE_H_
#include "update_file.h"

struct UpdatePackageInfo {
  int build = 0;
  std::string version;
};

inline UpdatePackageInfo ReadUpdatePackage(const std::wstring& path) {
  DWORD ignored = 0;
  DWORD size = GetFileVersionInfoSizeW(path.c_str(), &ignored);
  std::vector<BYTE> bytes(size);
  VS_FIXEDFILEINFO* fixed = nullptr;
  UINT fixed_size = 0;
  if (!size || !GetFileVersionInfoW(path.c_str(), 0, size, bytes.data()) ||
      !VerQueryValueW(bytes.data(), L"\\", reinterpret_cast<void**>(&fixed), &fixed_size) ||
      !fixed || fixed_size < sizeof(VS_FIXEDFILEINFO)) return {};
  return {LOWORD(fixed->dwFileVersionLS),
          std::to_string(HIWORD(fixed->dwFileVersionMS)) + "." +
          std::to_string(LOWORD(fixed->dwFileVersionMS)) + "." +
          std::to_string(HIWORD(fixed->dwFileVersionLS))};
}

// O cache só é reutilizado quando corresponde ao build e ao SHA-256 do
// catálogo HTTPS. Um arquivo incompleto, alterado ou antigo exige novo download.
inline UpdatePackageInfo ReadCachedUpdate(const std::wstring& path,
                                         int expected_build,
                                         const std::wstring& expected_hash) {
  if (expected_hash.size() != 64) return {};
  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) return {};
  const auto info = ReadUpdatePackage(path);
  const bool valid = info.build == expected_build && UpdateHash(file) == expected_hash;
  CloseHandle(file);
  return valid ? info : UpdatePackageInfo{};
}
#endif
