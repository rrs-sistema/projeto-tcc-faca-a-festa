#ifndef FACA_FESTA_UPDATE_FILE_H_
#define FACA_FESTA_UPDATE_FILE_H_
#include <windows.h>
#include <bcrypt.h>
#include <array>
#include <string>
#include <vector>

// Mantém o arquivo sem permissão de escrita durante a verificação/execução.
inline std::wstring UpdateHash(HANDLE file) {
  BCRYPT_ALG_HANDLE algorithm = nullptr;
  BCRYPT_HASH_HANDLE hash = nullptr;
  DWORD object_size = 0, read = 0;
  std::wstring output;
  if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, 0) < 0) return output;
  if (BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH, reinterpret_cast<PUCHAR>(&object_size), sizeof(object_size), &read, 0) >= 0) {
    std::vector<UCHAR> object(object_size);
    if (BCryptCreateHash(algorithm, &hash, object.data(), object_size, nullptr, 0, 0) >= 0) {
      std::array<UCHAR, 65536> buffer;
      bool ok = true;
      SetFilePointer(file, 0, nullptr, FILE_BEGIN);
      while (true) {
        if (!ReadFile(file, buffer.data(), static_cast<DWORD>(buffer.size()), &read, nullptr)) { ok = false; break; }
        if (!read) break;
        if (BCryptHashData(hash, buffer.data(), read, 0) < 0) { ok = false; break; }
      }
      std::array<UCHAR, 32> digest;
      if (ok && BCryptFinishHash(hash, digest.data(), static_cast<ULONG>(digest.size()), 0) >= 0) {
        constexpr wchar_t hex[] = L"0123456789abcdef";
        for (auto byte : digest) { output += hex[byte >> 4]; output += hex[byte & 15]; }
      }
      BCryptDestroyHash(hash);
    }
  }
  BCryptCloseAlgorithmProvider(algorithm, 0);
  return output;
}
inline std::wstring QuoteUpdatePath(const std::wstring& value) { return L"\"" + value + L"\""; }
#endif

