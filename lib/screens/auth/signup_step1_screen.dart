import 'package:flutter/material.dart';
import 'package:genome/screens/auth/signup_step2_screen.dart';
import '../../widgets/app_background.dart';

class SignUpStep1 extends StatefulWidget {
  const SignUpStep1({super.key});

  @override
  State<SignUpStep1> createState() => _SignUpStep1State();
}

class _SignUpStep1State extends State<SignUpStep1> {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController jobNumber = TextEditingController();
  final TextEditingController dob = TextEditingController();

  /// DATE PICKER FUNCTION
  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.white),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dob.text = "${picked.year}-${picked.month}-${picked.day}";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Row(
          children: [
            /// LEFT ILLUSTRATION
            Expanded(
              child: Image.asset(
                "assets/images/signup_art.png",
                width: 420,
                fit: BoxFit.contain,
              ),
            ),

            /// RIGHT FORM PANEL
            Expanded(
              child: Center(
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /// BACK BUTTON
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        /// TITLE
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
                          "Ready to explore more about what makes you, you?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 35),

                        /// FULL NAME
                        _input("Full Name", fullName, isDark),
                        const SizedBox(height: 18),

                        /// EMAIL
                        _input("Email", email, isDark),
                        const SizedBox(height: 18),

                        /// JOB NUMBER
                        _input("Job Number", jobNumber, isDark),
                        const SizedBox(height: 18),

                        /// DATE OF BIRTH
                        _dobInput(isDark),

                        const SizedBox(height: 30),

                        /// CONTINUE BUTTON
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
                            onPressed: _goToNext,
                            child: const Text(
                              "continue",
                              style: TextStyle(
                                  fontSize: 17, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// LOGIN INSTEAD
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, "/login"),
                          child: Text(
                            "Already have an account? Login",
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              color: isDark ? Colors.white70 : Colors.black87,
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

  /// -------------------------------------------------
  /// VALIDATION & NAVIGATION
  /// -------------------------------------------------
  void _goToNext() {
    if (fullName.text.isEmpty ||
        email.text.isEmpty ||
        jobNumber.text.isEmpty ||
        dob.text.isEmpty) {
      return _error("Please fill all fields.");
    }

    if (fullName.text.trim().length < 3) {
      return _error("Full name must be at least 3 characters.");
    }

    if (!email.text.contains("@") || !email.text.contains(".")) {
      return _error("Please enter a valid email address.");
    }

    if (jobNumber.text.length < 3) {
      return _error("Job number is too short.");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpStep2(
          fullName: fullName.text.trim(),
          email: email.text.trim(),
          jobNumber: jobNumber.text.trim(),
          dob: dob.text.trim(),
        ),
      ),
    );
  }

  /// ERROR MESSAGE
  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /// -------------------------------------------------
  /// INPUT FIELD UI
  /// -------------------------------------------------
  Widget _input(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// DOB FIELD
  Widget _dobInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date Of Birth",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.10) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dob.text.isEmpty
                      ? "Select your birth date"
                      : dob.text,
                  style: TextStyle(
                    color: dob.text.isEmpty
                        ? Colors.grey
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                Icon(
                  Icons.calendar_month,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
