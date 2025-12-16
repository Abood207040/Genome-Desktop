import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/theme_controller.dart';
import '../../services/notification_service.dart';

class SettingsDisplayPanel extends StatefulWidget {
  const SettingsDisplayPanel({super.key});

  @override
  State<SettingsDisplayPanel> createState() => _SettingsDisplayPanelState();
}

class _SettingsDisplayPanelState extends State<SettingsDisplayPanel> {
  bool isArabic = false;

  @override
  void initState() {
    super.initState();
    // sync app theme with device system theme on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeController = Provider.of<ThemeController>(context, listen: false);
      final brightness = MediaQuery.of(context).platformBrightness;
      themeController.syncWithSystem(brightness);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color panelTextColor = isDark ? Colors.white : Colors.black87;
    Color tileBackground = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Display",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2E2A85),
            ),
          ),
          const SizedBox(height: 40),
          
          // Change Language
         
          const SizedBox(height: 25),

          // Dark Mode (Now detects system and updates correctly)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2E8AF1),
                width: 3,
              ),
            ),
            child: _switchTile(
              title: "Dark Mode",
              value: themeController.themeMode == ThemeMode.dark,
              onChanged: (v) {
                themeController.setDarkMode(v);
              },
              background: tileBackground,
              textColor: panelTextColor,
              icon: Icons.brightness_6,
            ),
          ),

          const SizedBox(height: 40),

          // Notification Test Section
          Text(
            "Notification Test",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2E2A85),
            ),
          ),
          const SizedBox(height: 20),

          // Test Appointment Notification
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: tileBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: panelTextColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Test Appointment Notification",
                      style: TextStyle(
                        color: panelTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    await NotificationService().showAppointmentNotification(
                      patientName: "John Doe",
                      appointmentTime: "10:00 AM",
                      appointmentDate: "2024-12-17",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointment notification sent!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8AF1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Test"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Test Chat Notification
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: tileBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat,
                      color: panelTextColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Test Chat Notification",
                      style: TextStyle(
                        color: panelTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    await NotificationService().showChatNotification(
                      senderName: "Patient Smith",
                      message: "Hello doctor, I need to reschedule my appointment",
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chat notification sent!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8AF1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Test"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required Color background,
    required Color textColor,
    required IconData icon,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? Colors.white : Colors.black),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2E8AF1),
            inactiveTrackColor: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }
}
