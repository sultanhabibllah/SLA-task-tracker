
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  int selectedProfile = 0;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appState = context.read<AppState>();
    final selectedMember = appState.members[selectedProfile];

    // Signing in swaps this screen for the app shell (see main.dart).
    appState.signIn(selectedMember.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.midnight,
        content: Text(
          'Welcome, ${selectedMember.name}!',
          style: const TextStyle(
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamMembers = context.watch<AppState>().members;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28,
          ),
          children: [
            // Sprintly branding
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

            const SizedBox(height: 56),

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

            const SizedBox(height: 40),

            // Profile selection heading
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

            const SizedBox(height: 20),

            // Selectable team member cards
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
                            member.initials,
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
                                member.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.jobTitle,
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

            const SizedBox(height: 28),

            // Login form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      final emailPattern =
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                      if (!emailPattern.hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _continue(),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must contain at least 6 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continue,
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Center(
              child: Text(
                'Sprintly • Project & SLA Management',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
