import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genome/screens/homepage.dart';
import '../../widgets/app_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool obscurePass = true;
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
                "assets/images/login_art.png",
                width: 420,
                height: 420,
              ),
            ),

            Expanded(
              child: Center(
                child: Container(
                  width: 480,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Welcome back!",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          "Take the first step towards understanding yourself from the inside out.",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 35),

                        _label("Email", isDark),
                        _input(email, isDark, TextInputType.emailAddress),
                        const SizedBox(height: 20),

                        _label("Password", isDark),
                        _passwordInput(password, isDark),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        Center(
                          child: SizedBox(
                            width: 230,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E2A85),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading ? null : _loginLogic,
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 35),

                        /// Go to signup
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, "/signup");
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Don’t have an account? ",
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(
                                    text: "Sign up",
                                    style: TextStyle(
                                      color: Color(0xFF2E2A85),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // FIREBASE LOGIN + DOCTOR ROLE VALIDATION
  // ---------------------------------------------------
  void _loginLogic() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      _showError("Please enter email & password.");
      return;
    }

    setState(() => isLoading = true);

    try {
      /// LOGIN
      UserCredential creds =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      String uid = creds.user!.uid;

      /// GET USER DOCUMENT
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        _showError("User profile not found in database.");
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        return;
      }

      /// VALIDATE DATA EXISTS
      if (!userDoc.data().toString().contains("role")) {
        _showError("Profile is missing role information.");
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        return;
      }

      String role = userDoc["role"];

      /// ONLY DOCTORS CAN LOGIN
      if (role != "doctor") {
        _showError("This account is not a doctor account.");
        await FirebaseAuth.instance.signOut();
        setState(() => isLoading = false);
        return;
      }

      /// LOGIN SUCCESS → GO TO HOME
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        _showError("No user found with this email.");
      } else if (e.code == "wrong-password") {
        _showError("Incorrect password.");
      } else {
        _showError(e.message ?? "Login failed.");
      }

    } catch (e) {
      _showError("Error: $e");
    }

    setState(() => isLoading = false);
  }

  // ---------------------------------------------------
  // ERROR POPUP
  // ---------------------------------------------------
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ---------------------------------------------------
  // UI INPUT COMPONENTS
  // ---------------------------------------------------
  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _input(TextEditingController controller, bool isDark,
      TextInputType type) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _passwordInput(TextEditingController controller, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscurePass,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
              obscurePass ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => obscurePass = !obscurePass);
            },
          ),
        ),
      ),
    );
  }
}
