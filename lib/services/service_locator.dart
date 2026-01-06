import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/firebase_api_service.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/services/firebase_chat_service.dart';

// Global service locator instance.
final GetIt locator = GetIt.instance;

/// Controls whether to use Firebase services even in debug mode.
/// Set this to true to test Firebase integration during development.
/// Default: true (uses Firebase service with emulators in debug mode)
/// NOTE: Always true now - fake service is deprecated
bool useFirebaseInDebug = true;


/// Registers the services with the service locator.
///
/// This function should be called once at app startup.
/// Always uses Firebase API Service - fake service is deprecated.
/// In debug mode, connects to Firebase Emulators.
/// In release mode, connects to production Firebase.
Future<void> setupLocator() async {
  // Use a factory for the ApiService, so a new instance is created on each request if needed,
  // or use a singleton if the service should persist throughout the app's lifecycle.
  locator.registerSingletonAsync<ApiService>(() async {
    print('🔥 Using Firebase API Service (with Emulator support in debug mode)');
    print('   Debug mode: $kDebugMode');
    print('   Will connect to: ${kDebugMode ? 'Firebase Emulators' : 'Production Firebase'}');

    return FirebaseApiService();
  });

  // Register ChatService
  locator.registerLazySingleton<ChatService>(() {
    print('💬 Registering Firebase Chat Service');
    return FirebaseChatService();
  });
}

/// Utility function to reinitialize the service locator.
/// This can be useful if you need to force a service refresh.
void reinitializeLocator() {
  print('🔄 Reinitializing service locator...');
  locator.unregister<ApiService>();
  setupLocator();
}

