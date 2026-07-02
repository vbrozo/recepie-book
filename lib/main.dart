import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // Route framework + zone errors through a single, greppable console
  // prefix — otherwise failures that don't go through a repository's
  // try/catch (e.g. something throwing inside the sqflite web worker's
  // message channel) only show up as an unlabeled minified stack trace.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[Kuharica] FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Kuharica] Uncaught error: $error\n$stack');
    return true;
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: RecipeBookApp())),
    (error, stack) => debugPrint('[Kuharica] Uncaught zone error: $error\n$stack'),
  );
}
