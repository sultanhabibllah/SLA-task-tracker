import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatusGrid(),
              const SizedBox(height: 24),
              
              // Overdue Tasks Section
              _buildSectionHeader(
                title: "Overdue Tasks (2)",
                icon: Icons.error_outline,
                iconColor: const Color(0xFFDC3545),
                headerBgColor: const Color(0xFFFFF5F5),
              ),
              const SizedBox(height: 8),
              _buildTaskCard(
                title: "Test Application",
                subtitle: "Quality Assurance • Mobile App",
                timeText: "3 days ago",
                timeColor: const Color(0xFFDC3545),
                leadingIcon: Icons.science_outlined,
                avatarUrl: "https://pravatar.cc",
              ),
              
              const SizedBox(height: 20),
  
              // At Risk Tasks Section
              _buildSectionHeader(
                title: "At Risk Tasks (3)",
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFFC107),
                headerBgColor: const Color(0xFFFFF9E6),
              ),
              const SizedBox(height: 8),
              _buildTaskCard(
                title: "Implement Local Storage",
                subtitle: "Mobile App • Development",
                timeText: "Due in 2 days",
                timeColor: const Color(0xFFFFC107),
                leadingIcon: Icons.storage_outlined,
                avatarUrl: "https://pravatar.cc",
              ),
              
              const SizedBox(height: 20),
  
              // Upcoming Deadlines Section
              _buildSectionHeader(
                title: "Upcoming Deadlines (4)",
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF0D6EFD),
                headerBgColor: const Color(0xFFF0F5FF),
              ),
              const SizedBox(height: 8),
              _buildTaskCard(
                title: "Design Login Screen",
                subtitle: "UI/UX Design • Mobile App",
                timeText: "10 Dec 2024\n2 days left",
                timeColor: Colors.grey.shade600,
                leadingIcon: Icons.description_outlined,
                avatarUrl: "https://pravatar.cc",
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Modules ---

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts & Attention',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.extrabold, color: Color(0xFF0F172A)),
        ),
        SizedBox(height: 4),
        Text(
          'Stay on top of important updates\nand upcoming deadlines.',
          style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildStatusGrid() {
    return Row(
      children: [
        Expanded(child: _buildGridItem("2", "Overdue", const Color(0xFFDC3545), Icons.error_outline, const Color(0xFFFFF5F5))),
        const SizedBox(width: 10),
        Expanded(child: _buildGridItem("3", "At Risk", const Color(0xFFFFC107), Icons.warning_amber_rounded, const Color(0xFFFFF9E6))),
        const SizedBox(width: 10),
        Expanded(child: _buildGridItem("4", "Upcoming", const Color(0xFF0D6EFD), Icons.calendar_today_outlined, const Color(0xFFF0F5FF))),
        const SizedBox(width: 10),
        Expanded(child: _buildGridItem("8", "On Track", const Color(0xFF198754), Icons.check_circle_outline, const Color(0xFFE8F5E9))),
      ],
    );
  }

  Widget _buildGridItem(String count, String label, Color color, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color headerBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const Spacer(),
          Text(
            "View all",
            style: TextStyle(fontSize: 12, color: iconColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 10, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required String timeText,
    required Color timeColor,
    required IconData leadingIcon,
    required String avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leadingIcon, color: const Color(0xFF334155), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(height: 6),
              Text(
                timeText,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: timeColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
