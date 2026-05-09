import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LogService {
  static final Logger _logger = Logger(
    level: kReleaseMode ? Level.nothing : Level.debug,
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: _shouldUseColors(),
      printEmojis: true,
      printTime: true,
    ),
  );

  static bool _shouldUseColors() {
    if (kReleaseMode) return false;

    // Disable colors on iOS because Xcode console
    // does not support ANSI escape sequences
    if (Platform.isIOS) return false;

    return true;
  }

  static Logger get logger => _logger;

  static void setLevel(Level level) {
    Logger.level = level;
  }
}
