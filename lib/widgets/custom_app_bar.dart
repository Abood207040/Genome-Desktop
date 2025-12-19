import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatefulWidget {
  final String activePage;

  const CustomAppBar({
    super.key,
    this.activePage = "home",
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _hasUnreadMessages = false;
  bool _hasPendingAppointments = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _unreadSubscription;
  StreamSubscription<QuerySnapshot>? _appointmentSubscription;

  @override
  void initState() {
    super.initState();
    print("CustomAppBar: initState called");
    _setupUnreadMessagesListener();
    _setupAppointmentListener();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _appointmentSubscription?.cancel();
    super.dispose();
  }

  void _setupUnreadMessagesListener() {
    final user = _auth.currentUser;
    if (user == null) {
      print("CustomAppBar: No user logged in");
      return;
    }

    final doctorId = user.uid;
    print("CustomAppBar: Setting up unread listener for doctorId: $doctorId");

    _unreadSubscription = _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .listen((snapshot) async {
          print("CustomAppBar: Received ${snapshot.docs.length} chats for doctor");
          bool hasUnread = false;

          for (final doc in snapshot.docs) {
            final chatData = doc.data();
            final lastSenderId = chatData['lastSenderId'];
            final patientId = chatData['patientId'];

            print("CustomAppBar: Chat ${doc.id} - lastSenderId: $lastSenderId, patientId: $patientId, doctorId: $doctorId");

            // Check if the last message was sent by patient (not by doctor)
            if (lastSenderId != null && lastSenderId != doctorId) {
              print("CustomAppBar: Found unread message in chat ${doc.id} (lastSenderId: $lastSenderId != doctorId: $doctorId)");
              hasUnread = true;
              break;
            }
          }

          print("CustomAppBar: Final unread status: $hasUnread");

          if (mounted) {
            setState(() {
              _hasUnreadMessages = hasUnread;
            });
            print("CustomAppBar: Updated unread status to: $_hasUnreadMessages");
          }
        }, onError: (error) {
          print("CustomAppBar: Error listening for unread messages: $error");
        });
  }

  void _setupAppointmentListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen for pending appointments assigned to this doctor
    _appointmentSubscription = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
          final hasPending = snapshot.docs.isNotEmpty;
          if (mounted) {
            setState(() {
              _hasPendingAppointments = hasPending;
            });
          }
        }, onError: (error) {
          print("CustomAppBar: Error listening for appointments: $error");
        });
  }

  // ===============================
  //      GET USER NAME
  // ===============================
  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Doctor";

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (snap.exists && snap.data()!.containsKey("name")) {
      return snap["name"];
    }

    return user.displayName ?? "Doctor";
  }

  // ===============================
  //      LOGOUT
  // ===============================
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/auth",
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    print("CustomAppBar: Building with _hasUnreadMessages = $_hasUnreadMessages");
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color textColor = isDark ? Colors.white : Colors.black87;
    Color activeColor = isDark ? Colors.white : const Color(0xFF2E2A85);

    final user = FirebaseAuth.instance.currentUser;
    String userEmail = user?.email ?? "";

    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.35),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),

      child: Row(
        children: [
          // LOGO
          Image.asset(
            "assets/images/genora_logo.png",
            height: 38,
            color: isDark ? Colors.white : null,
          ),

          const SizedBox(width: 12),

          Text(
            "GENORA",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2F2A85),
            ),
          ),

          const SizedBox(width: 40),

          // ===============================
          //       NAVIGATION BAR
          // ===============================
          _navItem(context, "Home", "/home", textColor, activeColor),
          _navItem(
              context, "Patient Disease", "/patient-disease", textColor, activeColor),
          _navItem(
              context, "Child Genetics", "/child-genetics", textColor, activeColor),
          _navItem(
            context,
            "Appointments",
            "/appointments",
            textColor,
            activeColor,
            hasUnread: _hasPendingAppointments,
          ),
          _navItem(context, "Doctor Chat", "/doctor-chat", textColor, activeColor, hasUnread: _hasUnreadMessages),
          _navItem(context, "Settings", "/settings", textColor, activeColor),
          _navItem(context, "Upload File", "/upload-file", textColor, activeColor),

          const Spacer(),

          // ===============================
          //      USER MENU (AVATAR)
          // ===============================
          FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) {
              String userName = snapshot.data ?? "Doctor";

              return PopupMenuButton<int>(
                offset: const Offset(0, 55),
                color: isDark ? Colors.black87 : Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                onSelected: (value) {
                  if (value == 1) _logout(context);
                },

                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            size: 20, color: Colors.red.shade400),
                        const SizedBox(width: 10),
                        const Text(
                          "Logout",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor:
                            isDark ? Colors.white24 : Colors.black12,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===============================
  //         NAV ITEM WIDGET
  // ===============================
  Widget _navItem(
    BuildContext context,
    String title,
    String pageRoute,
    Color textColor,
    Color activeColor, {
    bool hasUnread = false,
  }) {
    bool isActive = (title == widget.activePage);

    if (title == "Doctor Chat") {
      print("CustomAppBar: Rendering Doctor Chat nav item, hasUnread: $hasUnread, _hasUnreadMessages: $_hasUnreadMessages");
    }

    return InkWell(
      onTap: () {
        if (!isActive) {
          // Clear indicators when user opens the related page
          if (title == "Doctor Chat") {
            setState(() {
              _hasUnreadMessages = false;
            });
          } else if (title == "Appointments") {
            setState(() {
              _hasPendingAppointments = false;
            });
          }
          Navigator.pushNamed(context, pageRoute);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : textColor,
                decoration: isActive ? TextDecoration.underline : null,
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
