import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  // -------------------------------------------------------------------------
  // DELETE ACCOUNT
  // -------------------------------------------------------------------------
  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnack(context, "No user found.", isError: true);
      return;
    }

    try {
      // DELETE USER DOCUMENTS
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .delete();

      await FirebaseFirestore.instance
          .collection("doctors")
          .doc(user.uid)
          .delete();

      // DELETE AUTH USER
      await user.delete();

      // SIGN OUT
      await FirebaseAuth.instance.signOut();

      _showSnack(context, "Account deleted successfully!");

      // REDIRECT TO LOGIN PAGE
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);

    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        _showSnack(
          context,
          "Please log in again before deleting your account.",
          isError: true,
        );
      } else {
        _showSnack(context, "Error: ${e.message}", isError: true);
      }
    } catch (e) {
      _showSnack(context, "Unexpected error: $e", isError: true);
    }
  }

  // -------------------------------------------------------------------------
  // CONFIRMATION POPUP
  // -------------------------------------------------------------------------
  void _confirmDelete(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.black87 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Are you sure?",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This action cannot be undone.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _deleteAccount(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // SNACKBAR
  // -------------------------------------------------------------------------
  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PAGE TITLE
          Text(
            "Delete Account",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2E2A85),
            ),
          ),

          const SizedBox(height: 40),

          Center(
            child: Container(
              width: 500,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  // ARE YOU SURE
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Are you sure",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF2E2A85),
                          ),
                        ),
                        TextSpan(
                          text: "?",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // IMAGE
                  Image.asset(
                    "assets/images/delete_account.png",
                    height: 140,
                  ),

                  const SizedBox(height: 35),

                  // DELETE BUTTON
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () => _confirmDelete(context),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2E2A85),
                              Color(0xFF2E8AF1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: const Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
