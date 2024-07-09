# TikTok Hackathon 2024


## Features
- Voice Control (Swipe Up, Swipe Down, Create a post)
- Epileptic Sensitivity
- Contrast Error Detection

We get a dialog box with Accessibility Report after creating a post. 

## Setup & Installation
- Clone this repository.
- Follow this to install and setup Flutter for Android development.
- Create and setup Firebase Project
- Setup DialogFlowAPI.

### Firebase Setup
- Enable Authentication.
- Create collections in Firestore Database - posts, users, job_processing.
- Enable Firebase Storage.
- Make Firestore rules.
- Create an android application.
- Download the google-services.json and place it in android/app.
- Copy the Web Firebase options into a .env created in the root.

### DialogFlow API Setup
- Enable DialogFlow API in Google Cloud Platform.
- Click on Create credentials and then create a service account to access this API.
- Download the service account key json and copy it to /assets as service_account_key.json.
- Create an agent on DialogFlow ES Console.
- Create Intents - Swipe Up, Swipe Down and Add Post. (Give them appropriate training phrases)

### Accessibility Pipeline
- Asynchronous processing of video/images for accessibility testing
- constrast checking
- epilepsy causing pattern detection
- runs through job processing.

## Steps to run
- Start a Virtual Device in Android Studio.
```bash
  flutter clean
  flutter pub get
  flutter run

  cd fastapi
  python worker.py
```

## Technology Used
- Frontend -> Flutter
- Backend -> Firebase
- Backend -> Python

This app is inspired by [Rivaan Ranawat](https://github.com/RivaanRanawat/instagram-flutter-clone) 's opensource app



