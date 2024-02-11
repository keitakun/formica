import 'package:flutter/foundation.dart';

extension StackTraceList on StackTrace {
  bool isChild(StackTrace stack) {
    List<String> thisList = toList();
    return listEquals(thisList.sublist(0, thisList.length - 2), stack.toList().sublist(0, thisList.length - 2));
  }

  List<String> toList() {
    if(kIsWeb)
    {
      return RegExp(r'(.*?\d+:\d+)\s+(.*?)$', multiLine: true, dotAll: true)
          .allMatches(toString())
          .map((e) => e.group(1) ?? '')
          .toList()
          .reversed
          .toList();
    }else
    {
      return RegExp(r'(?:#\d+\s+)?(.*?)$', multiLine: true, dotAll: true)
          .allMatches(toString())
          .map((e) => e.group(1) ?? '')
          .toList()
          .reversed
          .toList();
    }
  }
}
