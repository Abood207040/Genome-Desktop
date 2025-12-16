import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/app_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController currentPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      emailController.text = user.email ?? "";

      final userDoc =
          await _firestore.collection("users").doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        nameController.text = data["name"] ?? "";
        phoneController.text = data["phone"] ?? "";
      }

      setState(() {});
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  // SAVE PROFILE ----------------------------------------------------------------
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack("No user found.", isError: true);
      return;
    }

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      _showSnack("Name cannot be empty.", isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await user.updateDisplayName(name);

      await _firestore.collection("users").doc(user.uid).set({
        "name": name,
        "phone": phone,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection("doctors").doc(user.uid).set({
        "fullName": name,
        "phone": phone,
      }, SetOptions(merge: true));

      _showSnack("Profile updated successfully!");
    } catch (e) {
      _showSnack("Failed to update profile.", isError: true);
    }

    setState(() => _isSavingProfile = false);
  }

  // CHANGE PASSWORD --------------------------------------------------------------
  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack("No user found.", isError: true);
      return;
    }

    final current = currentPassController.text.trim();
    final newPass = newPassController.text.trim();
    final confirm = confirmPassController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack("Please fill all password fields.", isError: true);
      return;
    }

    if (newPass != confirm) {
      _showSnack("New password and confirm do not match.", isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showSnack("Password must be at least 6 characters.", isError: true);
      return;
    }

    setState(() => _isSavingPassword = true);

    try {
      // ⭐ FAST current-password validation
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: user.email!,
        password: current,
      );

      // ⭐ Update password
      await user.updatePassword(newPass);

      currentPassController.clear();
      newPassController.clear();
      confirmPassController.clear();

      _showSnack("Password changed successfully!");
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        _showSnack("Incorrect current password.", isError: true);
      } else if (e.code == "weak-password") {
        _showSnack("New password is too weak.", isError: true);
      } else {
        _showSnack("Error: ${e.message}", isError: true);
      }
    } catch (e) {
      _showSnack("Unexpected error: $e", isError: true);
    }

    setState(() => _isSavingPassword = false);
  }

  // SNACKBAR ---------------------------------------------------------------------
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Center(
          child: Container(
            width: 650,
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(22),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2E2A85),
                    ),
                  ),

                  const SizedBox(height: 30),

                  CircleAvatar(
                    radius: 55,
                    backgroundColor:
                        isDark ? Colors.white24 : Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 70,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 40),

                  _field("Name", nameController, isDark),
                  const SizedBox(height: 25),

                  _field("Email", emailController, isDark, readOnly: true),
                  const SizedBox(height: 25),

                  _field("Phone Number", phoneController, isDark,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 35),

                  SizedBox(
                    width: 240,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E2A85),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSavingProfile ? null : _saveProfile,
                      child: _isSavingProfile
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Update Profile",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 20),

                  _password("Current Password", currentPassController,
                      isDark, _obscureCurrent, () {
                    setState(() => _obscureCurrent = !_obscureCurrent);
                  }),
                  const SizedBox(height: 18),

                  _password("New Password", newPassController,
                      isDark, _obscureNew, () {
                    setState(() => _obscureNew = !_obscureNew);
                  }),
                  const SizedBox(height: 18),

                  _password("Confirm New Password", confirmPassController,
                      isDark, _obscureConfirm, () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  }),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: 240,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSavingPassword ? null : _changePassword,
                      child: _isSavingPassword
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Change Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // UI FIELDS ---------------------------------------------------------------------
  Widget _field(
      String label, TextEditingController controller, bool isDark,
      {bool readOnly = false, TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboard,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            ),
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _password(String label, TextEditingController controller,
      bool isDark, bool obscure, VoidCallback toggleVisibility) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: toggleVisibility,
              ),
            ),
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
