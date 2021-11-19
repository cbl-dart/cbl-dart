#include "include/cbl_flutter_ee/cbl_flutter_ee.h"

#include <flutter/plugin_registrar_windows.h>

namespace {

class CblFlutterEe : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CblFlutterEe();

  virtual ~CblFlutterEe();
};

// static
void CblFlutterEe::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<CblFlutterEe>();
  registrar->AddPlugin(std::move(plugin));
}

CblFlutterEe::CblFlutterEe() {}

CblFlutterEe::~CblFlutterEe() {}

}  // namespace

void CblFlutterEeRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  CblFlutterEe::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
