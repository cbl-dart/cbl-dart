#include "include/cbl_flutter_ce/cbl_flutter_ce.h"

#include <flutter/plugin_registrar_windows.h>

namespace {

class CblFlutterCe : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CblFlutterCe();

  virtual ~CblFlutterCe();
};

// static
void CblFlutterCe::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<CblFlutterCe>();
  registrar->AddPlugin(std::move(plugin));
}

CblFlutterCe::CblFlutterCe() {}

CblFlutterCe::~CblFlutterCe() {}

}  // namespace

void CblFlutterCeRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  CblFlutterCe::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
