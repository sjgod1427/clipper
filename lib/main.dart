import 'package:clipper/add_url_screen.dart';
import 'package:clipper/firebase_options.dart';
import 'package:clipper/home_screen.dart';
import 'package:clipper/login_screen.dart';
import 'package:clipper/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clipper/instagram_service.dart';

const platform = MethodChannel('com.app.clipvault/share');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final sharedText = await platform.invokeMethod<String>('getSharedText');
  // runApp(MyApp(sharedText: sharedText));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => InstagramService()),
      ],
      child: MyApp(sharedText: sharedText),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? sharedText;

  const MyApp({super.key, this.sharedText});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clipper',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(sharedText: sharedText),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final String? sharedText;

  const AuthWrapper({super.key, this.sharedText});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          if (sharedText != null) {
            return AddUrlScreen(sharedText: sharedText!);
          } else {
            return ClipVaultApp();
          }
        } else {
          return LoginScreen(
            sharedText: sharedText,
          ); // <-- pass sharedText here
        }
      },
    );
  }
}
