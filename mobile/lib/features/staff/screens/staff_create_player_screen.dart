import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/staff_provider.dart';

class StaffCreatePlayerScreen extends StatefulWidget {
  const StaffCreatePlayerScreen({super.key});

  @override
  State<StaffCreatePlayerScreen> createState() => _StaffCreatePlayerScreenState();
}

class _StaffCreatePlayerScreenState extends State<StaffCreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _regController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'PLAYER'; // Default role is Player

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final memberData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'registerNumber': _regController.text.trim(),
      'phone': _phoneController.text.trim(),
      'role': _selectedRole,
    };

    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final bool success = await staffProvider.createPlayer(memberData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team ${_selectedRole == "CAPTAIN" ? "Captain" : "Player"} account created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create account. Please check for duplicate email or register number.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Team Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Team Member',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 16),

                // College Email
                CustomTextField(
                  controller: _emailController,
                  label: 'College Email',
                  hint: 'student@college.edu',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'College Email is required';
                    if (!v.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Register Number
                CustomTextField(
                  controller: _regController,
                  label: 'Register Number',
                  hint: 'Enter register number',
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Register Number is required' : null,
                ),
                const SizedBox(height: 16),

                // Phone Number
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone Number is required';
                    }
                    final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length != 10) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Team Role Header
                Text(
                  'Team Role',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Team Role Selection Box
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'PLAYER',
                        groupValue: _selectedRole,
                        title: Text(
                          'Player',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      RadioListTile<String>(
                        value: 'CAPTAIN',
                        groupValue: _selectedRole,
                        title: Text(
                          'Captain',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
