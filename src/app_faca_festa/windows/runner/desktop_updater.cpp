#include "desktop_updater.h"
#include "update_file.h"
#include "update_cache.h"
#include "updater_public_key.h"
#include <winsparkle.h>
#include <shlobj.h>
#include <vector>

DesktopUpdater* DesktopUpdater::instance_ = nullptr;
DesktopUpdater::DesktopUpdater(HWND window, flutter::BinaryMessenger* messenger) : window_(window) {
  instance_ = this;
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(messenger, "faca_festa/desktop_update", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "installedInfo") {
      result->Success(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("version"), flutter::EncodableValue(std::string(FLUTTER_VERSION))},
        {flutter::EncodableValue("build"), flutter::EncodableValue(FLUTTER_VERSION_BUILD)}
      }));
    } else if (call.method_name() == "initialize") {
      if (!initialized_) {
        win_sparkle_set_appcast_url("https://faca-a-festa.web.app/desktop/updates/appcast.xml");
        if (!win_sparkle_set_eddsa_public_key(kUpdaterPublicKey)) { result->Error("invalid_key", "Chave do atualizador inválida."); return; }
        const std::string version = FLUTTER_VERSION;
        const std::wstring display(version.begin(), version.end());
        const std::wstring build = std::to_wstring(FLUTTER_VERSION_BUILD);
        win_sparkle_set_app_details(L"RRS System Technology", L"Faça a Festa", display.c_str());
        win_sparkle_set_app_build_version(build.c_str());
        win_sparkle_set_lang("pt_BR");
        win_sparkle_set_automatic_check_for_updates(0);
        win_sparkle_set_user_run_installer_callback(CaptureInstaller);
        // WinSparkle nunca lança o instalador: o callback copia o pacote
        // verificado e a UI Flutter solicita a instalação separadamente.
        win_sparkle_set_shutdown_request_callback(OnReady);
        win_sparkle_set_error_callback(OnError);
        win_sparkle_set_did_not_find_update_callback(OnNoUpdate);
        win_sparkle_set_update_cancelled_callback(OnError);
        win_sparkle_init();
        initialized_ = true;
      }
      result->Success();
    } else if (call.method_name() == "restoreDownload" && initialized_) {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (!args) { result->Error("invalid_cache_request", "Catálogo inválido."); return; }
      const auto build_entry = args->find(flutter::EncodableValue("build"));
      const auto hash_entry = args->find(flutter::EncodableValue("sha256"));
      if (build_entry == args->end() || hash_entry == args->end() ||
          !std::holds_alternative<int32_t>(build_entry->second) ||
          !std::holds_alternative<std::string>(hash_entry->second)) {
        result->Error("invalid_cache_request", "Catálogo inválido."); return;
      }
      const int build = std::get<int32_t>(build_entry->second);
      const auto hash = std::get<std::string>(hash_entry->second);
      const std::wstring digest(hash.begin(), hash.end());
      const auto path = CachePath();
      const auto info = build > FLUTTER_VERSION_BUILD
          ? ReadCachedUpdate(path, build, digest) : UpdatePackageInfo{};
      if (info.build == 0) { result->Success(); return; }
      {
        std::lock_guard<std::mutex> guard(mutex_);
        installer_ = path;
        checksum_ = digest;
        build_ = info.build;
        version_ = info.version;
      }
      result->Success(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("version"), flutter::EncodableValue(info.version)},
        {flutter::EncodableValue("build"), flutter::EncodableValue(info.build)}
      }));
    } else if (call.method_name() == "download" && initialized_) {
      win_sparkle_check_update_with_ui_and_install();
      result->Success();
    } else if (call.method_name() == "install" && initialized_) {
      if (LaunchHelper()) {
        result->Success();
        // O helper aguarda este processo sair; encerra a janela pelo Windows.
        PostMessageW(window_, WM_CLOSE, 0, 0);
      }
      else result->Error("install_failed", "Não foi possível preparar a instalação. Tente novamente.");
    } else result->NotImplemented();
  });
}
DesktopUpdater::~DesktopUpdater() {
  if (initialized_) win_sparkle_cleanup();
  instance_ = nullptr;
}
int __cdecl DesktopUpdater::CaptureInstaller(const wchar_t* path) {
  auto* self = instance_;
  if (!self) return -1;
  // Evita downgrade mesmo se os números do appcast forem alterados.
  const auto info = ReadUpdatePackage(path);
  const int build = info.build;
  if (build <= FLUTTER_VERSION_BUILD) return -1;
  const auto destination = self->CachePath();
  if (destination.empty()) return -1;
  const auto staging = destination + L".download";
  if (!CopyFileW(path, staging.c_str(), FALSE)) return -1;
  HANDLE file = CreateFileW(staging.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) return -1;
  const auto digest = UpdateHash(file);
  CloseHandle(file);
  if (digest.empty() || !MoveFileExW(staging.c_str(), destination.c_str(),
                                   MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
    DeleteFileW(staging.c_str());
    return -1;
  }
  std::lock_guard<std::mutex> guard(self->mutex_);
  self->installer_ = destination;
  self->checksum_ = digest;
  self->build_ = build;
  self->version_ = info.version;
  return 1;
}
std::wstring DesktopUpdater::CachePath() {
  wchar_t local[MAX_PATH];
  if (FAILED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr, 0, local))) return {};
  const auto directory = std::wstring(local) + L"\\FacaFesta\\Updates";
  if (SHCreateDirectoryExW(nullptr, directory.c_str(), nullptr) != ERROR_SUCCESS &&
      GetFileAttributesW(directory.c_str()) == INVALID_FILE_ATTRIBUTES) return {};
  return directory + L"\\pending.exe";
}
void __cdecl DesktopUpdater::OnError() { if (instance_) PostMessage(instance_->window_, kEventMessage, 1, 0); }
void __cdecl DesktopUpdater::OnNoUpdate() { if (instance_) PostMessage(instance_->window_, kEventMessage, 2, 0); }
void __cdecl DesktopUpdater::OnReady() { if (instance_) PostMessage(instance_->window_, kEventMessage, 3, 0); }
void DesktopUpdater::DispatchEvent(WPARAM event) {
  if (event == 3) {
    std::lock_guard<std::mutex> guard(mutex_);
    channel_->InvokeMethod("ready", std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
      {flutter::EncodableValue("version"), flutter::EncodableValue(version_)},
      {flutter::EncodableValue("build"), flutter::EncodableValue(build_)}
    }));
  } else channel_->InvokeMethod(event == 1 ? "error" : "noUpdate", nullptr);
}
bool DesktopUpdater::LaunchHelper() {
  std::lock_guard<std::mutex> guard(mutex_);
  if (installer_.empty() || checksum_.empty()) return false;
  wchar_t app[MAX_PATH];
  if (!GetModuleFileNameW(nullptr, app, MAX_PATH)) return false;
  const std::wstring executable = app;
  const auto directory = executable.substr(0, executable.find_last_of(L"\\"));
  const auto helper = installer_ + L".helper.exe";
  if (!CopyFileW((directory + L"\\faca_festa_update_helper.exe").c_str(), helper.c_str(), FALSE)) return false;
  std::wstring command = QuoteUpdatePath(helper) + L" " + QuoteUpdatePath(installer_) + L" " + std::to_wstring(GetCurrentProcessId()) + L" " + QuoteUpdatePath(executable) + L" " + checksum_;
  STARTUPINFOW startup{}; startup.cb = sizeof(startup);
  PROCESS_INFORMATION process{};
  if (!CreateProcessW(helper.c_str(), command.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW, nullptr, directory.c_str(), &startup, &process)) return false;
  CloseHandle(process.hThread); CloseHandle(process.hProcess);
  return true;
}

