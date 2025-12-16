import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/theme_controller.dart';
import '../../widgets/app_background.dart';
import '../../services/notification_service.dart';
import 'DoctorChatScreen.dart';

class DoctorInboxPage extends StatefulWidget {
  const DoctorInboxPage({super.key});

  @override
  State<DoctorInboxPage> createState() => _DoctorInboxPageState();
}

class _DoctorInboxPageState extends State<DoctorInboxPage> {
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  final Set<String> _notifiedMessageIds = {}; // Track notified messages
  late String doctorId;

  @override
  void initState() {
    super.initState();
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor != null) {
      doctorId = doctor.uid;
      _setupChatNotifications();
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _setupChatNotifications() {
    // Listen for new messages in all chats for this doctor
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .listen((chatSnapshot) {
          for (var chatDoc in chatSnapshot.docs) {
            // Listen to messages subcollection for each chat
            FirebaseFirestore.instance
                .collection('chats')
                .doc(chatDoc.id)
                .collection('messages')
                .snapshots()
                .listen((messageSnapshot) {
                  for (var docChange in messageSnapshot.docChanges) {
                    if (docChange.type == DocumentChangeType.added) {
                      final messageData = docChange.doc.data() as Map<String, dynamic>;
                      final messageId = docChange.doc.id;
                      final senderId = messageData['senderId'] as String?;
                      final text = messageData['text'] as String? ?? '';

                      // Only notify if message is not from the doctor (i.e., from patient)
                      // and we haven't notified about this message before
                      if (senderId != doctorId && !_notifiedMessageIds.contains(messageId)) {
                        _notifiedMessageIds.add(messageId);

                        final chatData = chatDoc.data() as Map<String, dynamic>;
                        final patientName = chatData['patientName'] as String? ?? 'Patient';

                        // Show notification for new chat message
                        NotificationService().showChatNotification(
                          senderName: patientName,
                          message: text,
                        );
                      }
                    }
                  }
                });
          }
        });
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return "";
      DateTime dt;
      if (ts is Timestamp) dt = ts.toDate();
      else if (ts is DateTime) dt = ts;
      else if (ts is int) dt = DateTime.fromMillisecondsSinceEpoch(ts);
      else return "";
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        return "${dt.day}/${dt.month}/${dt.year}";
      }
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.themeMode == ThemeMode.dark;

    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    final doctorId = doctor.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFF2E3164),
        title: const Text("Patient Messages",
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),

      // 🔵 Background Applied Here
      body: AppBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('doctorId', isEqualTo: doctorId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error loading chats:\n${snapshot.error}"),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat_bubble_outline,
                        size: 60, color: Color(0xFFBDBCE6)),
                    SizedBox(height: 12),
                    Text(
                      "No patient conversations yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // SORT BY updatedAt DESC
            docs.sort((a, b) {
              final aMap = a.data() as Map<String, dynamic>? ?? {};
              final bMap = b.data() as Map<String, dynamic>? ?? {};
              final aTs = aMap['updatedAt'] ?? aMap['createdAt'];
              final bTs = bMap['updatedAt'] ?? bMap['createdAt'];

              try {
                final da = aTs is Timestamp
                    ? aTs.toDate()
                    : DateTime.tryParse(aTs.toString()) ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                final db = bTs is Timestamp
                    ? bTs.toDate()
                    : DateTime.tryParse(bTs.toString()) ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                return db.compareTo(da);
              } catch (_) {
                return 0;
              }
            });

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final patientId = data['patientId']?.toString() ?? 'unknown';
                final patientName =
                    (data['patientName'] as String?)?.trim() ?? 'Patient';
                final lastMessage =
                    (data['lastMessage'] as String?) ?? '(No messages yet)';
                final lastSenderId = data['lastSenderId'] as String?;
                final updatedRaw = data['updatedAt'];
                final previewTime = _formatTimestamp(updatedRaw);

                final isUnread = lastSenderId != doctorId &&
                    lastMessage != "(No messages yet)";

                // Ensure chat has a message before showing
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(doc.id)
                      .collection('messages')
                      .limit(1)
                      .get(),
                  builder: (context, msgSnap) {
                    if (!msgSnap.hasData || msgSnap.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientId)
                          .get(),
                      builder: (context, userSnap) {
                        String finalName = patientName;
                        String patientEmail = "";
                        bool isPatient = true;

                        if (userSnap.hasData && userSnap.data!.exists) {
                          final u = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                          finalName = u['name'] ?? patientName;
                          patientEmail = u['email'] ?? "";
                          isPatient = (u['role'] ?? 'patient') == 'patient';
                        }

                        if (!isPatient) return const SizedBox.shrink();

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorChatScreen(
                                  patientId: patientId,
                                  patientName: finalName,
                                  chatId: doc.id,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnread
                                  ? const Color(0xFFE8F4FD)
                                  : (isDark ? Colors.black12 : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFFBCBEE6),
                                  child: Text(
                                    finalName.isNotEmpty
                                        ? finalName[0].toUpperCase()
                                        : "P",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              finalName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2E3164),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            previewTime,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        patientEmail,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        lastMessage,
                                        style: TextStyle(
                                          color: isUnread
                                              ? Colors.black
                                              : Colors.black87,
                                          fontWeight: isUnread
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
