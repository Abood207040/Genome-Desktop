import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_background.dart';

class SignUpStep2 extends StatefulWidget {
  final String fullName;
  final String email;
  final String jobNumber;
  final String dob;

  const SignUpStep2({
    super.key,
    required this.fullName,
    required this.email,
    required this.jobNumber,
    required this.dob,
  });

  @override
  State<SignUpStep2> createState() => _SignUpStep2State();
}

class _SignUpStep2State extends State<SignUpStep2> {
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  bool obscurePass = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Row(
          children: [
            Expanded(
              child: Image.asset(
                "assets/images/signup_art.png",
                width: 420,
              ),
            ),

            Expanded(
              child: Center(
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Text(
                              "Create\nyour account",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              "Almost done! Just create your password to continue.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 35),

                            _input(
                              "Password",
                              password,
                              isDark,
                              obscure: obscurePass,
                              onToggle: () =>
                                  setState(() => obscurePass = !obscurePass),
                            ),

                            const SizedBox(height: 18),

                            _input(
                              "Confirm Password",
                              confirmPassword,
                              isDark,
                              obscure: obscureConfirm,
                              onToggle: () => setState(
                                  () => obscureConfirm = !obscureConfirm),
                            ),

                            const SizedBox(height: 35),

                            SizedBox(
                              width: 200,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E2A85),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : _handleDoctorSignup,
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Continue",
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                "← Back to previous step",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // CREATE DOCTOR AUTH + FIRESTORE
  // -----------------------------------------------------
  void _handleDoctorSignup() async {
    if (password.text.isEmpty || confirmPassword.text.isEmpty) {
      return _error("Please fill both fields.");
    }

    if (password.text.length < 6) {
      return _error("Password must be at least 6 characters.");
    }

    if (password.text != confirmPassword.text) {
      return _error("Passwords do not match.");
    }

    setState(() => isLoading = true);

    try {
      /// 1️⃣ Create Auh User
      UserCredential creds =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email.trim(),
        password: password.text.trim(),
      );

      String uid = creds.user!.uid;

      /// 2️⃣ Add doctor → /doctors/{uid}
      await FirebaseFirestore.instance.collection("doctors").doc(uid).set({
        "fullName": widget.fullName,
        "email": widget.email,
        "jobNumber": widget.jobNumber,
        "dob": widget.dob,
        "role": "doctor",
        "uid": uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      /// 3️⃣ Add to users → /users/{uid}
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": widget.fullName,
        "email": widget.email,
        "role": "doctor",
        "uid": uid,
        "createdAt": FieldValue.serverTimestamp(),
      });

      /// 4️⃣ Success → Back to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully! Please login."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);

    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        _error("This email is already used.");
      } else {
        _error(e.message ?? "Signup failed.");
      }
    } catch (e) {
      _error("Error: $e");
    }

    setState(() => isLoading = false);
  }

  // -----------------------------------------------------
  // ERROR MESSAGE
  // -----------------------------------------------------
  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // -----------------------------------------------------
  // INPUT FIELD WIDGET
  // -----------------------------------------------------
  Widget _input(
    String label,
    TextEditingController controller,
    bool isDark, {
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: onToggle != null
                  ? IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
