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
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:instagram_clone_flutter/utils/actions.dart' as custom_actions;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize app based on platform - web or mobile
  if (kIsWeb) {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['WEB_APP_API_KEY']!,
        authDomain: dotenv.env['WEB_APP_AUTH_DOMAIN'],
        projectId: dotenv.env['WEB_APP_PROJECT_ID']!,
        storageBucket: dotenv.env['WEB_APP_STORAGE_BUCKET'],
        messagingSenderId: dotenv.env['WEB_APP_MESSAGING_SENDER_ID']!,
        appId: dotenv.env['WEB_APP_APP_ID']!
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
        ChangeNotifierProvider(create: (_) => UserProvider(),),
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
              // Checking if the snapshot has any data or not
              if (snapshot.hasData) {
                // if snapshot has data, it means the user is logged in
                return FutureBuilder(
                  future: AuthMethods().getUserDetails(),
                  builder: (context, AsyncSnapshot<model.User> userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (userSnapshot.hasData) {
                      // if user data exists in Firestore, display the screen layout
                      return const ResponsiveLayout(
                        mobileScreenLayout: MobileScreenLayout(),
                        webScreenLayout: WebScreenLayout(),
                      );
                    } else if (userSnapshot.hasError) {
                      // if there is an error (e.g., user data does not exist in Firestore), display the login screen
                      print('Error fetching user details: ${userSnapshot.error}');
                      return const LoginScreen();
                    } else {
                      // if user data does not exist in Firestore, display the login screen
                      return const LoginScreen();
                    }
                  },
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }
            }

            // means connection to future hasn't been made yet
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class VoiceAssistant {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late DialogFlow _dialogflow;
  bool _isListening = false;
  late Function(bool) onListeningStateChanged;

  VoiceAssistant({required this.onListeningStateChanged}) {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeDialogflow();
  }

  void _initializeDialogflow() async {
    try {
      AuthGoogle authGoogle = await AuthGoogle(fileJson: "assets/service_account_key.json").build();
      _dialogflow = DialogFlow(authGoogle: authGoogle, language: "en");
    } catch (e) {
      print("Error initializing DialogFlow: $e");
    }
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void startListening(BuildContext context) async {
    await requestMicrophonePermission();

    bool available = await _speech.initialize(
      onStatus: (val) {
        print('onStatus: $val');
        if (val == 'done' || val == 'notListening') {
          _isListening = false;
          onListeningStateChanged(false);
          print('Listening stopped or failed.');
        } else {
          _isListening = true;
          onListeningStateChanged(true);
        }
      },
      onError: (val) {
        print('onError: ${val.errorMsg}');
        _isListening = false;
        onListeningStateChanged(false);
        handleError(val);
      },
    );

    if (available) {
      print('Starting to listen...');
      _speech.listen(
        onResult: (val) {
          if (val.hasConfidenceRating && val.confidence > 0) {
            print("------ recognized words: ${val.recognizedWords}");
            _processCommand(val.recognizedWords, context);
          } else {
            print("------ no words recognized");
          }
        },
        listenFor: const Duration(seconds: 60),  // Increase the listening duration
        pauseFor: const Duration(seconds: 5),    // Increase the pause duration
        localeId: "en_US",                 // Set the locale if necessary
        cancelOnError: true,               // Cancel on error
        partialResults: true,              // Enable partial results
      );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    onListeningStateChanged(false);
  }

  void handleError(error) {
    print("onError: ${error.errorMsg}");
    print("Error permanent: ${error.permanent}");

    if (error.permanent) {
      // Handle the permanent error case
      if (error.errorMsg == 'error_speech_timeout') {
        print('Speech timeout error. Please ensure you are speaking clearly.');
        _speak("I couldn't hear you. Please try speaking again.");
      } else if (error.errorMsg == 'error_no_match') {
        print('No speech match. Please try again.');
        _speak("I didn't understand that. Could you please repeat?");
      } else if (error.errorMsg == 'error_audio') {
        print('Audio recording error. Please check your microphone.');
        _speak("There was an issue with the microphone. Please check it and try again.");
      } else {
        print('An unknown permanent error occurred.');
        _speak("An unknown error occurred. Please try again later.");
      }
    }
  }

  void _processCommand(String command, BuildContext context) async {
    print("Inside process command - $command");
    try {
      AIResponse response = await _dialogflow.detectIntent(command);
      if (response.queryResult == null) {
        print("Null response from DialogFlow");
        _speak("I didn't understand that. Please try again.");
        return;
      }
      String? intent = response.queryResult?.intent?.displayName;
      print("Intent: $intent");
      _performAction(intent ?? "Unknown", context);
    } catch (e) {
      print("Error processing command: $e");
      _speak("I didn't understand that. Please try again.");
    }
  }

  void _performAction(String intent, BuildContext context) {
    if (intent == 'Swipe Up') {
      _speak("Swiping up");
      custom_actions.Actions.swipeUp(context); // Call the swipe up action
    } else if (intent == 'Swipe Down') {
      _speak("Swiping down");
      custom_actions.Actions.swipeDown(context); // Call the swipe down action
    } else if (intent == 'Add Post') {
      _speak("Adding a post");
      custom_actions.Actions.addPost(context); // Call the add post action
    } else {
      _speak("I didn't understand that.");
    }
  }

  Future _speak(String text) async {
    await _flutterTts.speak(text);
  }
}

