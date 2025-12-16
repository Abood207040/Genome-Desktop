import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../controllers/theme_controller.dart';
import '../../../widgets/app_background.dart';

class AppointmentsScreen extends StatefulWidget {
  final String? initialStatusFilter;

  const AppointmentsScreen({super.key, this.initialStatusFilter});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String searchQuery = "";
  String selectedSortOption = "Newest";
  String selectedStatusFilter = "All";

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      selectedStatusFilter = widget.initialStatusFilter!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final bool isDark = themeController.themeMode == ThemeMode.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF272A4F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appointments',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: AppBackground(
        child: user == null
            ? const Center(child: Text("Not authenticated"))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    // 🔍 Search + Sort
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                searchQuery = value;
                                if (_debounce?.isActive ?? false) {
                                  _debounce!.cancel();
                                }
                                _debounce = Timer(
                                  const Duration(milliseconds: 400),
                                  () => setState(() {}),
                                );
                              },
                              decoration: const InputDecoration(
                                labelText:
                                    'Search by Patient, Doctor, or Phone',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              Icons.sort,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            onPressed: _showSortDialog,
                          ),
                        ],
                      ),
                    ),

                    // 📡 REAL-TIME STREAM
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("appointments")
                            .where("doctorId", isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text("No appointments found"));
                          }

                          final filteredAppointments =
                              _applyFilters(snapshot.data!.docs);

                          if (filteredAppointments.isEmpty) {
                            return const Center(
                                child: Text("No appointments found"));
                          }

                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                            ),
                            itemCount: filteredAppointments.length,
                            itemBuilder: (_, i) => _appointmentCard(
                              filteredAppointments[i],
                              isDark,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ===============================
  // 🔍 Filter + Sort (PURE FUNCTION)
  // ===============================
  List<DocumentSnapshot> _applyFilters(
      List<DocumentSnapshot> source) {
    List<DocumentSnapshot> temp = List.from(source);

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      temp = temp.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data["patientName"] ?? "").toLowerCase().contains(q) ||
            (data["doctorName"] ?? "").toLowerCase().contains(q) ||
            (data["phone"] ?? "").toLowerCase().contains(q);
      }).toList();
    }

    if (selectedStatusFilter != "All") {
      temp = temp.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data["status"] == selectedStatusFilter;
      }).toList();
    }

    temp.sort((a, b) {
      final ta =
          (a["createdAt"] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final tb =
          (b["createdAt"] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);

      return selectedSortOption == "Newest"
          ? tb.compareTo(ta)
          : ta.compareTo(tb);
    });

    return temp;
  }

  // ===============================
  // 🧾 Appointment Card
  // ===============================
  Widget _appointmentCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFB4B7DB).withOpacity(0.45),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C4A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["patientName"] ?? "",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data["phone"] ?? "",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Dr. ${data["doctorName"] ?? "Unknown"}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection("appointments")
                      .doc(doc.id)
                      .delete();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Text(
                "${data['date']} ${data['time']}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFB4B7DB).withOpacity(0.5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: data["status"],
                items: ["Pending", "Approved", "Done", "Cancel"]
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: s == "Done"
                                  ? Colors.green
                                  : s == "Approved"
                                      ? Colors.blue
                                      : s == "Cancel"
                                          ? Colors.red
                                          : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s,
                              style:
                                  const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  FirebaseFirestore.instance
                      .collection("appointments")
                      .doc(doc.id)
                      .update({"status": v});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🔽 Sort & Filter Dialog
  // ===============================
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sort & Filter"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOption("Newest"),
            _sortOption("Oldest"),
            const Divider(),
            _filterOption("All"),
            _filterOption("Pending"),
            _filterOption("Approved"),
            _filterOption("Done"),
            _filterOption("Cancel"),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String text) => ListTile(
        title: Text(text),
        onTap: () {
          setState(() => selectedSortOption = text);
          Navigator.pop(context);
        },
      );

  Widget _filterOption(String status) => ListTile(
        title: Text(status),
        onTap: () {
          setState(() => selectedStatusFilter = status);
          Navigator.pop(context);
        },
      );
}
