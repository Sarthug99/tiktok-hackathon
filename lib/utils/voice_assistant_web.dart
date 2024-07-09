import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:instagram_clone_flutter/utils/actions.dart' as custom_actions;

class VoiceAssistant {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late DialogFlow _dialogflow;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  late Function(bool) onListeningStateChanged;

  VoiceAssistant({required this.onListeningStateChanged}) {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeDialogflow();
    _initSpeech();
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
    try {
      await html.window.navigator.getUserMedia(audio: true);
      print('Microphone permission granted.');
    } catch (e) {
      print('Microphone permission denied on web: $e');
      _speak('Microphone permission denied. Please enable microphone access in your browser settings.');
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    if (_speechEnabled) {
      print('Speech recognition initialized.');
    } else {
      print('Speech recognition not available.');
    }
  }

  void startListening(BuildContext context) async {
    await requestMicrophonePermission();

    if (_speechEnabled) {
      _isListening = true;
      _speech.listen(onResult: (val) => _onSpeechResult(val, context));
      onListeningStateChanged(true);
      print('Started listening...');
    } else {
      print('Speech recognition not enabled.');
      _speak('Speech recognition is not enabled.');
    }
  }

  void stopListening() async {
    await _speech.stop();
    _isListening = false;
    onListeningStateChanged(false);
    print('Stopped listening.');
  }

  void _onSpeechResult(SpeechRecognitionResult result, BuildContext context) {
    _lastWords = result.recognizedWords;
    print("Recognized words: $_lastWords");

    if (_lastWords.isNotEmpty) {
      _processCommand(_lastWords, context);
    }
  }

  void handleError(SpeechRecognitionError error) {
    print("onError: ${error.errorMsg}");
    print("Error permanent: ${error.permanent}");

    if (error.permanent) {
      if (error.errorMsg == 'error_speech_timeout') {
        print('Speech timeout error. Please ensure you are speaking clearly.');
        _speak("I couldn't hear you. Please try speaking again.");
      } else if (error.errorMsg == 'error_no_match') {
        print('No speech match. Please try again.');
        _speak("I didn't understand that. Please repeat.");
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
    print("Processing command: $command");
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
