#ifndef FACA_FESTA_DESKTOP_UPDATER_H_
#define FACA_FESTA_DESKTOP_UPDATER_H_
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <memory>
#include <mutex>
#include <string>

class DesktopUpdater {
 public:
  static constexpr UINT kEventMessage = WM_APP + 170;
  DesktopUpdater(HWND window, flutter::BinaryMessenger* messenger);
  ~DesktopUpdater();
  void DispatchEvent(WPARAM event);
 private:
  static DesktopUpdater* instance_;
  static int __cdecl CaptureInstaller(const wchar_t* path);
  static void __cdecl OnError();
  static void __cdecl OnNoUpdate();
  static void __cdecl OnReady();
  bool LaunchHelper();
  HWND window_;
  bool initialized_ = false;
  std::mutex mutex_;
  std::wstring installer_;
  std::wstring checksum_;
  std::string version_;
  int build_ = 0;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};
#endif

