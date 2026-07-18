import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_trail/auth/auth_gate.dart';
import 'package:open_trail/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  await LiquidGlassWidgets.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);

    debugPrint(details.exceptionAsString());
  };
  runApp(LiquidGlassWidgets.wrap(child: const OpenTrail()));
}

class OpenTrail extends StatelessWidget {
  const OpenTrail({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthGate());
  }
}
