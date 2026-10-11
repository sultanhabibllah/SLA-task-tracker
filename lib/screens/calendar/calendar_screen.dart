import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Mock data for the current month days grid
  // In a real application, you would generate this dynamically based on DateTime
  final List<Map<String, dynamic>> _monthDays = [
    {"day": "25", "isCurrentMonth": false, "status": null},
    {"day": "26", "isCurrentMonth": false, "status": null},
    {"day": "27", "isCurrentMonth": false, "status": null},
    {"day": "28", "isCurrentMonth": false, "status": null},
    {"day": "29", "isCurrentMonth": false, "status": null},
    {"day": "30", "isCurrentMonth": false, "status": null},
    {"day": "1", "isCurrentMonth": true, "status": "at_risk"},
    {"day": "2", "isCurrentMonth": true, "status": null},
    {"day": "3", "isCurrentMonth": true, "status": "on_track"},
    {"day": "4", "isCurrentMonth": true, "status": null},
    {"day": "5", "isCurrentMonth": true, "status": "overdue"},
    {"day": "6", "isCurrentMonth": true, "status": null},
    {"day": "7", "isCurrentMonth": true, "status": null},
    {"day": "8", "isCurrentMonth": true, "status": "other"},
    {"day": "9", "isCurrentMonth": true, "status": null},
    {"day": "10", "isCurrentMonth": true, "status": "selected"}, // Dec 10, 2024
    {"day": "11", "isCurrentMonth": true, "status": null},
    {"day": "12", "isCurrentMonth": true, "status": "at_risk"},
    {"day": "13", "isCurrentMonth": true, "status": "on_track"},
    {"day": "14", "isCurrentMonth": true, "status": null},
    {"day": "15", "isCurrentMonth": true, "status": "other"},
    {"day": "16", "isCurrentMonth": true, "status": null},
    {"day": "17", "isCurrentMonth": true, "status": "overdue"},
    {"day": "18", "isCurrentMonth": true, "status": "other"},
    {"day": "19", "isCurrentMonth": true, "status": null},
    {"day": "20", "isCurrentMonth": true, "status": "on_track"},
    {"day": "21", "isCurrentMonth": true, "status": null},
    {"day": "22", "isCurrentMonth": true, "status": null},
    {"day": "23", "isCurrentMonth": true, "status": null},
    {"day": "24", "isCurrentMonth": true, "status": "overdue"},
    {"day": "25", "isCurrentMonth": true, "status": null},
    {"day": "26", "isCurrentMonth": true, "status": "at_risk"},
    {"day": "27", "isCurrentMonth": true, "status": null},
    {"day": "28", "isCurrentMonth": true, "status": null},
    {"day": "29", "isCurrentMonth": true, "status": null},
    {"day": "30", "isCurrentMonth": true, "status": null},
    {"day": "31", "isCurrentMonth": true, "status": "overdue"},
    {"day": "1", "isCurrentMonth": false, "status": null},
    {"day": "2", "isCurrentMonth": false, "status": null},
    {"day": "3", "isCurrentMonth": false, "status": null},
    {"day": "4", "isCurrentMonth": false, "status": null},
    {"day": "5", "isCurrentMonth": false, "status": null},
  ];

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
              _buildCalendarCard(),
              const SizedBox(height: 24),
              _buildTimelineSectionHeader(),
              const SizedBox(height: 12),
              _buildTimelineList(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Layout Sub-Modules ---

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendar',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.extrabold, color: Color(0xFF0F172A)),
        ),
        SizedBox(height: 4),
        Text(
          "View your team's schedule and upcoming\ndeadlines.",
          style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.3),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Month Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.black87),
                onPressed: () {},
              ),
              const Text(
                'December 2024',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Days of Week Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar Days Grid View
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _monthDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayData = _monthDays[index];
              return _buildCalendarDayItem(dayData);
            },
          ),
          const SizedBox(height: 16),
          // Colored Legend Indicators Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem("On Track", const Color(0xFF10B981)),
              _buildLegendItem("At Risk", const Color(0xFFFFC107)),
              _buildLegendItem("Overdue", const Color(0xFFDC3545)),
              _buildLegendItem("Other", const Color(0xFF3B82F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDayItem(Map<String, dynamic> dayData) {
    String dayText = dayData["day"];
    bool isCurrentMonth = dayData["isCurrentMonth"];
    String? status = dayData["status"];

    bool isSelected = status == "selected";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              dayText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isCurrentMonth ? const Color(0xFF0F172A) : Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        // Mini colored dot layout matrix under days
        if (isSelected)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniDot(const Color(0xFF10B981)),
              const SizedBox(width: 2),
              _buildMiniDot(const Color(0xFFFFC107)),
              const SizedBox(width: 2),
              _buildMiniDot(const Color(0xFFDC3545)),
            ],
          )
        else if (status == "at_risk")
          _buildMiniDot(const Color(0xFFFFC107))
        else if (status == "on_track")
          _buildMiniDot(const Color(0xFF10B981))
        else if (status == "overdue")
          _buildMiniDot(const Color(0xFFDC3545))
        else if (status == "other")
          _buildMiniDot(const Color(0xFF3B82F6))
        else
          const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildMiniDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTimelineSectionHeader() {
    return const Row(
