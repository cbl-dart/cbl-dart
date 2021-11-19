#include "include/cbl_flutter_local/cbl_flutter_local_plugin.h"

#include <flutter/plugin_registrar_windows.h>

namespace {

class CblFlutterLocalPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  CblFlutterLocalPlugin();

  virtual ~CblFlutterLocalPlugin();
};

// static
void CblFlutterLocalPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<CblFlutterLocalPlugin>();
  registrar->AddPlugin(std::move(plugin));
}

CblFlutterLocalPlugin::CblFlutterLocalPlugin() {}

CblFlutterLocalPlugin::~CblFlutterLocalPlugin() {}

}  // namespace

void CblFlutterLocalPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  CblFlutterLocalPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
