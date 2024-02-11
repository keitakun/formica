import 'package:formica/src/platform_history.dart';

class PlatformHistory extends PlatformHistoryInterface {
  static PlatformHistory? _instance;

  factory PlatformHistory() => _instance ??= PlatformHistory._();

  PlatformHistory._();
}
