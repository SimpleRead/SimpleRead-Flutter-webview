import 'package:flutter/material.dart';

import 'bridge/deeplink_handler.dart';
import 'screens/webview_screen.dart';

/// Kept alive for the app's lifetime (a top-level final, referenced from
/// main()) rather than a local variable -- deep links must be caught for as
/// long as the app runs, not just while some particular screen is mounted.
final DeeplinkHandler appDeeplinkHandler = DeeplinkHandler();

void main() {
  // Real bug fixed here: AppLinks() sets up its platform channel eagerly,
  // both for uriLinkStream and getInitialLink(). Calling it before the
  // widgets binding exists threw "Binding has not yet been initialized" on
  // every launch, silently -- no red screen, no dispatch, ever. runApp()
  // normally initializes the binding implicitly, but that's too late here
  // since appDeeplinkHandler (a top-level final) constructs AppLinks() the
  // moment start() first touches it, on the line before runApp().
  WidgetsFlutterBinding.ensureInitialized();
  appDeeplinkHandler.start();
  runApp(const SimpleReadShellApp());
}

/// Root widget of the SimpleRead hybrid native shell PoC.
class SimpleReadShellApp extends StatelessWidget {
  const SimpleReadShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SimpleRead Shell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebviewScreen(),
    );
  }
}
