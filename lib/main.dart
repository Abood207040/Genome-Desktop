import 'package:flutter/material.dart';
import 'package:genome/screens/AppointmentsScreen.dart';
import 'package:genome/screens/DoctorChatScreen.dart';
import 'package:genome/screens/DoctorInboxPage.dart';
import 'package:genome/screens/Models/child_deses_screen.dart';
import 'package:genome/screens/Models/patient_disease_screen.dart';
import 'package:genome/screens/Models/upload_screen.dart';
import 'package:genome/screens/auth/login_screen.dart';
import 'package:genome/screens/auth/signup_step1_screen.dart';
import 'package:genome/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/theme_controller.dart'; // Import ThemeController
import 'screens/homepage.dart'; // Import HomeScreen
import 'services/notification_service.dart'; // Import Notification Service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );  // Ensure Firebase is initialized
  } catch (e) {
    debugPrint("🔥 Firebase initialization failed: $e");
  }

  // Initialize notifications
  try {
    await NotificationService().initialize();
    debugPrint("✅ Notifications initialized successfully");
  } catch (e) {
    debugPrint("❌ Notification initialization failed: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(), // Provide ThemeController
      child: const GenomeApp(),
    ),
  );
}

class GenomeApp extends StatelessWidget {
  const GenomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GENORA",
      themeMode: themeController.themeMode,  // Set theme mode dynamically
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      initialRoute: "/auth",  // Home screen as the initial screen

      routes: {
        "/home": (context) => const HomeScreen(),
        "/appointments": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final initialFilter = args?['statusFilter'] as String?;
          return AppointmentsScreen(initialStatusFilter: initialFilter);
        },
        "/settings": (context) => const SettingsScreen(),
        "/upload-file": (context) => const UploadScreen(),
        "/patient-disease": (context) => const PatientDiseaseScreen(),
        "/child-genetics": (context) => const ChildGeneticsScreen(),
"/signup": (context) => const SignUpStep1(),
        "/auth": (context) => LoginScreen(),
        "/doctor-chat": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final patientId = args?['patientId'] as String?;
          final directUserId = args?['directUserId'] as String?;
          final patientName = args?['patientName'] as String?;
          final chatId = args?['chatId'] as String?;

          if (directUserId != null) {
            // Direct navigation to chat with specific user
            return DoctorChatScreen(
              patientId: directUserId,
              patientName: patientName ?? 'Patient',
              chatId: chatId ?? '',
            );
          } else if (patientId != null && patientName != null && chatId != null) {
            // Navigate to specific chat
            return DoctorChatScreen(
              patientId: patientId,
              patientName: patientName,
              chatId: chatId,
            );
          } else {
            // Show doctor inbox (list of patient conversations)
            return const DoctorInboxPage();
          }
        },

      },
    );
  }
}
