#include "include/formica/formica_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "formica_plugin.h"

void FormicaPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  formica::FormicaPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
