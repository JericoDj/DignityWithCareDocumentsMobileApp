import 'package:dignitywithcare/providers/client_provider.dart';
import 'package:dignitywithcare/providers/document_provider.dart';
import 'package:dignitywithcare/providers/manage_user_provider.dart';
import 'package:dignitywithcare/providers/notes_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // ← MUST come first
  //
  // if (!kIsWeb) {
  //   await dotenv.load(fileName: ".env"); // Only mobile
  // }     // ← NOW loads correctly

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCCzxcJ0OCgl5oe-n6S-73lgE1TGMqKcyU",
        appId: "1:404595228914:web:5a5baa60241aac53db106b",
        messagingSenderId: "404595228914",
        projectId: "dignity-with-care",
        storageBucket: "dignity-with-care.firebasestorage.app",
        authDomain: "dignity-with-care.firebaseapp.com",
        measurementId: "G-FQ18C33WQE",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await GetStorage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ManageUserProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        // ChangeNotifierProvider(create: (_) => NotesProvider()),


      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        primaryColor: const Color(0xFF6200EE),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF03DAC6),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
