
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  int selectedProfile = 0;

  final List<Map<String, String>> teamMembers = [
    {
      'name': 'Alex Carter',
      'role': 'Project Manager',
      'initials': 'AC',
    },
    {
      'name': 'Priya Sharma',
      'role': 'UI/UX Designer',
      'initials': 'PS',
    },
    {
      'name': 'James Wilson',
      'role': 'Developer',
      'initials': 'JW',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28,
          ),
          children: [
            // Brand header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.midnight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: AppColors.lime,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sprintly',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 64),

            // Welcome section
            const Text(
              'Welcome back.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Your team. Your tasks. All in one place.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 48),

            const Text(
              'Choose your profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Select your profile to continue.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 22),

            // Selectable profile cards
            ...List.generate(teamMembers.length, (index) {
              final member = teamMembers[index];
              final isSelected = selectedProfile == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedProfile = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.softGreen
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.onTrack
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: AppColors.midnight,
                          child: Text(
                            member['initials']!,
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member['role']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.onTrack
                              : AppColors.border,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
