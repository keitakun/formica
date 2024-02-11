#ifndef FLUTTER_PLUGIN_FORMICA_PLUGIN_H_
#define FLUTTER_PLUGIN_FORMICA_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace formica {

class FormicaPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FormicaPlugin();

  virtual ~FormicaPlugin();

  // Disallow copy and assign.
  FormicaPlugin(const FormicaPlugin&) = delete;
  FormicaPlugin& operator=(const FormicaPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace formica

#endif  // FLUTTER_PLUGIN_FORMICA_PLUGIN_H_
