// NEW FILE | Extends: flutter_app/lib/screens/citizen/citizen_home_screen.dart
// Citizen Dashboard with stats and navigation

import 'package:flutter/material.dart';
import '../../services/firebase_auth_service_new.dart';
import '../../services/report_service_new.dart';
import 'report_screen_new.dart';
import 'my_reports_screen_new.dart';
import 'map_screen_new.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  int _currentIndex = 0;
  List<dynamic> _recentReports = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF77B6EA);
  final Color bgColor = const Color(0xFFE8EEF2);
  final Color cardColor = const Color(0xFFC7D3DD);
  final Color textColor = const Color(0xFF37393A);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final reports = await reportApi.getMyReports();
    if (mounted) {
      setState(() {
        _recentReports = reports.take(5).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = firebaseAuthService.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Road Monitor",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => firebaseAuthService.signOut(),
            icon: Icon(Icons.logout, color: textColor),
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildHomeTab(user) : _buildOtherTabs(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.5),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add_photo_alternate), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildHomeTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, ${user?.displayName ?? 'Citizen'}!",
            style: TextStyle(fontSize: 22, color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Stats Row
          Row(
            children: [
              _buildStatCard("Total", "${_recentReports.length}", Colors.blue),
              _buildStatCard("Pending", "2", Colors.orange), // Static for now
              _buildStatCard("Fixed", "1", Colors.green),   // Static for now
            ],
          ),
          
          const SizedBox(height: 30),
          Text(
            "Recent Reports",
            style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _recentReports.isEmpty
                ? const Center(child: Text("No reports yet."))
                : Column(
                    children: _recentReports.map((r) => _buildReportItem(r)).toList(),
                  ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(dynamic report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          report['image_url'] != null 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(report['image_url'], width: 50, height: 50, fit: BoxFit.cover),
              )
            : Icon(Icons.image_not_supported, size: 50, color: cardColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['category'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(report['status'] ?? "pending", style: TextStyle(fontSize: 12, color: primaryColor)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildOtherTabs() {
    switch (_currentIndex) {
      case 1: return const ReportScreenNew();
      case 2: return const MapScreenNew();
      default: return const MyReportsScreenNew();
    }
  }
}
