import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/app_background.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int pendingAppointmentsCount = 0;
  bool showPendingAppointments = false;
  List<DocumentSnapshot> pendingAppointments = [];
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;
  final Set<String> _notifiedAppointmentIds = {}; // Track notified appointments

  @override
  void initState() {
    super.initState();
    _fetchPendingAppointmentsCount();
    _setupAppointmentNotifications();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  void _setupAppointmentNotifications() {
    // Listen for new appointments
    _appointmentsSubscription = FirebaseFirestore.instance
        .collection("appointments")
        .snapshots()
        .listen((snapshot) {
          for (var docChange in snapshot.docChanges) {
            if (docChange.type == DocumentChangeType.added) {
              final data = docChange.doc.data() as Map<String, dynamic>;
              final appointmentId = docChange.doc.id;

              // Only notify if we haven't notified about this appointment before
              if (!_notifiedAppointmentIds.contains(appointmentId)) {
                _notifiedAppointmentIds.add(appointmentId);

                // Show notification for new appointment
                NotificationService().showAppointmentNotification(
                  patientName: data['patientName'] ?? 'Unknown Patient',
                  appointmentTime: data['time'] ?? 'Unknown Time',
                  appointmentDate: data['date'] ?? 'Unknown Date',
                );
              }
            }
          }
        });
  }

  Future<void> _fetchPendingAppointmentsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("appointments")
        .where("status", isEqualTo: "Pending")
        .get();

    setState(() {
      pendingAppointmentsCount = snapshot.docs.length;
      pendingAppointments = snapshot.docs;
    });
  }

  void _togglePendingAppointments() {
    setState(() {
      showPendingAppointments = !showPendingAppointments;
    });
  }

  Future<void> _updateAppointmentStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection("appointments")
        .doc(docId)
        .update({"status": newStatus});

    // Refresh the pending appointments
    await _fetchPendingAppointmentsCount();

    if (pendingAppointmentsCount == 0) {
      setState(() {
        showPendingAppointments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final bool isDark = themeController.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height + 100, // Add extra height to prevent overflow
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const CustomAppBar(activePage: "Home"),

              // Welcome Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to GENORA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'where your genetic data transforms into clear answers for a healthier future.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced Dashboard Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Top Row - Key Metrics
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _togglePendingAppointments,
                            child: _buildEnhancedDashboardCard(
                              title: 'Pending Appointments',
                              value: pendingAppointmentsCount.toString(),
                              subtitle: 'Requires attention',
                              icon: Icons.schedule,
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection("appointments").snapshots(),
                            builder: (context, snapshot) {
                              int totalAppointments = snapshot.data?.docs.length ?? 0;
                              return _buildEnhancedDashboardCard(
                                title: 'Total Appointments',
                                value: totalAppointments.toString(),
                                subtitle: 'All time',
                                icon: Icons.calendar_today,
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.indigo],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Second Row - Daily Stats
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection("appointments").snapshots(),
                            builder: (context, snapshot) {
                              int todayAppointments = 0;
                              if (snapshot.hasData) {
                                String today = DateTime.now().toString().split(' ')[0];
                                todayAppointments = snapshot.data!.docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return data['date'] == today;
                                }).length;
                              }
                              return _buildEnhancedDashboardCard(
                                title: 'Today\'s Appointments',
                                value: todayAppointments.toString(),
                                subtitle: 'Scheduled',
                                icon: Icons.today,
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Colors.teal],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("appointments")
                                .where("status", isEqualTo: "Done")
                                .snapshots(),
                            builder: (context, snapshot) {
                              int completedAppointments = snapshot.data?.docs.length ?? 0;
                              return _buildEnhancedDashboardCard(
                                title: 'Completed',
                                value: completedAppointments.toString(),
                                subtitle: 'Successfully done',
                                icon: Icons.check_circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.teal, Colors.cyan],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Users Statistics Section
                    Text(
                      'User Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Doctors Count
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .where("role", isEqualTo: "doctor")
                                .snapshots(),
                            builder: (context, snapshot) {
                              int doctorsCount = snapshot.data?.docs.length ?? 0;
                              return _buildUserStatsCard(
                                title: 'Doctors',
                                value: doctorsCount.toString(),
                                icon: Icons.medical_services,
                                color: Colors.purple,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Patients Count
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .where("role", isEqualTo: "patient")
                                .snapshots(),
                            builder: (context, snapshot) {
                              int patientsCount = snapshot.data?.docs.length ?? 0;
                              return _buildUserStatsCard(
                                title: 'Patients',
                                value: patientsCount.toString(),
                                icon: Icons.people,
                                color: Colors.indigo,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Total Users
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection("users").snapshots(),
                            builder: (context, snapshot) {
                              int totalUsers = snapshot.data?.docs.length ?? 0;
                              return _buildUserStatsCard(
                                title: 'Total Users',
                                value: totalUsers.toString(),
                                icon: Icons.group,
                                color: Colors.amber,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Chat & Communication Stats
                    Text(
                      'Communication Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Active Chats
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection("chats").snapshots(),
                            builder: (context, snapshot) {
                              int totalChats = snapshot.data?.docs.length ?? 0;
                              return _buildCommunicationCard(
                                title: 'Active Conversations',
                                value: totalChats.toString(),
                                subtitle: 'Doctor-Patient chats',
                                icon: Icons.chat,
                                color: Colors.blue,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Unread Messages
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection("chats").snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData) {
                                // TODO: Implement unread message count logic
                                // Count chats where last sender is not the current user (doctor)
                                // This is a simplified version - in real app you'd check per user
                              }
                              return _buildCommunicationCard(
                                title: 'Unread Messages',
                                value: unreadCount.toString(),
                                subtitle: 'Requires response',
                                icon: Icons.mark_email_unread,
                                color: Colors.red,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Genetic Analysis Statistics
                    Text(
                      'Genetic Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Genetic Tests Count
                        Expanded(
                          child: _buildGeneticCard(
                            title: 'Genetic Tests',
                            value: '24',
                            subtitle: 'Completed this month',
                            icon: Icons.biotech,
                            color: Colors.pink,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Reports Generated
                        Expanded(
                          child: _buildGeneticCard(
                            title: 'PDF Reports',
                            value: '18',
                            subtitle: 'Generated reports',
                            icon: Icons.description,
                            color: Colors.deepPurple,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Success Rate
                        Expanded(
                          child: _buildGeneticCard(
                            title: 'Success Rate',
                            value: '98%',
                            subtitle: 'Analysis accuracy',
                            icon: Icons.trending_up,
                            color: Colors.green,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // System Health & Performance
                    Text(
                      'System Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSystemCard(
                            title: 'Server Status',
                            status: 'Online',
                            icon: Icons.cloud_done,
                            color: Colors.green,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSystemCard(
                            title: 'Database',
                            status: 'Healthy',
                            icon: Icons.storage,
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSystemCard(
                            title: 'AI Models',
                            status: 'Active',
                            icon: Icons.psychology,
                            color: Colors.orange,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions & Analytics Row
                    Row(
                      children: [
                        Expanded(child: _buildEnhancedQuickActionsCard(isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEnhancedAnalyticsCard(isDark)),
                      ],
                    ),
                  ],
                ),
              ),

              // Pending Appointments Section (shown when clicked)
              if (showPendingAppointments) ...[
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pending Appointments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: _togglePendingAppointments,
                            icon: Icon(
                              Icons.close,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (pendingAppointments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No pending appointments!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildPendingAppointmentCard(
                              pendingAppointments[index],
                              isDark,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Recent Activity Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("appointments")
                          .orderBy('timestamp', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No recent activity',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return _buildActivityCard(data, isDark);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

                  // Analytic Shapes/Visual Elements Section
              _buildAnalyticShapesSection(isDark),

              const SizedBox(height: 20),

              // Additional Analytics Section
              _buildProgressAnalyticsSection(isDark),

              // Bottom padding to prevent overflow (65px as requested - 30px + 35px)
              const SizedBox(height: 65),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticShapesSection(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("appointments").snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        // Status counts
        int done = 0, approved = 0, pending = 0, cancelled = 0;

        // Last 5 months data (oldest -> newest)
        final now = DateTime.now();
        final monthLabels = <String>[];
        final monthCounts = List<int>.filled(5, 0);
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];

        for (int i = 4; i >= 0; i--) {
          final dt = DateTime(now.year, now.month - i, 1);
          monthLabels.add(monthNames[dt.month - 1]);
        }

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = (data['status'] ?? '').toString();
          switch (status) {
            case 'Done':
              done++;
              break;
            case 'Approved':
              approved++;
              break;
            case 'Pending':
              pending++;
              break;
            case 'Cancel':
            case 'Cancelled':
              cancelled++;
              break;
          }

          final dateStr = data['date']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            DateTime? dt;
            dt = DateTime.tryParse(dateStr);
            if (dt == null) {
              final parts = dateStr.split('-');
              if (parts.length >= 3) {
                final y = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                final d = int.tryParse(parts[2]);
                if (y != null && m != null && d != null) {
                  dt = DateTime(y, m, d);
                }
              }
            }
            if (dt != null) {
              final diff = (now.year * 12 + now.month) - (dt.year * 12 + dt.month);
              if (diff >= 0 && diff < 5) {
                // Newest at end of array
                monthCounts[4 - diff] = monthCounts[4 - diff] + 1;
              }
            }
          }
        }

        int totalStatus = done + approved + pending + cancelled;
        String pct(int count) {
          if (totalStatus == 0) return '0%';
          return '${((count / totalStatus) * 100).toStringAsFixed(0)}%';
        }

        final maxMonth = monthCounts.fold<int>(0, (p, c) => c > p ? c : p);
        double ratio(int count) {
          if (maxMonth == 0) return 0.1;
          final r = count / maxMonth;
          // keep a small margin to avoid overflow in tight layouts
          return (r * 0.9).clamp(0.05, 1.0);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF272A4F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Analytics Visual Elements
              Row(
                children: [
                  // Left side - Charts/Shapes
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Bar Chart - monthly trends (live)
                        Container(
                          height: 170,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Trends',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    monthCounts.length,
                                    (i) => _buildBar(
                                      ratio(monthCounts[i]),
                                      [
                                        Colors.blue,
                                        Colors.green,
                                        Colors.orange,
                                        Colors.purple,
                                        Colors.red
                                      ][i % 5],
                                      monthLabels[i],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Pie Chart - live status distribution
                        Container(
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildPieSlice(Colors.green, 'Done', pct(done)),
                                    const SizedBox(width: 8),
                                    _buildPieSlice(Colors.blue, 'Approved', pct(approved)),
                                    const SizedBox(width: 8),
                                    _buildPieSlice(Colors.orange, 'Pending', pct(pending)),
                                    const SizedBox(width: 8),
                                    _buildPieSlice(Colors.red, 'Cancelled', pct(cancelled)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Right side - Metrics Cards (derived)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Growth Indicator (month over month trend)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Colors.teal],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      docs.isEmpty ? '+0%' : '+${(ratio(monthCounts.last) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Growth Rate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Performance Score (completion ratio)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.indigo],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      totalStatus == 0
                                          ? '0%'
                                          : '${((done / (totalStatus)) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Completion',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Efficiency Metric (approved share)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.deepPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.speed,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      totalStatus == 0
                                          ? '0%'
                                          : '${((approved / totalStatus) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Approval Share',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressAnalyticsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.show_chart,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bars Section
          Row(
            children: [
              // Left side - Progress indicators
              Expanded(
                child: Column(
                  children: [
                    _buildProgressIndicator(
                      'Patient Satisfaction',
                      0.92,
                      Colors.green,
                      '92%',
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressIndicator(
                      'Appointment Success',
                      0.87,
                      Colors.blue,
                      '87%',
                      isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressIndicator(
                      'Response Time',
                      0.78,
                      Colors.orange,
                      '78%',
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right side - Circular progress indicators
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCircularProgress('Daily', 0.85, Colors.purple, isDark),
                        _buildCircularProgress('Weekly', 0.92, Colors.teal, isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCircularProgress('Monthly', 0.88, Colors.indigo, isDark),
                        _buildCircularProgress('Yearly', 0.95, Colors.green, isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Trend indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrendIndicator('Appointments', '+12%', Colors.green, Icons.trending_up, isDark),
                _buildTrendIndicator('Revenue', '+8%', Colors.blue, Icons.trending_up, isDark),
                _buildTrendIndicator('Efficiency', '+15%', Colors.orange, Icons.trending_up, isDark),
                _buildTrendIndicator('Satisfaction', '+5%', Colors.purple, Icons.trending_up, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String title, double progress, Color color, String percentage, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress(String label, double progress, Color color, bool isDark) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(String title, String value, Color color, IconData icon, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBar(double height, Color color, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 100 * height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPieSlice(Color color, String label, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required bool isDark,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneticCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActionsCard(bool isDark) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.electric_bolt,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedQuickActionButton(
                    icon: Icons.calendar_today,
                    label: 'New Appointment',
                    onTap: () => Navigator.pushNamed(context, '/appointments'),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.indigo],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEnhancedQuickActionButton(
                    icon: Icons.chat,
                    label: 'Doctor Chat',
                    onTap: () => Navigator.pushNamed(context, '/doctor-chat'),
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedQuickActionButton(
                    icon: Icons.upload_file,
                    label: 'Upload File',
                    onTap: () => Navigator.pushNamed(context, '/upload-file'),
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEnhancedQuickActionButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    gradient: const LinearGradient(
                      colors: [Colors.grey, Colors.blueGrey],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAnalyticsCard(bool isDark) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("appointments").snapshots(),
                    builder: (context, snapshot) {
                      int todayAppointments = 0;
                      if (snapshot.hasData) {
                        String today = DateTime.now().toString().split(' ')[0]; // Get today's date in YYYY-MM-DD format
                        todayAppointments = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final appointmentDate = data['date']?.toString();
                          return appointmentDate == today;
                        }).length;
                      }
                      return _buildEnhancedAnalyticsItem(
                        'Today',
                        todayAppointments.toString(),
                        Colors.purple,
                        isDark,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("appointments").snapshots(),
                    builder: (context, snapshot) {
                      int completedAppointments = 0;
                      if (snapshot.hasData) {
                        completedAppointments = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['status'] == 'Done';
                        }).length;
                      }
                      return _buildEnhancedAnalyticsItem(
                        'Completed',
                        completedAppointments.toString(),
                        Colors.indigo,
                        isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEnhancedQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAnalyticsItem(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPendingAppointmentCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C4A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["patientName"] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      data["phone"] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                "${data['date'] ?? ''} ${data['time'] ?? ''}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateAppointmentStatus(doc.id, 'Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateAppointmentStatus(doc.id, 'Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data, bool isDark) {
    final status = data['status'] ?? 'Unknown';
    final patientName = data['patientName'] ?? 'Unknown';
    final date = data['date'] ?? '';
    final time = data['time'] ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Approved':
        statusColor = Colors.blue;
        statusIcon = Icons.approval;
        break;
      case 'Cancel':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF272A4F) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$patientName - $status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '$date $time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
