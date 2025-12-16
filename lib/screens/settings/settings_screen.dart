import 'package:flutter/material.dart';
import 'package:genome/screens/settings/delete_account_screen.dart';
import 'package:genome/screens/settings/edit_profile_screen.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/custom_app_bar.dart';
import 'settings_display_panel.dart';
import 'widgets/settings_sidebar.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String activePage = "Display";

  @override
  Widget build(BuildContext context) {
    Widget pageWidget;

    if (activePage == "Display") {
      pageWidget = const SettingsDisplayPanel();
    } else if (activePage == "Edit Profile") {
      pageWidget = const EditProfileScreen();
    } else if (activePage == "Delete Account") {
  pageWidget = const DeleteAccountScreen();
} else {
      pageWidget = Container(); // default fallback
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const CustomAppBar(activePage: "Settings"),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Sidebar with highlight & clicks
                  SettingsSidebar(
                    activePage: activePage,
                    onItemSelected: (page) {
                      if (page == "Logout") {
                        // process logout later
                        return;
                      }
                      setState(() => activePage = page);
                    },
                  ),

                  /// Panel content
                  Expanded(child: pageWidget),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
