import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/models/user.dart' as model;
import 'package:instagram_clone_flutter/providers/user_provider.dart';
import 'package:instagram_clone_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_clone_flutter/responsive/responsive_layout.dart';
import 'package:instagram_clone_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_clone_flutter/screens/login_screen.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:instagram_clone_flutter/resources/auth_methods.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Conditional imports for VoiceAssistant
import 'utils/voice_assistant_mobile.dart' if (dart.library.html) 'utils/voice_assistant_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app based on platform - web or mobile
  if (kIsWeb) {
    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['WEB_APP_API_KEY']!,
        authDomain: dotenv.env['WEB_APP_AUTH_DOMAIN'],
        projectId: dotenv.env['WEB_APP_PROJECT_ID']!,
        storageBucket: dotenv.env['WEB_APP_STORAGE_BUCKET'],
        messagingSenderId: dotenv.env['WEB_APP_MESSAGING_SENDER_ID']!,
        appId: dotenv.env['WEB_APP_APP_ID']!,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Instagram Clone',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                return FutureBuilder(
                  future: AuthMethods().getUserDetails(),
                  builder: (context, AsyncSnapshot<model.User> userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasData) {
                      return const ResponsiveLayout(
                        mobileScreenLayout: MobileScreenLayout(),
                        webScreenLayout: WebScreenLayout(),
                      );
                    } else if (userSnapshot.hasError) {
                      print('Error fetching user details: ${userSnapshot.error}');
                      return const LoginScreen();
                    } else {
                      return const LoginScreen();
                    }
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
