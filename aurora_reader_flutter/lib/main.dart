import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/logging/error_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('aurora_reader');

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorLogger.instance.capture(
      details.exception,
      stackTrace: details.stack,
      source: 'FlutterError: ${details.library ?? 'unknown'}',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger.instance.capture(
      error,
      stackTrace: stack,
      source: 'PlatformDispatcher',
    );
    return true;
  };

  runApp(const ProviderScope(child: AuroraReaderApp()));
}
