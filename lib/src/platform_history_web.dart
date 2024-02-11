import 'package:flutter/material.dart';
import 'dart:html';

import 'package:formica/src/platform_history.dart';

class PlatformHistory extends PlatformHistoryInterface {
  static PlatformHistory? _instance;

  factory PlatformHistory() => _instance ??= PlatformHistory._();

  PlatformHistory._() {
    window.onPopState.listen(_onPopState);
  }

  Uri get base
  {
    return Uri.parse(window.location.href).resolve(window.document.querySelector('base')?.getAttribute('href') ?? '/');
  }

  void _onPopState(PopStateEvent e) {
    Uri uri = Uri.parse(window.location.href);
    onPop.value = Uri.parse(window.location.href)
        .toString()
        .replaceFirst(base.toString(), '');
  }

  @override
  push(String path) {
    Uri uri = Uri.parse(window.location.href);
    Uri nextUri = base.resolve(path);
    if(uri.toString() != nextUri.toString())
    {
      window.history.pushState({}, '', path);
    }
  }

  @override
  replace(String path) {
    window.history.replaceState({}, '', path);
  }
}
