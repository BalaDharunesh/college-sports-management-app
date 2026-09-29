import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class SportItem {
  final String name;
  final IconData icon;
  final String teamName;
  final String staffEmail;
  final String captainEmail;
  final String playerEmail;

  const SportItem({
    required this.name,
    required this.icon,
    required this.teamName,
    required this.staffEmail,
    required this.captainEmail,
    required this.playerEmail,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 5 Sports list with corresponding accounts
  final List<SportItem> _sports = const [
    SportItem(
      name: 'Cricket',
      icon: Icons.sports_cricket_rounded,
      teamName: 'Strikers Cricket XI',
      staffEmail: 'staff.cricket@college.edu',
      captainEmail: 'captain.cricket@college.edu',
      playerEmail: 'player.virat@college.edu',
    ),
    SportItem(
      name: 'Football',
      icon: Icons.sports_soccer_rounded,
      teamName: 'Panthers Football FC',
      staffEmail: 'staff.football@college.edu',
      captainEmail: 'captain.football@college.edu',
      playerEmail: 'player.marcus@college.edu',
    ),
    SportItem(
      name: 'Tennis',
      icon: Icons.sports_tennis_rounded,
      teamName: 'Aces Tennis Squad',
      staffEmail: 'staff.tennis@college.edu',
      captainEmail: 'captain.tennis@college.edu',
      playerEmail: 'player.jannik@college.edu',
    ),
    SportItem(
      name: 'Badminton',
      icon: Icons.sports_rounded,
      teamName: 'Smashers Badminton XI',
      staffEmail: 'staff.badminton@college.edu',
      captainEmail: 'captain.badminton@college.edu',
      playerEmail: 'player.viktor@college.edu',
    ),
    SportItem(
      name: 'Basketball',
      icon: Icons.sports_basketball_rounded,
      teamName: 'Titans Basketball Squad',
      staffEmail: 'staff.basketball@college.edu',
      captainEmail: 'captain.basketball@college.edu',
      playerEmail: 'player.curry@college.edu',
    ),
  ];

  late SportItem _selectedSport;

  @override
  void initState() {
    super.initState();
    _selectedSport = _sports[0];
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed. Please check credentials.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_score_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SportSync',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your sport and sign in to access your squad portal',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // --- SPORT SELECTOR UI ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Select Your Sport',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _sports.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final sport = _sports[index];
                            final isSelected = _selectedSport.name == sport.name;

                            return ChoiceChip(
                              avatar: Icon(
                                sport.icon,
                                size: 18,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              label: Text(
                                sport.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.background,
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSport = sport;
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(_selectedSport.icon, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_selectedSport.name} Portal • ${_selectedSport.teamName}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: 'College Email',
                          hint: 'user@college.edu',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter your email';
                            if (!val.contains('@')) return 'Please enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please enter your password';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        CustomButton(
                          text: 'Sign In to ${_selectedSport.name}',
                          onPressed: _handleLogin,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Account Presets for Selected Sport
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedSport.name} Role Quick Login',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.shield_outlined, size: 16, color: AppColors.staffBadge),
                            label: Text('${_selectedSport.name} Staff'),
                            backgroundColor: AppColors.surface,
                            onPressed: () => _fillDemo(_selectedSport.staffEmail, 'Password123!'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.stars_outlined, size: 16, color: AppColors.captainBadge),
                            label: Text('${_selectedSport.name} Captain'),
                            backgroundColor: AppColors.surface,
                            onPressed: () => _fillDemo(_selectedSport.captainEmail, 'Password123!'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.person_outline, size: 16, color: AppColors.playerBadge),
                            label: Text('${_selectedSport.name} Player'),
                            backgroundColor: AppColors.surface,
                            onPressed: () => _fillDemo(_selectedSport.playerEmail, 'Password123!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

