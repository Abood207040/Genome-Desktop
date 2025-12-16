import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorChatScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String chatId;

  const DoctorChatScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.chatId,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  late String doctorId;
  bool _chatReady = false;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return;
    }

    doctorId = user.uid;
    _ensureChatDoc();
  }

  Future<void> _ensureChatDoc() async {
    try {
      final docRef = _firestore.collection('chats').doc(widget.chatId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        await docRef.set({
          'patientId': widget.patientId,
          'doctorId': doctorId,
          'patientName': widget.patientName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'patientId': widget.patientId,
          'doctorId': doctorId,
          'patientName': widget.patientName,
        }, SetOptions(merge: true));
      }

      setState(() => _chatReady = true);
    } catch (e) {
      setState(() => _chatReady = true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      final messagesRef =
          _firestore.collection('chats').doc(widget.chatId).collection('messages');

      await messagesRef.add({
        'senderId': doctorId,
        'receiverId': widget.patientId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(widget.chatId).set({
        'lastMessage': text,
        'lastSenderId': doctorId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to send message")));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_chatReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // ✅ Change background ONLY in dark mode
      backgroundColor: isDark ? const Color(0xFF0D0D12) : const Color(0xFFF3F4FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2E3164),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFBCBEE6),
              child: Text(
                widget.patientName.isNotEmpty
                    ? widget.patientName[0].toUpperCase()
                    : "P",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                      child: Text("No messages yet",
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final raw = docs[i].data() as Map<String, dynamic>;
                    final text = raw['text'] ?? '';
                    final sender = raw['senderId'];
                    final isMe = sender == doctorId;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        isMe
                            ? _sentBubble(text)
                            : _receivedBubble(text),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // MESSAGE INPUT
          SafeArea(
            child: Container(
              color: isDark ? const Color(0xFF1A1B23) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2B33)
                            : const Color(0xFFF0F0FA),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Write a message...",
                          hintStyle: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54),
                          border: InputBorder.none,
                        ),
                        style:
                            TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E3164),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2E3164),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _receivedBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFBCBEE6),
          borderRadius: BorderRadius.circular(18),
        ),
        child:
            Text(text, style: const TextStyle(color: Color(0xFF2E3164))),
      ),
    );
  }
}
