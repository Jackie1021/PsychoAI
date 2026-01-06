
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_app/firebase_options.dart';
import 'package:flutter_app/models/app_theme.dart';
import 'package:flutter_app/pages/home_page.dart';
import 'package:flutter_app/pages/profile_card_editor_page.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/services/chat_service.dart';
import 'package:flutter_app/services/theme_service.dart';
import 'package:flutter_app/providers/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'pages/post_page.dart';
import 'pages/auth_page.dart';

// Global notifier for theme changes (can be removed if fully migrated to Riverpod)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    // 🔧 本地开发：连接到 Emulator
  if (kDebugMode) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5002);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9098);
    FirebaseStorage.instance.useStorageEmulator('localhost', 9198);
  }

  await setupLocator(); // Set up the service locator

  // LLM integration removed - now handled by Firebase Functions in backend

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAppTheme = ref.watch(themeProvider);

    // Use .when to handle the different states of the async provider
    return asyncAppTheme.when(
      data: (appTheme) {
        // --- THEME DATA IS SUCCESSFULLY LOADED ---
        final themeColors = appTheme.colors;
        final baseTextTheme = GoogleFonts.josefinSansTextTheme();

        final newTheme = ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: themeColors.background,
          primaryColor: themeColors.primary,
          textTheme: baseTextTheme.apply(
            bodyColor: themeColors.textColor,
            displayColor: themeColors.textColor,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: themeColors.primary,
            background: themeColors.background,
            brightness: ThemeData.estimateBrightnessForColor(themeColors.background),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: themeColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: themeColors.textColor),
            titleTextStyle: baseTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeColors.textColor,
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: themeColors.cardBackground, // Using cardBackground for nav bar
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: themeColors.textColor),
          ),
        );

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final user = snapshot.data;
            
            if (user == null) {
              return MaterialApp(
                title: 'Psycho',
                theme: newTheme,
                debugShowCheckedModeBanner: false,
                home: const AuthPage(),
              );
            }

            // User is logged in, wrap with ChatProvider
            return provider.ChangeNotifierProvider<ChatProvider>(
              create: (_) => ChatProvider(
                chatService: locator<ChatService>(),
                currentUserId: user.uid,
              ),
              child: MaterialApp(
                title: 'Psycho',
                theme: newTheme,
                debugShowCheckedModeBanner: false,
                home: const HomePage(),
                routes: {
                  '/profile_card_editor': (context) =>
                      const ProfileCardEditorPage(),
                },
              ),
            );
          },
        );
      },
      loading: () {
        // --- THEME IS LOADING ---
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (err, stack) {
        // --- FAILED TO LOAD THEME ---
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Text(
                'Failed to load theme: $err',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
