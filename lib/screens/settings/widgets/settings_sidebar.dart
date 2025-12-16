import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/theme_controller.dart';

class SettingsSidebar extends StatelessWidget {
  final String activePage;
  final Function(String) onItemSelected;

  const SettingsSidebar({
    super.key,
    required this.activePage,
    required this.onItemSelected,
  });

  // --------------------------------------------------
  // LOGOUT FUNCTION
  // --------------------------------------------------
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  Widget _sideItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool selected,
    required Function() onTap,
  }) {
    final themeController = Provider.of<ThemeController>(context);
    final bool isDark = themeController.themeMode == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.25))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 30,
        leading: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black87,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final bool isDark = themeController.themeMode == ThemeMode.dark;

    return Container(
      width: 230,
      margin: const EdgeInsets.only(left: 25, top: 25, bottom: 25),
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF272A4F).withOpacity(0.6),
            const Color(0xFF1A1A2E).withOpacity(0.7),
          ] : [
            const Color(0xFF8A8FBF).withOpacity(0.35),
            const Color(0xFF595C7A).withOpacity(0.40),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Sidebar Title
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text(
              "Settings",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          /// Menu Items
          _sideItem(
            context: context,
            icon: Icons.display_settings,
            title: "Display",
            selected: activePage == "Display",
            onTap: () => onItemSelected("Display"),
          ),

          _sideItem(
            context: context,
            icon: Icons.person,
            title: "Edit Profile",
            selected: activePage == "Edit Profile",
            onTap: () => onItemSelected("Edit Profile"),
          ),

          _sideItem(
            context: context,
            icon: Icons.delete_forever,
            title: "Delete Account",
            selected: activePage == "Delete Account",
            onTap: () => onItemSelected("Delete Account"),
          ),

          const SizedBox(height: 20),

          /// Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.25),
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),

          /// LOGOUT (Calls Logout Function)
          _sideItem(
            context: context,
            icon: Icons.logout,
            title: "Logout",
            selected: false,
            onTap: () => _logout(context),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
