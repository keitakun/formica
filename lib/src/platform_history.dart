import 'package:flutter/material.dart';

abstract class PlatformHistoryInterface {
  ValueNotifier<String> onPop = ValueNotifier<String>('');

  push(String path) {}

  replace(String path) {}
}
