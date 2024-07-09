import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/utils/actions.dart' as custom_actions;

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
        } else if (val == 'listening') {
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
        listenFor: const Duration(seconds: 10),  // Adjust listening duration
        pauseFor: const Duration(seconds: 2),    // Adjust pause duration
        localeId: "en_US",                       // Set the locale if necessary
        cancelOnError: true,                     // Cancel on error
        partialResults: true,                    // Enable partial results
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
